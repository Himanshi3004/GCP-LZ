# Compliance Framework Module - Main Configuration
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
    "accesscontextmanager.googleapis.com",
    "binaryauthorization.googleapis.com",
    "assuredworkloads.googleapis.com",
    "servicenetworking.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  disable_on_destroy = false
}

# Service account for compliance operations
resource "google_service_account" "compliance" {
  project      = var.project_id
  account_id   = "compliance-sa"
  display_name = "Compliance Service Account"
}

# IAM bindings for compliance service account
resource "google_project_iam_member" "compliance_roles" {
  for_each = toset([
    "roles/accesscontextmanager.policyAdmin",
    "roles/binaryauthorization.attestorsAdmin",
    "roles/assuredworkloads.admin"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.compliance.email}"
}