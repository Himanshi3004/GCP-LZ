# Identity Federation Module - Main Configuration

# Enable required APIs
resource "google_project_service" "identity_apis" {
  for_each = toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "accesscontextmanager.googleapis.com",
    "cloudidentity.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  
  disable_on_destroy = false
}

# Conditional access policy for MFA enforcement
resource "google_access_context_manager_service_perimeter" "identity_perimeter" {
  count  = var.enable_mfa ? 1 : 0
  parent = "accessPolicies/${google_access_context_manager_access_policy.workforce_policy.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.workforce_policy.name}/servicePerimeters/identity_perimeter"
  title  = "Identity Federation Perimeter"
  
  status {
    restricted_services = [
      "iam.googleapis.com",
      "iamcredentials.googleapis.com"
    ]
    
    access_levels = var.enable_mfa ? [
      google_access_context_manager_access_level.mfa_required[0].name
    ] : []
  }
  
  perimeter_type = "PERIMETER_TYPE_REGULAR"
}