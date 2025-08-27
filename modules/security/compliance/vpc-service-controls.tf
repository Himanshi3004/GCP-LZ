# VPC Service Controls Configuration
resource "google_access_context_manager_access_policy" "policy" {
  count  = var.enable_vpc_service_controls ? 1 : 0
  parent = "organizations/${var.organization_id}"
  title  = "VPC Service Controls Policy"
}

# Service perimeter for restricted services
resource "google_access_context_manager_service_perimeter" "perimeter" {
  count  = var.enable_vpc_service_controls ? 1 : 0
  parent = google_access_context_manager_access_policy.policy[0].name
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy[0].name}/servicePerimeters/restricted_perimeter"
  title  = "Restricted Services Perimeter"
  
  status {
    restricted_services = var.restricted_services
    
    resources = [
      "projects/${var.project_id}"
    ]
    
    access_levels = []
    
    vpc_accessible_services {
      enable_restriction = true
      allowed_services   = var.restricted_services
    }
  }
  
  perimeter_type = "PERIMETER_TYPE_REGULAR"
}

# Access level for trusted networks
resource "google_access_context_manager_access_level" "trusted_networks" {
  count  = var.enable_vpc_service_controls ? 1 : 0
  parent = google_access_context_manager_access_policy.policy[0].name
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy[0].name}/accessLevels/trusted_networks"
  title  = "Trusted Networks"
  
  basic {
    conditions {
      ip_subnetworks = [
        "10.0.0.0/8",
        "172.16.0.0/12",
        "192.168.0.0/16"
      ]
    }
  }
}