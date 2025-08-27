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
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "orgpolicy.googleapis.com",
    "securitycenter.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  disable_on_destroy = false
}

# Service account for policy enforcement
resource "google_service_account" "policy_enforcer" {
  project      = var.project_id
  account_id   = "policy-enforcer-sa"
  display_name = "Policy Enforcement Service Account"
}

# IAM roles for policy enforcement
resource "google_project_iam_member" "policy_enforcer_roles" {
  for_each = toset([
    "roles/orgpolicy.policyAdmin",
    "roles/securitycenter.admin",
    "roles/cloudbuild.builds.builder"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.policy_enforcer.email}"
}

# Cloud Build trigger for policy validation
resource "google_cloudbuild_trigger" "policy_validation" {
  project     = var.project_id
  name        = "policy-validation-trigger"
  description = "Validates Terraform plans against policies"
  
  source_to_build {
    uri       = var.source_repo_url
    ref       = "refs/heads/main"
    repo_type = "CLOUD_SOURCE_REPOSITORIES"
  }
  
  build {
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = ["config", "set", "project", var.project_id]
    }
    
    step {
      name = "hashicorp/terraform:1.5"
      args = ["init"]
    }
    
    step {
      name = "hashicorp/terraform:1.5"
      args = ["plan", "-out=tfplan"]
    }
    
    step {
      name = "gcr.io/${var.project_id}/conftest"
      args = ["verify", "--policy", "policies/", "tfplan"]
    }
    
    step {
      name = "gcr.io/${var.project_id}/tfsec"
      args = [".", "--format", "json", "--out", "tfsec-results.json"]
    }
  }
  
  service_account = google_service_account.policy_enforcer.id
}

# Storage bucket for policy artifacts
resource "google_storage_bucket" "policy_artifacts" {
  name     = "${var.project_id}-policy-artifacts"
  location = var.region
  project  = var.project_id
  
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
  
  labels = var.labels
}