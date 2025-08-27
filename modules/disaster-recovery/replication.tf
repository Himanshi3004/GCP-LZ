# DNS managed zone for failover
resource "google_dns_managed_zone" "main" {
  name     = var.dns_zone_name
  dns_name = "${var.domain_name}."
  project  = var.project_id
  
  description = "DNS zone for disaster recovery failover"
  
  dnssec_config {
    state = "on"
  }
  
  labels = merge(var.labels, {
    purpose = "disaster-recovery"
  })
}

# Primary DNS record
resource "google_dns_record_set" "main" {
  name    = "${var.domain_name}."
  type    = "A"
  ttl     = 300
  project = var.project_id
  
  managed_zone = google_dns_managed_zone.main.name
  
  rrdatas = [google_compute_global_address.lb_ip.address]
}

# CNAME record for www
resource "google_dns_record_set" "www" {
  name    = "www.${var.domain_name}."
  type    = "CNAME"
  ttl     = 300
  project = var.project_id
  
  managed_zone = google_dns_managed_zone.main.name
  
  rrdatas = ["${var.domain_name}."]
}

# DR data storage buckets
resource "google_storage_bucket" "dr_data" {
  for_each = var.primary_data_buckets
  
  name     = "${var.project_id}-dr-data-${each.key}"
  location = var.dr_region
  project  = var.project_id
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
  
  labels = merge(var.labels, {
    purpose = "disaster-recovery"
    region  = var.dr_region
    source  = each.key
  })
}

# Data replication jobs
resource "google_storage_transfer_job" "dr_replication" {
  for_each = var.primary_data_buckets
  
  description = "DR data replication for ${each.key}"
  project     = var.project_id
  
  transfer_spec {
    gcs_data_source {
      bucket_name = each.value.bucket_name
      path        = each.value.sync_path
    }
    
    gcs_data_sink {
      bucket_name = google_storage_bucket.dr_data[each.key].name
    }
    
    transfer_options {
      delete_objects_unique_in_sink = false
      overwrite_objects_already_existing_in_sink = true
    }
  }
  
  schedule {
    schedule_start_date {
      year  = 2024
      month = 1
      day   = 1
    }
    
    start_time_of_day {
      hours   = 1
      minutes = 0
      seconds = 0
      nanos   = 0
    }
    
    repeat_interval = "3600s"  # Hourly replication
  }
  
  status = "ENABLED"
}

# SQL read replicas for disaster recovery
resource "google_sql_database_instance" "dr_replica" {
  for_each = var.enable_sql_replica ? var.sql_instances : {}
  
  name                 = "${each.value.instance_name}-replica"
  database_version     = each.value.database_version
  region              = var.dr_region
  project             = var.project_id
  master_instance_name = each.value.instance_name
  
  replica_configuration {
    failover_target = true
  }
  
  settings {
    tier = each.value.tier
    
    availability_type = "REGIONAL"
    
    backup_configuration {
      enabled                        = true
      start_time                    = "03:00"
      point_in_time_recovery_enabled = true
      
      backup_retention_settings {
        retained_backups = 30
        retention_unit   = "COUNT"
      }
      
      transaction_log_retention_days = 7
    }
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = "projects/${var.project_id}/global/networks/shared-vpc"
      require_ssl     = true
    }
    
    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }
    
    database_flags {
      name  = "log_connections"
      value = "on"
    }
    
    insights_config {
      query_insights_enabled  = true
      record_application_tags = true
      record_client_address   = true
    }
  }
  
  deletion_protection = true
}

# Cross-region GKE backup replication
resource "google_storage_transfer_job" "gke_backup_replication" {
  for_each = var.gke_clusters
  
  description = "GKE backup replication for ${each.key}"
  project     = var.project_id
  
  transfer_spec {
    gcs_data_source {
      bucket_name = "${var.project_id}-gke-backups-${var.primary_region}"
      path        = "${each.key}/"
    }
    
    gcs_data_sink {
      bucket_name = "${var.project_id}-gke-backups-${var.dr_region}"
    }
    
    transfer_options {
      delete_objects_unique_in_sink = false
      overwrite_objects_already_existing_in_sink = true
    }
  }
  
  schedule {
    schedule_start_date {
      year  = 2024
      month = 1
      day   = 1
    }
    
    start_time_of_day {
      hours   = 2
      minutes = 0
      seconds = 0
      nanos   = 0
    }
    
    repeat_interval = "21600s"  # Every 6 hours
  }
  
  status = "ENABLED"
}

# DR region GKE clusters (standby)
resource "google_container_cluster" "dr_cluster" {
  for_each = var.gke_clusters
  
  name     = "${each.key}-dr"
  location = var.dr_region
  project  = var.project_id
  
  # Minimal configuration for standby cluster
  initial_node_count       = 1
  remove_default_node_pool = true
  
  network    = "projects/${var.project_id}/global/networks/shared-vpc"
  subnetwork = "projects/${var.project_id}/regions/${var.dr_region}/subnetworks/private-subnet-${var.dr_region}"
  
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block = "172.16.0.0/28"
  }
  
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }
  
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    
    http_load_balancing {
      disabled = false
    }
    
    network_policy_config {
      disabled = false
    }
  }
  
  network_policy {
    enabled = true
  }
  
  # Security configuration
  enable_shielded_nodes = true
  
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  
  # Minimal node pool for standby
  node_pool {
    name       = "dr-pool"
    node_count = 1
    
    node_config {
      machine_type = "e2-medium"
      disk_size_gb = 50
      disk_type    = "pd-ssd"
      
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
      
      shielded_instance_config {
        enable_secure_boot          = true
        enable_integrity_monitoring = true
      }
      
      workload_metadata_config {
        mode = "GKE_METADATA"
      }
    }
    
    autoscaling {
      min_node_count = 0
      max_node_count = 10
    }
    
    management {
      auto_repair  = true
      auto_upgrade = true
    }
  }
}

# Replication monitoring
resource "google_monitoring_alert_policy" "replication_failure" {
  display_name = "Data Replication Failure"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Storage transfer job failed"
    
    condition_threshold {
      filter          = "resource.type=\"storage_transfer_job\" AND metric.type=\"storagetransfer.googleapis.com/transfer/success\""
      comparison      = "COMPARISON_EQUAL"
      threshold_value = 0
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# SQL replica lag monitoring
resource "google_monitoring_alert_policy" "sql_replica_lag" {
  count = var.enable_sql_replica ? 1 : 0
  
  display_name = "SQL Replica Lag Alert"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "SQL replica lag too high"
    
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/replication/replica_lag\""
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = var.rpo_minutes * 60  # Convert minutes to seconds
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}