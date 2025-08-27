# Cloud Router for NAT
resource "google_compute_router" "router" {
  for_each = var.enable_cloud_nat ? toset(var.nat_regions) : []
  
  name    = "${var.network_name}-router-${each.value}"
  project = var.host_project_id
  region  = each.value
  network = google_compute_network.vpc.id
  
  depends_on = [google_compute_network.vpc]
}

# Cloud NAT
resource "google_compute_router_nat" "nat" {
  for_each = var.enable_cloud_nat ? toset(var.nat_regions) : []
  
  name                               = "${var.network_name}-nat-${each.value}"
  project                           = var.host_project_id
  router                            = google_compute_router.router[each.value].name
  region                            = each.value
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
  
  depends_on = [google_compute_router.router]
}