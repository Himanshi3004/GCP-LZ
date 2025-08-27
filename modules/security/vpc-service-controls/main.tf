# VPC Service Controls Implementation
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

# Enable Access Context Manager API
resource "google_project_service" "access_context_manager" {
  project = var.project_id
  service = "accesscontextmanager.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Create Access Policy
resource "google_access_context_manager_access_policy" "policy" {
  parent = "organizations/${var.organization_id}"
  title  = "${var.organization_name} Access Policy"
}

# Create Access Levels
resource "google_access_context_manager_access_level" "basic_level" {
  parent = "accessPolicies/${google_access_context_manager_access_policy.policy.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/basic_level"
  title  = "Basic Access Level"

  basic {
    conditions {
      ip_subnetworks = var.allowed_ip_ranges
    }
  }
}

# Create Service Perimeter
resource "google_access_context_manager_service_perimeter" "perimeter" {
  parent = "accessPolicies/${google_access_context_manager_access_policy.policy.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/servicePerimeters/${var.environment}_perimeter"
  title  = "${var.environment} Service Perimeter"

  status {
    restricted_services = var.restricted_services
    resources          = var.protected_projects

    access_levels = [
      google_access_context_manager_access_level.basic_level.name,
      google_access_context_manager_access_level.device_trust.name
    ]

    vpc_accessible_services {
      enable_restriction = true
      allowed_services   = var.allowed_services
    }

    # Ingress policies
    dynamic "ingress_policies" {
      for_each = var.ingress_policies
      content {
        ingress_from {
          sources {
            access_level = ingress_policies.value.access_level
          }
          identity_type = ingress_policies.value.identity_type
          identities    = ingress_policies.value.identities
        }
        ingress_to {
          resources = ingress_policies.value.resources
          dynamic "operations" {
            for_each = ingress_policies.value.operations
            content {
              service_name = operations.value.service_name
              dynamic "method_selectors" {
                for_each = operations.value.methods
                content {
                  method = method_selectors.value
                }
              }
            }
          }
        }
      }
    }

    # Egress policies
    dynamic "egress_policies" {
      for_each = var.egress_policies
      content {
        egress_from {
          identity_type = egress_policies.value.identity_type
          identities    = egress_policies.value.identities
        }
        egress_to {
          resources = egress_policies.value.resources
          dynamic "operations" {
            for_each = egress_policies.value.operations
            content {
              service_name = operations.value.service_name
              dynamic "method_selectors" {
                for_each = operations.value.methods
                content {
                  method = method_selectors.value
                }
              }
            }
          }
        }
      }
    }
  }

  perimeter_type = "PERIMETER_TYPE_REGULAR"
}

# Bridge perimeter for cross-environment communication
resource "google_access_context_manager_service_perimeter" "bridge_perimeter" {
  count = length(var.bridge_perimeter_projects) > 0 ? 1 : 0
  
  parent = "accessPolicies/${google_access_context_manager_access_policy.policy.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/servicePerimeters/${var.environment}_bridge"
  title  = "${var.environment} Bridge Perimeter"

  status {
    resources = var.bridge_perimeter_projects
  }

  perimeter_type = "PERIMETER_TYPE_BRIDGE"
}

# Device trust access level
resource "google_access_context_manager_access_level" "device_trust" {
  parent = "accessPolicies/${google_access_context_manager_access_policy.policy.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/device_trust"
  title  = "Device Trust Level"

  basic {
    conditions {
      device_policy {
        require_screen_lock              = true
        require_admin_approval           = var.environment == "prod"
        require_corp_owned               = var.environment == "prod"
        allowed_encryption_statuses      = ["ENCRYPTED"]
        allowed_device_management_levels = ["MANAGED"]
      }
      regions = var.allowed_regions
    }
  }
}

# Time-based access level
resource "google_access_context_manager_access_level" "time_based" {
  count = var.enable_time_based_access ? 1 : 0
  
  parent = "accessPolicies/${google_access_context_manager_access_policy.policy.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/time_based"
  title  = "Time-based Access Level"

  basic {
    conditions {
      ip_subnetworks = var.allowed_ip_ranges
      
      # Business hours only for production
      dynamic "required_access_levels" {
        for_each = var.environment == "prod" ? [1] : []
        content {
          # This would reference a business hours access level
        }
      }
    }
  }
}