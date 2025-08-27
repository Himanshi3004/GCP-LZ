resource "google_gke_backup_backup_plan" "daily_plan" {
  count    = var.enable_backup ? 1 : 0
  name     = "${var.cluster_name}-daily-backup"
  project  = var.project_id
  location = var.region
  cluster  = google_container_cluster.primary.id
  
  backup_config {
    include_volume_data = var.backup_include_volume_data
    include_secrets     = var.backup_include_secrets
    
    selected_namespaces {
      namespaces = var.backup_namespaces
    }
    
    encryption_key {
      gcp_kms_encryption_key = var.backup_encryption_key
    }
  }
  
  backup_schedule {
    cron_schedule = var.backup_daily_schedule
    paused        = false
  }
  
  retention_policy {
    backup_delete_lock_days = var.backup_delete_lock_days
    backup_retain_days      = var.backup_retain_days
  }
  
  labels = var.labels
}

resource "google_gke_backup_backup_plan" "weekly_plan" {
  count    = var.enable_backup && var.enable_weekly_backup ? 1 : 0
  name     = "${var.cluster_name}-weekly-backup"
  project  = var.project_id
  location = var.region
  cluster  = google_container_cluster.primary.id
  
  backup_config {
    include_volume_data = true
    include_secrets     = true
    all_namespaces      = true
    
    encryption_key {
      gcp_kms_encryption_key = var.backup_encryption_key
    }
  }
  
  backup_schedule {
    cron_schedule = var.backup_weekly_schedule
    paused        = false
  }
  
  retention_policy {
    backup_delete_lock_days = 14
    backup_retain_days      = 90
  }
  
  labels = var.labels
}

resource "google_monitoring_alert_policy" "backup_failure" {
  display_name = "GKE Backup Failure"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Backup job failed"
    
    condition_threshold {
      filter          = "resource.type=\"gke_cluster\""
      comparison      = "COMPARISON_EQ"
      threshold_value = 0
      duration        = "300s"
    }
  }
  
  notification_channels = []
  
  alert_strategy {
    auto_close = "86400s"
  }
}