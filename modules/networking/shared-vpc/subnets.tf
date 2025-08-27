# Create subnets with enhanced configuration
resource "google_compute_subnetwork" "subnets" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }
  
  name                     = each.value.name
  project                  = var.host_project_id
  network                  = google_compute_network.vpc.id
  ip_cidr_range           = each.value.ip_cidr_range
  region                  = each.value.region
  description             = each.value.description
  private_ip_google_access = each.value.private_ip_google_access
  
  # Enable flow logs with configurable settings
  log_config {
    aggregation_interval = lookup(each.value, "flow_logs_aggregation_interval", "INTERVAL_10_MIN")
    flow_sampling        = lookup(each.value, "flow_logs_sampling", 0.5)
    metadata             = lookup(each.value, "flow_logs_metadata", "INCLUDE_ALL_METADATA")
    metadata_fields      = lookup(each.value, "flow_logs_metadata_fields", [])
    filter_expr          = lookup(each.value, "flow_logs_filter", "true")
  }
  
  # Secondary IP ranges for GKE pods/services
  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ip_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
  
  # Purpose-specific configuration
  purpose          = lookup(each.value, "purpose", null)
  role             = lookup(each.value, "role", null)
  stack_type       = lookup(each.value, "stack_type", "IPV4_ONLY")
  ipv6_access_type = lookup(each.value, "ipv6_access_type", null)
  
  depends_on = [google_compute_network.vpc]
}

# IAM bindings for subnet-level access control
resource "google_compute_subnetwork_iam_binding" "subnet_users" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
    if lookup(subnet, "subnet_users", []) != []
  }
  
  project    = var.host_project_id
  region     = each.value.region
  subnetwork = google_compute_subnetwork.subnets[each.key].name
  role       = "roles/compute.networkUser"
  members    = each.value.subnet_users
}

resource "google_compute_subnetwork_iam_binding" "subnet_admins" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
    if lookup(subnet, "subnet_admins", []) != []
  }
  
  project    = var.host_project_id
  region     = each.value.region
  subnetwork = google_compute_subnetwork.subnets[each.key].name
  role       = "roles/compute.networkAdmin"
  members    = each.value.subnet_admins
}

# Private Service Connect subnet for Google APIs
resource "google_compute_subnetwork" "psc_subnet" {
  count = var.enable_private_service_connect ? 1 : 0
  
  name          = "${var.network_name}-psc-subnet"
  project       = var.host_project_id
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.psc_subnet_cidr
  region        = var.default_region
  purpose       = "PRIVATE_SERVICE_CONNECT"
  
  depends_on = [google_compute_network.vpc]
}

# Subnet allocation tracking and documentation
locals {
  subnet_allocation = {
    for subnet in var.subnets : subnet.name => {
      cidr           = subnet.ip_cidr_range
      region         = subnet.region
      purpose        = lookup(subnet, "purpose", "general")
      environment    = lookup(subnet, "environment", "unknown")
      workload_type  = lookup(subnet, "workload_type", "general")
      allocated_ips  = pow(2, 32 - tonumber(split("/", subnet.ip_cidr_range)[1]))
    }
  }
}

# Output subnet allocation for documentation
resource "local_file" "subnet_allocation_doc" {
  count = var.generate_subnet_docs ? 1 : 0
  
  filename = "${path.module}/subnet-allocation.json"
  content = jsonencode({
    network_name = var.network_name
    subnets      = local.subnet_allocation
    generated_at = timestamp()
  })
}