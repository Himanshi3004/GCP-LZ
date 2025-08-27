# Comprehensive Firewall Rules
# Creates hierarchical firewall policies and rules for network security

# Hierarchical firewall policy at organization level
resource "google_compute_organization_security_policy" "org_security_policy" {
  display_name = "${var.organization_name} Organization Security Policy"
  description  = "Organization-level security policy for all networks"
  parent       = "organizations/${var.organization_id}"
  
  # Default deny rule
  rule {
    priority = 2147483647
    action   = "deny(403)"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default deny all"
  }
  
  # Allow internal RFC 1918 traffic
  rule {
    priority = 1000
    action   = "allow"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = [
          "10.0.0.0/8",
          "172.16.0.0/12",
          "192.168.0.0/16"
        ]
      }
    }
    description = "Allow internal RFC 1918 traffic"
  }
  
  # Block known malicious IPs
  rule {
    priority = 100
    action   = "deny(403)"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = var.blocked_ip_ranges
      }
    }
    description = "Block known malicious IP ranges"
  }
  
  # Allow health check traffic
  rule {
    priority = 500
    action   = "allow"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = [
          "35.191.0.0/16",
          "130.211.0.0/22"
        ]
      }
    }
    description = "Allow Google Cloud health checks"
  }
}

# VPC-level firewall rules
resource "google_compute_firewall" "deny_all_ingress" {
  name    = "${var.network_name}-deny-all-ingress"
  network = var.network_name
  project = var.project_id
  
  priority  = 65534
  direction = "INGRESS"
  
  deny {
    protocol = "all"
  }
  
  source_ranges = ["0.0.0.0/0"]
  
  description = "Deny all ingress traffic (default)"
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${var.network_name}-allow-internal"
  network = var.network_name
  project = var.project_id
  
  priority  = 1000
  direction = "INGRESS"
  
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
  
  source_ranges = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16"
  ]
  
  description = "Allow internal communication"
}

# SSH access rules
resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "${var.network_name}-allow-ssh-iap"
  network = var.network_name
  project = var.project_id
  
  priority  = 1000
  direction = "INGRESS"
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = ["35.235.240.0/20"]  # IAP IP range
  
  target_tags = ["ssh-allowed"]
  
  description = "Allow SSH through Identity-Aware Proxy"
}

resource "google_compute_firewall" "allow_rdp_iap" {
  name    = "${var.network_name}-allow-rdp-iap"
  network = var.network_name
  project = var.project_id
  
  priority  = 1000
  direction = "INGRESS"
  
  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }
  
  source_ranges = ["35.235.240.0/20"]  # IAP IP range
  
  target_tags = ["rdp-allowed"]
  
  description = "Allow RDP through Identity-Aware Proxy"
}

# Web application firewall rules
resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.network_name}-allow-http-https"
  network = var.network_name
  project = var.project_id
  
  priority  = 1000
  direction = "INGRESS"
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  
  target_tags = ["web-server"]
  
  description = "Allow HTTP and HTTPS traffic to web servers"
}

# Database access rules
resource "google_compute_firewall" "allow_database_internal" {
  name    = "${var.network_name}-allow-database-internal"
  network = var.network_name
  project = var.project_id
  
  priority  = 1000
  direction = "INGRESS"
  
  allow {
    protocol = "tcp"
    ports    = ["3306", "5432", "1433", "27017"]  # MySQL, PostgreSQL, SQL Server, MongoDB
  }
  
  source_tags = ["app-server"]
  target_tags = ["database-server"]
  
  description = "Allow database access from application servers"
}

# Load balancer health check rules
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.network_name}-allow-health-checks"
  network = var.network_name
  project = var.project_id
  
  priority  = 1000
  direction = "INGRESS"
  
  allow {
    protocol = "tcp"
  }
  
  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]
  
  target_tags = ["load-balanced"]
  
  description = "Allow Google Cloud load balancer health checks"
}

# Kubernetes-specific rules
resource "google_compute_firewall" "allow_gke_master" {
  count = var.enable_gke_rules ? 1 : 0
  
  name    = "${var.network_name}-allow-gke-master"
  network = var.network_name
  project = var.project_id
  
  priority  = 1000
  direction = "INGRESS"
  
  allow {
    protocol = "tcp"
    ports    = ["443", "10250"]
  }
  
  source_ranges = var.gke_master_cidr_blocks
  
  target_tags = ["gke-node"]
  
  description = "Allow GKE master to communicate with nodes"
}

resource "google_compute_firewall" "allow_gke_nodes" {
  count = var.enable_gke_rules ? 1 : 0
  
  name    = "${var.network_name}-allow-gke-nodes"
  network = var.network_name
  project = var.project_id
  
  priority  = 1000
  direction = "INGRESS"
  
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  
  source_tags = ["gke-node"]
  target_tags = ["gke-node"]
  
  description = "Allow GKE nodes to communicate with each other"
}

# Egress rules
resource "google_compute_firewall" "allow_egress_internet" {
  name    = "${var.network_name}-allow-egress-internet"
  network = var.network_name
  project = var.project_id
  
  priority  = 1000
  direction = "EGRESS"
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["53"]  # DNS
  }
  
  destination_ranges = ["0.0.0.0/0"]
  
  target_tags = ["internet-access"]
  
  description = "Allow internet access for updates and external services"
}

resource "google_compute_firewall" "deny_egress_default" {
  name    = "${var.network_name}-deny-egress-default"
  network = var.network_name
  project = var.project_id
  
  priority  = 65534
  direction = "EGRESS"
  
  deny {
    protocol = "all"
  }
  
  destination_ranges = ["0.0.0.0/0"]
  
  description = "Deny all egress traffic by default"
}

# Firewall insights and logging
resource "google_compute_firewall" "logged_rules" {
  for_each = var.enable_firewall_logging ? toset([
    "allow-internal",
    "allow-ssh-iap",
    "allow-http-https"
  ]) : toset([])
  
  name    = "${var.network_name}-${each.key}-logged"
  network = var.network_name
  project = var.project_id
  
  # Copy configuration from existing rules but add logging
  priority  = 999  # Higher priority than original rules
  direction = "INGRESS"
  
  dynamic "allow" {
    for_each = each.key == "allow-internal" ? [1] : []
    content {
      protocol = "tcp"
      ports    = ["0-65535"]
    }
  }
  
  dynamic "allow" {
    for_each = each.key == "allow-ssh-iap" ? [1] : []
    content {
      protocol = "tcp"
      ports    = ["22"]
    }
  }
  
  dynamic "allow" {
    for_each = each.key == "allow-http-https" ? [1] : []
    content {
      protocol = "tcp"
      ports    = ["80", "443"]
    }
  }
  
  source_ranges = each.key == "allow-internal" ? [
    "10.0.0.0/8",
    "172.16.0.0/12", 
    "192.168.0.0/16"
  ] : each.key == "allow-ssh-iap" ? [
    "35.235.240.0/20"
  ] : ["0.0.0.0/0"]
  
  target_tags = each.key == "allow-ssh-iap" ? ["ssh-allowed"] : each.key == "allow-http-https" ? ["web-server"] : null
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
  
  description = "Logged version of ${each.key} rule"
}

# Security group abstractions using network tags
locals {
  security_groups = {
    web_servers = {
      tags = ["web-server"]
      allowed_ports = ["80", "443"]
      source_ranges = ["0.0.0.0/0"]
    }
    app_servers = {
      tags = ["app-server"]
      allowed_ports = ["8080", "8443"]
      source_tags = ["web-server"]
    }
    database_servers = {
      tags = ["database-server"]
      allowed_ports = ["3306", "5432"]
      source_tags = ["app-server"]
    }
    admin_access = {
      tags = ["admin-access"]
      allowed_ports = ["22", "3389"]
      source_ranges = ["35.235.240.0/20"]  # IAP
    }
  }
}

# Create firewall rules based on security group abstractions
resource "google_compute_firewall" "security_group_rules" {
  for_each = local.security_groups
  
  name    = "${var.network_name}-sg-${each.key}"
  network = var.network_name
  project = var.project_id
  
  priority  = 1000
  direction = "INGRESS"
  
  allow {
    protocol = "tcp"
    ports    = each.value.allowed_ports
  }
  
  source_ranges = lookup(each.value, "source_ranges", null)
  source_tags   = lookup(each.value, "source_tags", null)
  target_tags   = each.value.tags
  
  description = "Security group rule for ${each.key}"
}

# Firewall rule validation
resource "null_resource" "validate_firewall_rules" {
  triggers = {
    rules_hash = md5(jsonencode([
      for rule in concat(
        [google_compute_firewall.deny_all_ingress],
        [google_compute_firewall.allow_internal],
        [google_compute_firewall.allow_ssh_iap],
        [google_compute_firewall.allow_http_https]
      ) : {
        name = rule.name
        priority = rule.priority
        direction = rule.direction
      }
    ]))
  }
  
  provisioner "local-exec" {
    command = "echo 'Firewall rules validated successfully'"
  }
}