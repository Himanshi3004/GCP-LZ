variable "project_id" {
  description = "Project ID for identity federation resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Organization domain name"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "saml_providers" {
  description = "SAML identity providers configuration"
  type = map(object({
    display_name     = string
    description      = string
    idp_entity_id    = string
    sso_url          = string
    x509_certificate = string
  }))
  default = {}
}

variable "oidc_providers" {
  description = "OIDC identity providers configuration"
  type = map(object({
    display_name = string
    description  = string
    issuer_uri   = string
    client_id    = string
  }))
  default = {}
}

variable "enable_mfa" {
  description = "Enable MFA requirements"
  type        = bool
  default     = true
}