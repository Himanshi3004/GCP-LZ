output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "network_self_link" {
  description = "The self link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "subnets" {
  description = "Map of subnet names to subnet details with enhanced information"
  value = {
    for subnet in google_compute_subnetwork.subnets : subnet.name => {
      id                = subnet.id
      self_link         = subnet.self_link
      ip_cidr_range     = subnet.ip_cidr_range
      region            = subnet.region
      purpose           = subnet.purpose
      role              = subnet.role
      stack_type        = subnet.stack_type
      private_ip_google_access = subnet.private_ip_google_access
      secondary_ip_ranges = subnet.secondary_ip_range
      log_config = subnet.log_config
    }
  }
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = [for subnet in google_compute_subnetwork.subnets : subnet.id]
}

output "subnet_self_links" {
  description = "List of subnet self links"
  value       = [for subnet in google_compute_subnetwork.subnets : subnet.self_link]
}

output "psc_subnet" {
  description = "Private Service Connect subnet details"
  value = var.enable_private_service_connect ? {
    id            = google_compute_subnetwork.psc_subnet[0].id
    self_link     = google_compute_subnetwork.psc_subnet[0].self_link
    ip_cidr_range = google_compute_subnetwork.psc_subnet[0].ip_cidr_range
    region        = google_compute_subnetwork.psc_subnet[0].region
  } : null
}

output "router_ids" {
  description = "Map of region to router ID"
  value       = { for router in google_compute_router.router : router.region => router.id }
}

output "nat_ips" {
  description = "Map of region to NAT IP addresses"
  value = {
    for nat in google_compute_router_nat.nat : nat.region => nat.nat_ips
  }
}

# Private Service Connect outputs
output "psc_google_apis_ip" {
  description = "Private Service Connect IP address for Google APIs"
  value       = var.enable_private_service_connect ? google_compute_global_address.google_apis_psc[0].address : null
}

output "psc_service_ips" {
  description = "Map of service names to PSC IP addresses"
  value = var.enable_private_service_connect ? {
    for service, address in google_compute_global_address.service_psc : service => address.address
  } : {}
}

output "psc_forwarding_rules" {
  description = "Map of PSC forwarding rules"
  value = var.enable_private_service_connect ? {
    google_apis = google_compute_global_forwarding_rule.google_apis_psc[0].id
    services = {
      for service, rule in google_compute_global_forwarding_rule.service_psc : service => rule.id
    }
  } : {}
}

output "psc_service_attachments" {
  description = "Map of PSC service attachments for published services"
  value = {
    for service, attachment in google_compute_service_attachment.internal_services : service => {
      id                    = attachment.id
      connection_preference = attachment.connection_preference
      target_service        = attachment.target_service
    }
  }
}

output "psc_consumer_endpoints" {
  description = "Map of PSC consumer endpoints"
  value = {
    for endpoint, address in google_compute_address.psc_consumer_endpoints : endpoint => {
      ip_address = address.address
      region     = address.region
      subnetwork = address.subnetwork
    }
  }
}

output "psc_dns_zones" {
  description = "Map of PSC DNS zones"
  value = var.enable_private_service_connect ? {
    for zone, dns_zone in google_dns_managed_zone.psc_dns_zones : zone => {
      id       = dns_zone.id
      dns_name = dns_zone.dns_name
      name_servers = dns_zone.name_servers
    }
  } : {}
}

# Firewall outputs
output "firewall_rules" {
  description = "Map of firewall rule names to rule details"
  value = {
    deny_all_ingress = {
      id        = google_compute_firewall.deny_all_ingress.id
      name      = google_compute_firewall.deny_all_ingress.name
      direction = google_compute_firewall.deny_all_ingress.direction
      priority  = google_compute_firewall.deny_all_ingress.priority
    }
    allow_internal = {
      id        = google_compute_firewall.allow_internal.id
      name      = google_compute_firewall.allow_internal.name
      direction = google_compute_firewall.allow_internal.direction
      priority  = google_compute_firewall.allow_internal.priority
    }
    custom_rules = {
      for rule in google_compute_firewall.custom_rules : rule.name => {
        id        = rule.id
        name      = rule.name
        direction = rule.direction
        priority  = rule.priority
      }
    }
  }
}

# Subnet allocation documentation
output "subnet_allocation" {
  description = "Subnet allocation information for documentation"
  value       = local.subnet_allocation
}

# Network summary
output "network_summary" {
  description = "Summary of network configuration"
  value = {
    network_name = var.network_name
    host_project = var.host_project_id
    service_projects = var.service_project_ids
    subnet_count = length(var.subnets)
    regions = distinct([for subnet in var.subnets : subnet.region])
    total_ip_space = sum([for subnet in var.subnets : pow(2, 32 - tonumber(split("/", subnet.ip_cidr_range)[1]))])
    psc_enabled = var.enable_private_service_connect
    cloud_nat_enabled = var.enable_cloud_nat
    security_groups_enabled = var.enable_security_groups
  }
}