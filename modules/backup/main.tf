terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "sqladmin.googleapis.com",
    "container.googleapis.com",
    "file.googleapis.com",
    "gkebackup.googleapis.com",
    "storage.googleapis.com",
    "storagetransfer.googleapis.com",
    "cloudscheduler.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "pubsub.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  disable_on_destroy = false
}

resource "google_service_account" "backup_sa" {
  project      = var.project_id
  account_id   = "backup-service-account"
  display_name = "Backup Service Account"
  description  = "Service account for automated backup operations"
}

resource "google_project_iam_member" "backup_roles" {
  for_each = toset([
    "roles/compute.storageAdmin",
    "roles/cloudsql.admin",
    "roles/container.admin",
    "roles/file.editor",
    "roles/gkebackup.admin",
    "roles/storage.admin",
    "roles/storagetransfer.admin",
    "roles/cloudscheduler.admin",
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter",
    "roles/pubsub.publisher"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.backup_sa.email}"
}

# Backup monitoring service account
resource "google_service_account" "backup_monitor_sa" {
  project      = var.project_id
  account_id   = "backup-monitor-sa"
  display_name = "Backup Monitoring Service Account"
  description  = "Service account for backup monitoring and alerting"
}

resource "google_project_iam_member" "backup_monitor_roles" {
  for_each = toset([
    "roles/monitoring.editor",
    "roles/logging.viewer",
    "roles/pubsub.subscriber"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.backup_monitor_sa.email}"
}