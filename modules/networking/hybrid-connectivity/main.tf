terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.84.0"
    }
  }
}

# Enable required APIs
resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"
  
  disable_dependent_services = false
  disable_on_destroy         = false
}

# Data source for existing network
data "google_compute_network" "network" {
  name    = var.network_name
  project = var.project_id
}