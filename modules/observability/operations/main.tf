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
    "cloudtrace.googleapis.com",
    "cloudprofiler.googleapis.com",
    "clouddebugger.googleapis.com",
    "clouderrorreporting.googleapis.com",
    "monitoring.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  disable_on_destroy = false
}

resource "google_service_account" "operations" {
  project      = var.project_id
  account_id   = "operations-sa"
  display_name = "Operations Service Account"
}

resource "google_project_iam_member" "operations_roles" {
  for_each = toset([
    "roles/cloudtrace.agent",
    "roles/cloudprofiler.agent",
    "roles/clouddebugger.agent",
    "roles/errorreporting.writer"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.operations.email}"
}