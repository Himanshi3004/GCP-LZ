# GKE backup plans with enhanced configuration
resource "google_gke_backup_backup_plan" "plans" {
  for_each = var.gke_clusters
  
  name     = "${each.key}-backup-plan"
  cluster  = each.value.cluster_id
  location = each.value.location
  project  = var.project_id
  
  backup_config {
    include_volume_data    = true
    include_secrets       = true
    all_namespaces       = true
    
    selected_applications {
      namespaced_names {
        name      = "kube-system"
        namespace = "kube-system"
      }
      namespaced_names {
        name      = "default"
        namespace = "default"
      }
    }
    
    dynamic "encryption_key" {
      for_each = var.kms_key_id != null ? [1] : []
      content {
        gcp_kms_encryption_key = var.kms_key_id
      }
    }
  }
  
  backup_schedule {
    cron_schedule = var.snapshot_schedule
    paused       = false
  }
  
  retention_policy {
    backup_delete_lock_days = 7
    backup_retain_days     = var.backup_retention_days
    locked                 = false
  }
  
  labels = merge(var.labels, {
    cluster = each.key
    backup_type = "automated"
  })
}

# GKE restore plans
resource "google_gke_backup_restore_plan" "plans" {
  for_each = var.gke_clusters
  
  name     = "${each.key}-restore-plan"
  location = each.value.location
  project  = var.project_id
  
  backup_plan = google_gke_backup_backup_plan.plans[each.key].id
  
  cluster = each.value.cluster_id
  
  restore_config {
    all_namespaces                 = true
    namespaced_resource_restore_mode = "DELETE_AND_RESTORE"
    volume_data_restore_policy      = "RESTORE_VOLUME_DATA_FROM_BACKUP"
    
    cluster_resource_restore_scope {
      all_group_kinds = true
    }
    
    cluster_resource_conflict_policy = "USE_EXISTING_VERSION"
    namespaced_resource_conflict_policy = "USE_EXISTING_VERSION"
  }
  
  labels = merge(var.labels, {
    cluster = each.key
    restore_type = "automated"
  })
}

# Weekly GKE backup plans for long-term retention
resource "google_gke_backup_backup_plan" "weekly_plans" {
  for_each = var.gke_clusters
  
  name     = "${each.key}-weekly-backup-plan"
  cluster  = each.value.cluster_id
  location = each.value.location
  project  = var.project_id
  
  backup_config {
    include_volume_data    = true
    include_secrets       = true
    all_namespaces       = true
    
    dynamic "encryption_key" {
      for_each = var.kms_key_id != null ? [1] : []
      content {
        gcp_kms_encryption_key = var.kms_key_id
      }
    }
  }
  
  backup_schedule {
    cron_schedule = "0 1 * * 0"  # Weekly on Sunday at 1 AM
    paused       = false
  }
  
  retention_policy {
    backup_delete_lock_days = 30
    backup_retain_days     = var.long_term_retention_days
    locked                 = false
  }
  
  labels = merge(var.labels, {
    cluster = each.key
    backup_type = "weekly"
  })
}

# GKE backup monitoring
resource "google_monitoring_alert_policy" "gke_backup_failure" {
  count = var.enable_backup_monitoring ? 1 : 0
  
  display_name = "GKE Backup Failure"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "GKE backup failed"
    
    condition_threshold {
      filter          = "resource.type=\"gke_backup\" AND metric.type=\"gkebackup.googleapis.com/backup/success\""
      comparison      = "COMPARISON_EQUAL"
      threshold_value = 0
      duration        = "3600s"
      
      aggregations {
        alignment_period   = "3600s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }
  
  notification_channels = var.backup_notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# Scheduled GKE backup testing
resource "google_cloud_scheduler_job" "gke_backup_test" {
  count = var.enable_backup_testing ? length(var.gke_clusters) : 0
  
  name        = "${keys(var.gke_clusters)[count.index]}-backup-test"
  project     = var.project_id
  region      = var.region
  description = "Automated GKE backup testing"
  schedule    = var.backup_test_schedule
  
  http_target {
    http_method = "POST"
    uri         = "https://cloudbuild.googleapis.com/v1/projects/${var.project_id}/triggers/gke-backup-test:run"
    
    headers = {
      "Content-Type" = "application/json"
    }
    
    body = base64encode(jsonencode({
      branchName = "main"
      substitutions = {
        _CLUSTER_NAME = keys(var.gke_clusters)[count.index]
        _BACKUP_PLAN  = google_gke_backup_backup_plan.plans[keys(var.gke_clusters)[count.index]].name
      }
    }))
    
    oauth_token {
      service_account_email = google_service_account.backup_sa.email
    }
  }
}

# PubSub topic for backup notifications
resource "google_pubsub_topic" "gke_backup_notifications" {
  name    = "gke-backup-notifications"
  project = var.project_id
  
  labels = var.labels
}

resource "google_pubsub_subscription" "gke_backup_notifications" {
  name    = "gke-backup-notifications-sub"
  topic   = google_pubsub_topic.gke_backup_notifications.name
  project = var.project_id
  
  message_retention_duration = "604800s"  # 7 days
  retain_acked_messages      = false
  
  expiration_policy {
    ttl = "2678400s"  # 31 days
  }
}