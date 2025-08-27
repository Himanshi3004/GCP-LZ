# Cloud Interconnect Attachment
resource "google_compute_interconnect_attachment" "attachment" {
  count = var.enable_interconnect && var.interconnect_config != null ? 1 : 0
  
  name                     = "${var.network_name}-interconnect-attachment"
  project                  = var.project_id
  region                   = var.region
  router                   = google_compute_router.hybrid_router.id
  type                     = var.interconnect_config.type
  edge_availability_domain = "AVAILABILITY_DOMAIN_1"
  
  # Interconnect configuration
  interconnect = var.interconnect_config.type == "DEDICATED" ? var.interconnect_config.interconnect_name : null
  
  bandwidth = "BPS_1G"
  
  candidate_subnets = ["169.254.100.0/29"]
  vlan_tag8021q     = 100
}

# Router interface for Interconnect
resource "google_compute_router_interface" "interconnect_interface" {
  count = var.enable_interconnect && var.interconnect_config != null ? 1 : 0
  
  name                    = "${var.network_name}-interconnect-interface"
  router                  = google_compute_router.hybrid_router.name
  region                  = var.region
  project                 = var.project_id
  ip_range               = "169.254.100.1/29"
  interconnect_attachment = google_compute_interconnect_attachment.attachment[0].name
}

# BGP peer for Interconnect
resource "google_compute_router_peer" "interconnect_peer" {
  count = var.enable_interconnect && var.interconnect_config != null ? 1 : 0
  
  name                      = "${var.network_name}-interconnect-peer"
  router                    = google_compute_router.hybrid_router.name
  region                    = var.region
  project                   = var.project_id
  peer_ip_address          = "169.254.100.2"
  peer_asn                 = 65000
  advertised_route_priority = 100
  interface                = google_compute_router_interface.interconnect_interface[0].name
}