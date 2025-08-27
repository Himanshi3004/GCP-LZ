# Workforce identity federation pools
resource "google_iam_workforce_pool" "main" {
  workforce_pool_id = "${var.environment}-workforce-pool"
  parent            = "locations/global"
  location          = "global"
  display_name      = "Workforce Pool for ${var.environment}"
  description       = "Workforce identity pool for external identity providers"
  disabled          = false
  
  session_duration = "3600s"
}

# Access context manager policy for workforce pool
resource "google_access_context_manager_access_policy" "workforce_policy" {
  parent = "organizations/${data.google_organization.org.org_id}"
  title  = "${var.environment}-workforce-policy"
  
  lifecycle {
    prevent_destroy = true
  }
}

data "google_organization" "org" {
  domain = var.domain_name
}

# Access level for MFA requirement
resource "google_access_context_manager_access_level" "mfa_required" {
  count  = var.enable_mfa ? 1 : 0
  parent = "accessPolicies/${google_access_context_manager_access_policy.workforce_policy.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.workforce_policy.name}/accessLevels/mfa_required"
  title  = "MFA Required"
  
  basic {
    conditions {
      required_access_levels = []
      
      device_policy {
        require_screen_lock = true
        require_admin_approval = false
        require_corp_owned = false
      }
    }
  }
}