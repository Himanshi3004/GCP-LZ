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
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  disable_on_destroy = false
}

resource "google_service_account" "warehouse" {
  project      = var.project_id
  account_id   = "warehouse-sa"
  display_name = "Data Warehouse Service Account"
}

resource "google_project_iam_member" "warehouse_roles" {
  for_each = toset([
    "roles/bigquery.admin",
    "roles/bigquery.jobUser"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.warehouse.email}"
}