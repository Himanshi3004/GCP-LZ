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
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "dataflow.googleapis.com",
    "pubsub.googleapis.com",
    "composer.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  disable_on_destroy = false
}

resource "google_service_account" "data_lake" {
  project      = var.project_id
  account_id   = "data-lake-sa"
  display_name = "Data Lake Service Account"
}

resource "google_project_iam_member" "data_lake_roles" {
  for_each = toset([
    "roles/storage.admin",
    "roles/bigquery.dataEditor",
    "roles/dataflow.worker",
    "roles/pubsub.editor"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.data_lake.email}"
}