variable "organization_id" {
  description = "The GCP organization ID"
  type        = string
}

variable "organization_name" {
  description = "Organization name"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges for access"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "protected_projects" {
  description = "List of project numbers to protect"
  type        = list(string)
  default     = []
}

variable "restricted_services" {
  description = "List of services to restrict"
  type        = list(string)
  default = [
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "bigtable.googleapis.com"
  ]
}

variable "allowed_services" {
  description = "List of services allowed within VPC"
  type        = list(string)
  default = [
    "storage.googleapis.com",
    "bigquery.googleapis.com"
  ]
}

variable "bridge_perimeter_projects" {
  description = "List of project numbers for bridge perimeter"
  type        = list(string)
  default     = []
}

variable "ingress_policies" {
  description = "Ingress policies configuration"
  type = list(object({
    access_level  = string
    identity_type = string
    identities    = list(string)
    resources     = list(string)
    operations = list(object({
      service_name = string
      methods      = list(string)
    }))
  }))
  default = []
}

variable "egress_policies" {
  description = "Egress policies configuration"
  type = list(object({
    identity_type = string
    identities    = list(string)
    resources     = list(string)
    operations = list(object({
      service_name = string
      methods      = list(string)
    }))
  }))
  default = []
}

variable "allowed_regions" {
  description = "List of allowed regions for access"
  type        = list(string)
  default     = ["US", "EU"]
}

variable "enable_time_based_access" {
  description = "Enable time-based access controls"
  type        = bool
  default     = false
}