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
    "sourcerepo.googleapis.com",
    "cloudbuild.googleapis.com",
    "containeranalysis.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  disable_on_destroy = false
}

resource "google_service_account" "source_management" {
  project      = var.project_id
  account_id   = "source-management-sa"
  display_name = "Source Management Service Account"
}

resource "google_project_iam_member" "source_management_roles" {
  for_each = toset([
    "roles/source.admin",
    "roles/cloudbuild.builds.editor"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.source_management.email}"
}