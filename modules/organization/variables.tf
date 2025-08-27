variable "organization_id" {
  description = "The GCP organization ID"
  type        = string
}

variable "billing_account" {
  description = "The billing account ID"
  type        = string
}

variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
}

variable "domain_name" {
  description = "Organization domain name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_audit_logs" {
  description = "Enable audit logging"
  type        = bool
  default     = true
}

variable "enable_organization_policies" {
  description = "Enable organization policies"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "allowed_regions" {
  description = "List of allowed GCP regions"
  type        = list(string)
  default     = ["us-central1", "us-east1"]
}

variable "allowed_vpn_peer_ips" {
  description = "List of allowed VPN peer IP addresses"
  type        = list(string)
  default     = []
}

variable "prod_allowed_regions" {
  description = "List of allowed GCP regions for production environment"
  type        = list(string)
  default     = ["us-central1", "us-east1"]
}

variable "folder_policies" {
  description = "Folder-specific organization policies"
  type = map(object({
    allowed_services = optional(list(string))
    denied_services  = optional(list(string))
    location_restrictions = optional(list(string))
  }))
  default = {}
}