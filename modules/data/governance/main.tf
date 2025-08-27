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
    "datacatalog.googleapis.com",
    "dlp.googleapis.com",
    "logging.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  disable_on_destroy = false
}

resource "google_service_account" "governance" {
  project      = var.project_id
  account_id   = "governance-sa"
  display_name = "Data Governance Service Account"
}

resource "google_project_iam_member" "governance_roles" {
  for_each = toset([
    "roles/datacatalog.admin",
    "roles/dlp.admin",
    "roles/logging.admin"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.governance.email}"
}