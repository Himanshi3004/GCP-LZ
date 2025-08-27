resource "google_storage_bucket" "primary_backup" {
  name     = "${var.project_id}-primary-backup"
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
  
  versioning {
    enabled = true
  }
  
  labels = var.labels
}

resource "google_storage_bucket" "replica_backup" {
  count = var.enable_cross_region_backup ? 1 : 0
  
  name     = "${var.project_id}-replica-backup"
  location = var.backup_regions[1]
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
  
  versioning {
    enabled = true
  }
  
  labels = var.labels
}

resource "google_storage_transfer_job" "backup_replication" {
  count = var.enable_cross_region_backup ? 1 : 0
  
  description = "Backup replication job"
  project     = var.project_id
  
  transfer_spec {
    gcs_data_source {
      bucket_name = google_storage_bucket.primary_backup.name
    }
    
    gcs_data_sink {
      bucket_name = google_storage_bucket.replica_backup[0].name
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
      hours   = 3
      minutes = 0
      seconds = 0
      nanos   = 0
    }
  }
  
  status = "ENABLED"
}