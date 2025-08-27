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
  project = var.host_project_id
  service = "compute.googleapis.com"
  
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "container_api" {
  project = var.host_project_id
  service = "container.googleapis.com"
  
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "servicenetworking_api" {
  project = var.host_project_id
  service = "servicenetworking.googleapis.com"
  
  disable_dependent_services = false
  disable_on_destroy         = false
}

# Enable Shared VPC on host project
resource "google_compute_shared_vpc_host_project" "host" {
  project = var.host_project_id
  
  depends_on = [google_project_service.compute_api]
}

# Attach service projects to shared VPC
resource "google_compute_shared_vpc_service_project" "service_projects" {
  for_each = toset(var.service_project_ids)
  
  host_project    = var.host_project_id
  service_project = each.value
  
  depends_on = [google_compute_shared_vpc_host_project.host]
}