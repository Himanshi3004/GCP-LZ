# Logging and Monitoring Module - Main Configuration
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "bigquery.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  disable_on_destroy = false
}

# Service account for logging and monitoring
resource "google_service_account" "logging_monitoring" {
  project      = var.project_id
  account_id   = "logging-monitoring-sa"
  display_name = "Logging and Monitoring Service Account"
}

# IAM bindings
resource "google_project_iam_member" "logging_monitoring_roles" {
  for_each = toset([
    "roles/logging.admin",
    "roles/monitoring.editor",
    "roles/bigquery.dataEditor"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.logging_monitoring.email}"
}