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
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
    "container.googleapis.com",
    "run.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  disable_on_destroy = false
}

resource "google_service_account" "cicd_pipeline" {
  project      = var.project_id
  account_id   = "cicd-pipeline-sa"
  display_name = "CI/CD Pipeline Service Account"
}

resource "google_project_iam_member" "cicd_pipeline_roles" {
  for_each = toset([
    "roles/cloudbuild.builds.builder",
    "roles/clouddeploy.operator",
    "roles/container.developer",
    "roles/run.developer"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cicd_pipeline.email}"
}