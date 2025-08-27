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
    "dns.googleapis.com",
    "compute.googleapis.com",
    "monitoring.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudscheduler.googleapis.com",
    "storage.googleapis.com",
    "storagetransfer.googleapis.com",
    "sqladmin.googleapis.com",
    "container.googleapis.com",
    "gkebackup.googleapis.com",
    "pubsub.googleapis.com",
    "logging.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  disable_on_destroy = false
}

resource "google_service_account" "dr_sa" {
  project      = var.project_id
  account_id   = "disaster-recovery-sa"
  display_name = "Disaster Recovery Service Account"
  description  = "Service account for disaster recovery operations"
}

resource "google_project_iam_member" "dr_roles" {
  for_each = toset([
    "roles/dns.admin",
    "roles/compute.admin",
    "roles/monitoring.editor",
    "roles/cloudbuild.builds.builder",
    "roles/cloudscheduler.admin",
    "roles/storage.admin",
    "roles/storagetransfer.admin",
    "roles/cloudsql.admin",
    "roles/container.admin",
    "roles/gkebackup.admin",
    "roles/pubsub.publisher",
    "roles/logging.logWriter"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.dr_sa.email}"
}

# DR monitoring service account
resource "google_service_account" "dr_monitor_sa" {
  project      = var.project_id
  account_id   = "dr-monitor-sa"
  display_name = "DR Monitoring Service Account"
  description  = "Service account for DR monitoring and alerting"
}

resource "google_project_iam_member" "dr_monitor_roles" {
  for_each = toset([
    "roles/monitoring.editor",
    "roles/logging.viewer",
    "roles/pubsub.subscriber",
    "roles/compute.viewer",
    "roles/dns.reader"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.dr_monitor_sa.email}"
}