# Default deny-all ingress rule (highest priority)
resource "google_compute_firewall" "deny_all_ingress" {
  name    = "${var.network_name}-deny-all-ingress"
  project = var.host_project_id
  network = google_compute_network.vpc.name
  
  description = "Deny all ingress traffic by default"
  direction   = "INGRESS"
  priority    = 65534
  
  deny {
    protocol = "all"
  }
  
  source_ranges = ["0.0.0.0/0"]
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow internal communication within VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.network_name}-allow-internal"
  project = var.host_project_id
  network = google_compute_network.vpc.name
  
  description = "Allow internal communication within VPC"
  direction   = "INGRESS"
  priority    = 1000
  
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "icmp"
  }
  
  source_ranges = [for subnet in var.subnets : subnet.ip_cidr_range]
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow SSH from Identity-Aware Proxy
resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "${var.network_name}-allow-ssh-iap"
  project = var.host_project_id
  network = google_compute_network.vpc.name
  
  description = "Allow SSH from Identity-Aware Proxy"
  direction   = "INGRESS"
  priority    = 1000
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["ssh-allowed"]
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow RDP from Identity-Aware Proxy
resource "google_compute_firewall" "allow_rdp_iap" {
  name    = "${var.network_name}-allow-rdp-iap"
  project = var.host_project_id
  network = google_compute_network.vpc.name
  
  description = "Allow RDP from Identity-Aware Proxy"
  direction   = "INGRESS"
  priority    = 1000
  
  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }
  
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["rdp-allowed"]
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow health checks from Google Cloud Load Balancers
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.network_name}-allow-health-checks"
  project = var.host_project_id
  network = google_compute_network.vpc.name
  
  description = "Allow health checks from Google Cloud Load Balancers"
  direction   = "INGRESS"
  priority    = 1000
  
  allow {
    protocol = "tcp"
  }
  
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
  target_tags = ["lb-health-check"]
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Security group abstractions - Web tier
resource "google_compute_firewall" "web_tier_ingress" {
  count = var.enable_security_groups ? 1 : 0
  
  name    = "${var.network_name}-web-tier-ingress"
  project = var.host_project_id
  network = google_compute_network.vpc.name
  
  description = "Allow HTTP/HTTPS to web tier"
  direction   = "INGRESS"
  priority    = 1000
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  
  source_ranges = var.web_tier_allowed_sources
  target_tags   = ["web-tier"]
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Security group abstractions - App tier
resource "google_compute_firewall" "app_tier_ingress" {
  count = var.enable_security_groups ? 1 : 0
  
  name    = "${var.network_name}-app-tier-ingress"
  project = var.host_project_id
  network = google_compute_network.vpc.name
  
  description = "Allow app tier communication"
  direction   = "INGRESS"
  priority    = 1000
  
  allow {
    protocol = "tcp"
    ports    = var.app_tier_ports
  }
  
  source_tags = ["web-tier"]
  target_tags = ["app-tier"]
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Security group abstractions - Database tier
resource "google_compute_firewall" "db_tier_ingress" {
  count = var.enable_security_groups ? 1 : 0
  
  name    = "${var.network_name}-db-tier-ingress"
  project = var.host_project_id
  network = google_compute_network.vpc.name
  
  description = "Allow database tier communication"
  direction   = "INGRESS"
  priority    = 1000
  
  allow {
    protocol = "tcp"
    ports    = var.db_tier_ports
  }
  
  source_tags = ["app-tier"]
  target_tags = ["db-tier"]
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Custom firewall rules with enhanced logging
resource "google_compute_firewall" "custom_rules" {
  for_each = { for rule in var.firewall_rules : rule.name => rule }
  
  name        = each.value.name
  project     = var.host_project_id
  network     = google_compute_network.vpc.name
  description = each.value.description
  direction   = each.value.direction
  priority    = each.value.priority
  
  source_ranges      = each.value.ranges
  source_tags        = each.value.source_tags
  target_tags        = each.value.target_tags
  source_service_accounts = lookup(each.value, "source_service_accounts", [])
  target_service_accounts = lookup(each.value, "target_service_accounts", [])
  
  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
  
  dynamic "deny" {
    for_each = each.value.deny
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }
  
  log_config {
    metadata = lookup(each.value, "log_metadata", "INCLUDE_ALL_METADATA")
  }
  
  disabled = lookup(each.value, "disabled", false)
}

# Egress rules for controlled outbound access
resource "google_compute_firewall" "allow_egress_internet" {
  count = var.enable_egress_internet ? 1 : 0
  
  name    = "${var.network_name}-allow-egress-internet"
  project = var.host_project_id
  network = google_compute_network.vpc.name
  
  description = "Allow controlled egress to internet"
  direction   = "EGRESS"
  priority    = 1000
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["53"]
  }
  
  destination_ranges = ["0.0.0.0/0"]
  target_tags       = ["internet-egress"]
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Firewall insights configuration
resource "google_compute_firewall" "insights_test_rule" {
  count = var.enable_firewall_insights ? 1 : 0
  
  name    = "${var.network_name}-insights-test"
  project = var.host_project_id
  network = google_compute_network.vpc.name
  
  description = "Test rule for firewall insights"
  direction   = "INGRESS"
  priority    = 2000
  disabled    = true
  
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  
  source_ranges = ["10.0.0.0/8"]
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}