# Cloud Router for BGP sessions
resource "google_compute_router" "hybrid_router" {
  name    = "${var.network_name}-hybrid-router"
  project = var.project_id
  region  = var.region
  network = data.google_compute_network.network.id
  
  bgp {
    asn               = var.vpn_config != null ? var.vpn_config.cloud_asn : 64512
    advertise_mode    = "CUSTOM"
    
    dynamic "advertised_ip_ranges" {
      for_each = var.custom_routes
      content {
        range       = advertised_ip_ranges.value.dest_range
        description = advertised_ip_ranges.value.description
      }
    }
  }
  
  depends_on = [google_project_service.compute_api]
}

# BGP sessions
resource "google_compute_router_peer" "bgp_sessions" {
  for_each = { for session in var.bgp_sessions : session.name => session }
  
  name                      = each.value.name
  router                    = google_compute_router.hybrid_router.name
  region                    = var.region
  project                   = var.project_id
  peer_ip_address          = each.value.peer_ip_address
  peer_asn                 = each.value.peer_asn
  advertised_route_priority = each.value.advertised_route_priority
  interface                = each.value.interface_name
}