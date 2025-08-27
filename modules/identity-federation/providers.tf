# SAML identity providers
resource "google_iam_workforce_pool_provider" "saml_providers" {
  for_each = var.saml_providers

  workforce_pool_id = google_iam_workforce_pool.main.workforce_pool_id
  location          = "global"
  provider_id       = each.key
  display_name      = each.value.display_name
  description       = each.value.description
  disabled          = false

  saml {
    idp_metadata_xml = base64decode(each.value.x509_certificate)
  }

  attribute_mapping = {
    "google.subject"        = "assertion.subject"
    "google.display_name"   = "assertion.displayName"
    "google.groups"         = "assertion.groups"
    "attribute.department"  = "assertion.department"
  }

  attribute_condition = "true"
}

# OIDC identity providers
resource "google_iam_workforce_pool_provider" "oidc_providers" {
  for_each = var.oidc_providers

  workforce_pool_id = google_iam_workforce_pool.main.workforce_pool_id
  location          = "global"
  provider_id       = each.key
  display_name      = each.value.display_name
  description       = each.value.description
  disabled          = false

  oidc {
    issuer_uri  = each.value.issuer_uri
    client_id   = each.value.client_id
    web_sso_config {
      response_type             = "CODE"
      assertion_claims_behavior = "MERGE_USER_INFO_OVER_ID_TOKEN_CLAIMS"
    }
  }

  attribute_mapping = {
    "google.subject"      = "assertion.sub"
    "google.display_name" = "assertion.name"
    "google.groups"       = "assertion.groups"
    "attribute.email"     = "assertion.email"
  }

  attribute_condition = "assertion.email.endsWith('@${var.domain_name}')"
}