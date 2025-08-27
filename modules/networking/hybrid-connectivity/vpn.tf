# HA VPN Gateway with multiple interfaces
resource "google_compute_ha_vpn_gateway" "ha_gateway" {
  count = var.enable_vpn ? 1 : 0
  
  name    = "${var.network_name}-ha-vpn-gateway"
  project = var.project_id
  region  = var.region
  network = data.google_compute_network.network.id
  
  description = "High Availability VPN Gateway for ${var.network_name}"
}

# External VPN Gateway configurations for different peer types
resource "google_compute_external_vpn_gateway" "external_gateway" {
  for_each = var.enable_vpn ? var.vpn_gateways : {}
  
  name            = "${var.network_name}-external-vpn-${each.key}"
  project         = var.project_id
  redundancy_type = each.value.redundancy_type
  description     = each.value.description
  
  dynamic "interface" {
    for_each = each.value.interfaces
    content {
      id         = interface.value.id
      ip_address = interface.value.ip_address
    }
  }
}

# VPN Tunnels with enhanced configuration
resource "google_compute_vpn_tunnel" "tunnels" {
  for_each = var.enable_vpn ? var.vpn_tunnels : {}
  
  name                  = "${var.network_name}-vpn-tunnel-${each.key}"
  project               = var.project_id
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway[0].id
  peer_external_gateway = google_compute_external_vpn_gateway.external_gateway[each.value.gateway_key].id
  shared_secret         = each.value.shared_secret
  router                = google_compute_router.hybrid_router.id
  
  vpn_gateway_interface         = each.value.vpn_gateway_interface
  peer_external_gateway_interface = each.value.peer_external_gateway_interface
  
  ike_version = each.value.ike_version
  
  # Enhanced IKE configuration
  local_traffic_selector  = each.value.local_traffic_selector
  remote_traffic_selector = each.value.remote_traffic_selector
  
  labels = merge(var.labels, {
    tunnel_type = "ha-vpn"
    gateway     = each.value.gateway_key
  })
}

# Router interfaces for VPN tunnels with optimized IP allocation
resource "google_compute_router_interface" "tunnel_interfaces" {
  for_each = var.enable_vpn ? var.vpn_tunnels : {}
  
  name       = "${var.network_name}-tunnel-${each.key}-interface"
  router     = google_compute_router.hybrid_router.name
  region     = var.region
  project    = var.project_id
  ip_range   = each.value.interface_ip_range
  vpn_tunnel = google_compute_vpn_tunnel.tunnels[each.key].name
  
  # Interconnect attachment for hybrid connectivity
  interconnect_attachment = lookup(each.value, "interconnect_attachment", null)
}

# BGP peers with advanced configuration
resource "google_compute_router_peer" "tunnel_peers" {
  for_each = var.enable_vpn ? var.vpn_tunnels : {}
  
  name                      = "${var.network_name}-tunnel-${each.key}-peer"
  router                    = google_compute_router.hybrid_router.name
  region                    = var.region
  project                   = var.project_id
  peer_ip_address          = each.value.peer_ip_address
  peer_asn                 = each.value.peer_asn
  advertised_route_priority = each.value.advertised_route_priority
  interface                = google_compute_router_interface.tunnel_interfaces[each.key].name
  
  # Advanced BGP configuration
  advertise_mode    = each.value.advertise_mode
  advertised_groups = each.value.advertised_groups
  
  # Custom route advertisements
  dynamic "advertised_ip_ranges" {
    for_each = lookup(each.value, "advertised_ip_ranges", [])
    content {
      range       = advertised_ip_ranges.value.range
      description = advertised_ip_ranges.value.description
    }
  }
  
  # BFD configuration for faster failover
  enable_ipv6               = lookup(each.value, "enable_ipv6", false)
  ipv6_nexthop_address     = lookup(each.value, "ipv6_nexthop_address", null)
  peer_ipv6_nexthop_address = lookup(each.value, "peer_ipv6_nexthop_address", null)
  
  # Router appliance instance for advanced routing
  router_appliance_instance = lookup(each.value, "router_appliance_instance", null)
}

# Route-based VPN configuration with policy-based routing
resource "google_compute_route" "vpn_routes" {
  for_each = var.enable_vpn ? var.vpn_static_routes : {}
  
  name        = "${var.network_name}-vpn-route-${each.key}"
  project     = var.project_id
  network     = data.google_compute_network.network.name
  dest_range  = each.value.dest_range
  priority    = each.value.priority
  description = each.value.description
  
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnels[each.value.tunnel_key].id
  
  tags = each.value.tags
}

# VPN monitoring and health checks
resource "google_compute_health_check" "vpn_health_check" {
  count = var.enable_vpn && var.enable_vpn_monitoring ? 1 : 0
  
  name        = "${var.network_name}-vpn-health-check"
  project     = var.project_id
  description = "Health check for VPN connectivity"
  
  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3
  
  tcp_health_check {
    port = 22
  }
}

# VPN monitoring dashboard
resource "google_monitoring_dashboard" "vpn_dashboard" {
  count = var.enable_vpn && var.enable_vpn_monitoring ? 1 : 0
  
  dashboard_json = jsonencode({
    displayName = "VPN Connectivity Dashboard"
    mosaicLayout = {
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "VPN Tunnel Status"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"vpn_gateway\" AND metric.type=\"compute.googleapis.com/vpn/tunnel_established\""
                    aggregation = {
                      alignmentPeriod  = "300s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          width  = 6
          height = 4
          widget = {
            title = "VPN Throughput"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"vpn_gateway\" AND metric.type=\"compute.googleapis.com/vpn/network/sent_bytes_count\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          width  = 12
          height = 4
          widget = {
            title = "BGP Session Status"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_router\" AND metric.type=\"compute.googleapis.com/router/bgp/session_up\""
                    aggregation = {
                      alignmentPeriod  = "300s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
  
  project = var.project_id
}

# VPN alert policies
resource "google_monitoring_alert_policy" "vpn_tunnel_down" {
  count = var.enable_vpn && var.enable_vpn_monitoring ? 1 : 0
  
  display_name = "VPN Tunnel Down Alert"
  project      = var.project_id
  
  conditions {
    display_name = "VPN Tunnel Disconnected"
    
    condition_threshold {
      filter          = "resource.type=\"vpn_gateway\" AND metric.type=\"compute.googleapis.com/vpn/tunnel_established\""
      comparison      = "COMPARISON_EQUAL"
      threshold_value = 0
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = var.vpn_notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_alert_policy" "bgp_session_down" {
  count = var.enable_vpn && var.enable_vpn_monitoring ? 1 : 0
  
  display_name = "BGP Session Down Alert"
  project      = var.project_id
  
  conditions {
    display_name = "BGP Session Disconnected"
    
    condition_threshold {
      filter          = "resource.type=\"gce_router\" AND metric.type=\"compute.googleapis.com/router/bgp/session_up\""
      comparison      = "COMPARISON_EQUAL"
      threshold_value = 0
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = var.vpn_notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# Automated failover procedures using Cloud Functions
resource "google_cloudfunctions_function" "vpn_failover" {
  count = var.enable_vpn && var.enable_automated_failover ? 1 : 0
  
  name        = "${var.network_name}-vpn-failover"
  project     = var.project_id
  region      = var.region
  description = "Automated VPN failover procedures"
  
  runtime = "python39"
  
  available_memory_mb   = 256
  source_archive_bucket = var.failover_function_bucket
  source_archive_object = var.failover_function_object
  entry_point          = "handle_vpn_failover"
  
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = "projects/${var.project_id}/topics/vpn-alerts"
  }
  
  environment_variables = {
    PROJECT_ID = var.project_id
    NETWORK    = var.network_name
    REGION     = var.region
  }
}

# VPN connection testing automation
resource "google_compute_instance" "vpn_test_instance" {
  count = var.enable_vpn && var.enable_connection_testing ? 1 : 0
  
  name         = "${var.network_name}-vpn-test"
  project      = var.project_id
  zone         = "${var.region}-a"
  machine_type = "e2-micro"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    network    = data.google_compute_network.network.id
    subnetwork = var.test_subnet
  }
  
  metadata_startup_script = file("${path.module}/scripts/vpn-connectivity-test.sh")
  
  service_account {
    email  = var.test_service_account
    scopes = ["cloud-platform"]
  }
  
  tags = ["vpn-test", "internal"]
  
  labels = merge(var.labels, {
    purpose = "vpn-testing"
  })
}