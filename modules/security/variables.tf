# Security Module Variables

# Common variables
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "organization_id" {
  description = "The GCP organization ID"
  type        = string
}

variable "organization_name" {
  description = "Organization name"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

# SCC variables
variable "enable_scc_premium" {
  description = "Enable Security Command Center Premium tier"
  type        = bool
  default     = true
}

variable "monitored_projects" {
  description = "List of project IDs to monitor with SCC"
  type        = list(string)
  default     = []
}

variable "compliance_standards" {
  description = "Compliance standards to monitor"
  type        = list(string)
  default     = ["CIS", "PCI-DSS", "NIST", "ISO27001"]
}

variable "enable_auto_remediation" {
  description = "Enable automated remediation for security findings"
  type        = bool
  default     = false
}

variable "scc_notification_config" {
  description = "Configuration for security notifications"
  type = object({
    pubsub_topic    = optional(string)
    email_addresses = optional(list(string))
    slack_webhook   = optional(string)
  })
  default = {}
}

variable "severity_threshold" {
  description = "Minimum severity level for notifications"
  type        = string
  default     = "MEDIUM"
}

# Data Protection variables
variable "enable_kms" {
  description = "Enable Cloud KMS"
  type        = bool
  default     = true
}

variable "enable_dlp" {
  description = "Enable Cloud DLP policies"
  type        = bool
  default     = true
}

variable "enable_cmek" {
  description = "Enable Customer Managed Encryption Keys"
  type        = bool
  default     = true
}

variable "key_rotation_period" {
  description = "Key rotation period in seconds"
  type        = string
  default     = "7776000s" # 90 days
}

variable "enable_access_justification" {
  description = "Enable access justification for key usage"
  type        = bool
  default     = false
}

variable "key_users" {
  description = "List of users/service accounts that can use encryption keys"
  type        = list(string)
  default     = []
}

variable "access_policy_id" {
  description = "Access Context Manager policy ID"
  type        = string
  default     = ""
}

variable "dlp_templates" {
  description = "DLP inspect templates configuration"
  type = list(object({
    name        = string
    description = string
    info_types  = list(string)
  }))
  default = [
    {
      name        = "pii-template"
      description = "Template for PII detection"
      info_types  = ["EMAIL_ADDRESS", "PHONE_NUMBER", "CREDIT_CARD_NUMBER"]
    }
  ]
}

# VPC Service Controls variables
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