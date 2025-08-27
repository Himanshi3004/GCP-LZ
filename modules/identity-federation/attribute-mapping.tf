# Attribute mapping configurations for identity providers

locals {
  # Standard attribute mappings for SAML
  saml_attribute_mappings = {
    "google.subject"        = "assertion.subject"
    "google.display_name"   = "assertion.displayName || assertion.name"
    "google.groups"         = "assertion.groups"
    "attribute.email"       = "assertion.email"
    "attribute.department"  = "assertion.department"
    "attribute.title"       = "assertion.title"
    "attribute.location"    = "assertion.location"
  }

  # Standard attribute mappings for OIDC
  oidc_attribute_mappings = {
    "google.subject"        = "assertion.sub"
    "google.display_name"   = "assertion.name"
    "google.groups"         = "assertion.groups"
    "attribute.email"       = "assertion.email"
    "attribute.department"  = "assertion.department"
    "attribute.title"       = "assertion.job_title"
  }

  # Conditional access expressions
  access_conditions = {
    domain_restriction = "assertion.email.endsWith('@${var.domain_name}')"
    mfa_required      = var.enable_mfa ? "assertion.auth_time > (now - duration('1h'))" : "true"
    environment_access = "assertion.groups.hasAny(['${var.environment}-users', 'platform-admins'])"
  }
}

# IAM policy data for workforce pool access
data "google_iam_policy" "workforce_pool_policy" {
  binding {
    role = "roles/iam.workforcePoolUser"
    members = [
      "principalSet://iam.googleapis.com/${google_iam_workforce_pool.main.name}/*"
    ]
    
    condition {
      title       = "Domain and MFA Check"
      description = "Require domain membership and MFA"
      expression  = join(" && ", [
        local.access_conditions.domain_restriction,
        local.access_conditions.mfa_required
      ])
    }
  }
}

# Project IAM binding for workforce pool users
resource "google_project_iam_binding" "workforce_users" {
  project = var.project_id
  role    = "roles/iam.workforcePoolUser"
  
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workforce_pool.main.name}/attribute.email/${var.domain_name}"
  ]
}