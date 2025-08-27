output "router_id" {
  description = "The ID of the Cloud Router"
  value       = google_compute_router.hybrid_router.id
}

output "router_name" {
  description = "The name of the Cloud Router"
  value       = google_compute_router.hybrid_router.name
}

output "vpn_gateway_id" {
  description = "The ID of the HA VPN Gateway"
  value       = var.enable_vpn ? google_compute_ha_vpn_gateway.ha_gateway[0].id : null
}

output "vpn_tunnels" {
  description = "VPN tunnel information"
  value = var.enable_vpn && var.vpn_config != null ? {
    tunnel1 = {
      id     = google_compute_vpn_tunnel.tunnel1[0].id
      name   = google_compute_vpn_tunnel.tunnel1[0].name
      status = google_compute_vpn_tunnel.tunnel1[0].detailed_status
    }
    tunnel2 = {
      id     = google_compute_vpn_tunnel.tunnel2[0].id
      name   = google_compute_vpn_tunnel.tunnel2[0].name
      status = google_compute_vpn_tunnel.tunnel2[0].detailed_status
    }
  } : null
}

output "interconnect_attachment_id" {
  description = "The ID of the Interconnect Attachment"
  value       = var.enable_interconnect && var.interconnect_config != null ? google_compute_interconnect_attachment.attachment[0].id : null
}

output "bgp_sessions" {
  description = "BGP session information"
  value = {
    for peer in google_compute_router_peer.bgp_sessions : peer.name => {
      id              = peer.id
      peer_ip_address = peer.peer_ip_address
      peer_asn       = peer.peer_asn
    }
  }
}