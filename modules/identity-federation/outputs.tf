output "workforce_pool" {
  description = "Workforce identity pool configuration"
  value = {
    id           = google_iam_workforce_pool.main.workforce_pool_id
    name         = google_iam_workforce_pool.main.name
    display_name = google_iam_workforce_pool.main.display_name
  }
}

output "saml_providers" {
  description = "SAML identity providers"
  value = {
    for k, v in google_iam_workforce_pool_provider.saml_providers : k => {
      id           = v.provider_id
      name         = v.name
      display_name = v.display_name
    }
  }
}

output "oidc_providers" {
  description = "OIDC identity providers"
  value = {
    for k, v in google_iam_workforce_pool_provider.oidc_providers : k => {
      id           = v.provider_id
      name         = v.name
      display_name = v.display_name
    }
  }
}

output "access_policy" {
  description = "Access context manager policy"
  value = {
    name  = google_access_context_manager_access_policy.workforce_policy.name
    title = google_access_context_manager_access_policy.workforce_policy.title
  }
}

output "mfa_access_level" {
  description = "MFA access level configuration"
  value = var.enable_mfa ? {
    name  = google_access_context_manager_access_level.mfa_required[0].name
    title = google_access_context_manager_access_level.mfa_required[0].title
  } : null
}