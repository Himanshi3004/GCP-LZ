# Data Protection Module - Main Configuration
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
    "cloudkms.googleapis.com",
    "dlp.googleapis.com",
    "secretmanager.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  disable_on_destroy = false
}

# Service account for data protection
resource "google_service_account" "data_protection" {
  project      = var.project_id
  account_id   = "data-protection-sa"
  display_name = "Data Protection Service Account"
}

# IAM bindings
resource "google_project_iam_member" "data_protection_roles" {
  for_each = toset([
    "roles/cloudkms.cryptoKeyEncrypterDecrypter",
    "roles/dlp.admin"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.data_protection.email}"
}