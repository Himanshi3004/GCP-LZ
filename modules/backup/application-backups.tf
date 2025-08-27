# Application backup storage buckets
resource "google_storage_bucket" "application_backup" {
  for_each = var.application_backup_paths
  
  name     = "${var.project_id}-app-backup-${each.key}"
  location = var.region
  project  = var.project_id
  
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = var.backup_retention_days
    }
    action {
      type = "Delete"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
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
    purpose     = "application-backup"
    application = each.key
  })
}

# Application backup transfer jobs
resource "google_storage_transfer_job" "application_backup" {
  for_each = var.application_backup_paths
  
  description = "Application backup for ${each.key}"
  project     = var.project_id
  
  transfer_spec {
    gcs_data_source {
      bucket_name = each.value.source_bucket
      path        = each.value.backup_path
    }
    
    gcs_data_sink {
      bucket_name = google_storage_bucket.application_backup[each.key].name
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
      hours   = tonumber(split(" ", each.value.schedule)[1])
      minutes = 0
      seconds = 0
      nanos   = 0
    }
  }
  
  status = "ENABLED"
}

# Cloud Function for application backup validation
resource "google_storage_bucket" "backup_validation_source" {
  name     = "${var.project_id}-backup-validation-source"
  location = var.region
  project  = var.project_id
  
  uniform_bucket_level_access = true
  
  labels = merge(var.labels, {
    purpose = "backup-validation"
  })
}

resource "google_cloudfunctions_function" "backup_validator" {
  count = var.enable_backup_testing ? 1 : 0
  
  name        = "backup-validator"
  project     = var.project_id
  region      = var.region
  description = "Validates backup integrity and completeness"
  
  source_archive_bucket = google_storage_bucket.backup_validation_source.name
  source_archive_object = "backup-validator.zip"
  
  entry_point = "validate_backup"
  runtime     = "python39"
  
  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = "${var.project_id}-backups-${var.region}"
  }
  
  environment_variables = {
    PROJECT_ID = var.project_id
    REGION     = var.region
  }
  
  service_account_email = google_service_account.backup_sa.email
  
  labels = var.labels
}

# Backup validation results topic
resource "google_pubsub_topic" "backup_validation_results" {
  name    = "backup-validation-results"
  project = var.project_id
  
  labels = var.labels
}

# Application backup monitoring
resource "google_monitoring_alert_policy" "application_backup_failure" {
  count = var.enable_backup_monitoring ? 1 : 0
  
  display_name = "Application Backup Failure"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Application backup transfer failed"
    
    condition_threshold {
      filter          = "resource.type=\"storage_transfer_job\" AND metric.type=\"storagetransfer.googleapis.com/transfer/success\""
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