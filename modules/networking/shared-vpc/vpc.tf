# Create the VPC network
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  project                 = var.host_project_id
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
  
  depends_on = [google_project_service.compute_api]
}