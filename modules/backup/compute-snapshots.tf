# Primary snapshot policy for daily backups
resource "google_compute_resource_policy" "snapshot_policy" {
  name    = "disk-snapshot-policy"
  region  = var.region
  project = var.project_id
  
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "02:00"
      }
    }
    
    retention_policy {
      max_retention_days    = var.backup_retention_days
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
    
    snapshot_properties {
      labels = merge(var.labels, {
        backup_type = "automated"
        created_by  = "terraform"
        policy_type = "daily"
      })
      storage_locations = var.enable_cross_region_backup ? var.backup_regions : [var.region]
      guest_flush       = true
    }
  }
}

# Weekly snapshot policy for long-term retention
resource "google_compute_resource_policy" "weekly_snapshot_policy" {
  name    = "disk-weekly-snapshot-policy"
  region  = var.region
  project = var.project_id
  
  snapshot_schedule_policy {
    schedule {
      weekly_schedule {
        day_of_weeks {
          day        = "SUNDAY"
          start_time = "01:00"
        }
      }
    }
    
    retention_policy {
      max_retention_days    = var.long_term_retention_days
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
    
    snapshot_properties {
      labels = merge(var.labels, {
        backup_type = "automated"
        created_by  = "terraform"
        policy_type = "weekly"
      })
      storage_locations = var.enable_cross_region_backup ? var.backup_regions : [var.region]
      guest_flush       = true
    }
  }
}

# Attach daily snapshot policy to disks
resource "google_compute_disk_resource_policy_attachment" "daily_attachment" {
  for_each = toset(var.disk_names)
  
  name    = google_compute_resource_policy.snapshot_policy.name
  disk    = each.value
  zone    = "${var.region}-a"
  project = var.project_id
}

# Attach weekly snapshot policy to disks
resource "google_compute_disk_resource_policy_attachment" "weekly_attachment" {
  for_each = toset(var.disk_names)
  
  name    = google_compute_resource_policy.weekly_snapshot_policy.name
  disk    = each.value
  zone    = "${var.region}-a"
  project = var.project_id
}

# Backup storage buckets with lifecycle management
resource "google_storage_bucket" "backup_buckets" {
  for_each = toset(var.backup_regions)
  
  name     = "${var.project_id}-backups-${each.value}"
  location = each.value
  project  = var.project_id
  
  uniform_bucket_level_access = true
  
  # Standard retention lifecycle
  lifecycle_rule {
    condition {
      age = var.backup_retention_days
    }
    action {
      type = "Delete"
    }
  }
  
  # Move to nearline after 30 days
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
  
  # Move to coldline after 90 days
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
  
  versioning {
    enabled = true
  }
  
  dynamic "encryption" {
    for_each = var.kms_key_id != null ? [1] : []
    content {
      default_kms_key_name = var.kms_key_id
    }
  }
  
  labels = merge(var.labels, {
    purpose = "backup"
    region  = each.value
  })
}

# Snapshot monitoring
resource "google_monitoring_alert_policy" "snapshot_failure" {
  count = var.enable_backup_monitoring ? 1 : 0
  
  display_name = "Snapshot Backup Failure"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Snapshot creation failed"
    
    condition_threshold {
      filter          = "resource.type=\"gce_disk\" AND metric.type=\"compute.googleapis.com/snapshot/creation_failed\""
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = var.backup_notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}