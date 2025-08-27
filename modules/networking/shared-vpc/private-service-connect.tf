# Private Service Connect for Google APIs
resource "google_compute_global_address" "google_apis_psc" {
  count = var.enable_private_service_connect ? 1 : 0
  
  name          = "${var.network_name}-google-apis-psc"
  project       = var.host_project_id
  purpose       = "PRIVATE_SERVICE_CONNECT"
  network       = google_compute_network.vpc.id
  address_type  = "INTERNAL"
  
  depends_on = [google_compute_network.vpc]
}

# PSC endpoint for Google APIs
resource "google_compute_global_forwarding_rule" "google_apis_psc" {
  count = var.enable_private_service_connect ? 1 : 0
  
  name                  = "${var.network_name}-google-apis-psc"
  project               = var.host_project_id
  target                = "all-apis"
  network               = google_compute_network.vpc.id
  ip_address            = google_compute_global_address.google_apis_psc[0].id
  load_balancing_scheme = ""
  
  depends_on = [google_compute_global_address.google_apis_psc]
}

# PSC endpoints for specific Google services
resource "google_compute_global_address" "service_psc" {
  for_each = var.enable_private_service_connect ? var.psc_google_services : {}
  
  name          = "${var.network_name}-${each.key}-psc"
  project       = var.host_project_id
  purpose       = "PRIVATE_SERVICE_CONNECT"
  network       = google_compute_network.vpc.id
  address_type  = "INTERNAL"
  
  depends_on = [google_compute_network.vpc]
}

resource "google_compute_global_forwarding_rule" "service_psc" {
  for_each = var.enable_private_service_connect ? var.psc_google_services : {}
  
  name                  = "${var.network_name}-${each.key}-psc"
  project               = var.host_project_id
  target                = each.value.target
  network               = google_compute_network.vpc.id
  ip_address            = google_compute_global_address.service_psc[each.key].id
  load_balancing_scheme = ""
  
  depends_on = [google_compute_global_address.service_psc]
}

# PSC for internal services (published services)
resource "google_compute_service_attachment" "internal_services" {
  for_each = var.psc_published_services
  
  name        = each.value.name
  project     = var.host_project_id
  region      = each.value.region
  description = each.value.description
  
  target_service          = each.value.target_service
  connection_preference   = each.value.connection_preference
  nat_subnets            = each.value.nat_subnets
  enable_proxy_protocol  = each.value.enable_proxy_protocol
  
  dynamic "consumer_reject_lists" {
    for_each = each.value.consumer_reject_lists
    content {
      project_id_or_num = consumer_reject_lists.value
    }
  }
  
  dynamic "consumer_accept_lists" {
    for_each = each.value.consumer_accept_lists
    content {
      project_id_or_num = consumer_accept_lists.value.project_id_or_num
      connection_limit  = consumer_accept_lists.value.connection_limit
    }
  }
}

# PSC consumer endpoints for internal services
resource "google_compute_address" "psc_consumer_endpoints" {
  for_each = var.psc_consumer_endpoints
  
  name         = each.value.name
  project      = var.host_project_id
  region       = each.value.region
  subnetwork   = each.value.subnetwork
  address_type = "INTERNAL"
  purpose      = "PRIVATE_SERVICE_CONNECT"
  
  depends_on = [google_compute_subnetwork.subnets]
}

resource "google_compute_forwarding_rule" "psc_consumer_endpoints" {
  for_each = var.psc_consumer_endpoints
  
  name                  = each.value.name
  project               = var.host_project_id
  region                = each.value.region
  target                = each.value.target_service
  load_balancing_scheme = ""
  network               = google_compute_network.vpc.id
  ip_address            = google_compute_address.psc_consumer_endpoints[each.key].id
  
  depends_on = [google_compute_address.psc_consumer_endpoints]
}

# DNS zones for PSC endpoints
resource "google_dns_managed_zone" "psc_dns_zones" {
  for_each = var.enable_private_service_connect ? var.psc_dns_zones : {}
  
  name        = each.value.name
  project     = var.host_project_id
  dns_name    = each.value.dns_name
  description = each.value.description
  
  visibility = "private"
  
  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc.id
    }
  }
}

# DNS records for PSC endpoints
resource "google_dns_record_set" "psc_dns_records" {
  for_each = var.enable_private_service_connect ? var.psc_dns_records : {}
  
  name         = each.value.name
  project      = var.host_project_id
  managed_zone = google_dns_managed_zone.psc_dns_zones[each.value.zone_key].name
  type         = each.value.type
  ttl          = each.value.ttl
  rrdatas      = each.value.rrdatas
}

# PSC connection tracking and monitoring
resource "google_monitoring_alert_policy" "psc_connection_alerts" {
  count = var.enable_private_service_connect && var.enable_psc_monitoring ? 1 : 0
  
  display_name = "${var.network_name} PSC Connection Monitoring"
  project      = var.host_project_id
  
  conditions {
    display_name = "PSC Connection Failures"
    
    condition_threshold {
      filter          = "resource.type=\"gce_forwarding_rule\""
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = var.psc_notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}