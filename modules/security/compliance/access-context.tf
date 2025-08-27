# Access Context Manager Configuration
resource "google_access_context_manager_access_level" "device_policy" {
  count  = var.enable_vpc_service_controls ? 1 : 0
  parent = google_access_context_manager_access_policy.policy[0].name
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy[0].name}/accessLevels/device_policy"
  title  = "Device Policy Access Level"
  
  basic {
    conditions {
      device_policy {
        require_screen_lock              = true
        require_admin_approval           = true
        require_corp_owned               = true
        allowed_encryption_statuses      = ["ENCRYPTED"]
        allowed_device_management_levels = ["MANAGED"]
        
        os_constraints {
          os_type                    = "DESKTOP_CHROME_OS"
          minimum_version           = "10.0"
          require_verified_chrome_os = true
        }
      }
    }
    
    conditions {
      members = [
        "user:admin@${replace(var.organization_id, "organizations/", "")}.com"
      ]
    }
  }
}

# Service perimeter with access levels
resource "google_access_context_manager_service_perimeter" "secure_perimeter" {
  count  = var.enable_vpc_service_controls ? 1 : 0
  parent = google_access_context_manager_access_policy.policy[0].name
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy[0].name}/servicePerimeters/secure_perimeter"
  title  = "Secure Perimeter with Device Policy"
  
  status {
    restricted_services = var.restricted_services
    
    resources = [
      "projects/${var.project_id}"
    ]
    
    access_levels = [
      google_access_context_manager_access_level.device_policy[0].name,
      google_access_context_manager_access_level.trusted_networks[0].name
    ]
    
    vpc_accessible_services {
      enable_restriction = true
      allowed_services   = var.restricted_services
    }
  }
  
  perimeter_type = "PERIMETER_TYPE_REGULAR"
}