variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "enable_dlp" {
  description = "Enable Cloud DLP policies"
  type        = bool
  default     = true
}

variable "enable_kms" {
  description = "Enable Cloud KMS"
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

variable "dlp_templates" {
  description = "DLP inspect templates configuration"
  type = list(object({
    name         = string
    description  = string
    info_types   = list(string)
  }))
  default = [
    {
      name        = "pii-template"
      description = "Template for PII detection"
      info_types  = ["EMAIL_ADDRESS", "PHONE_NUMBER", "CREDIT_CARD_NUMBER"]
    }
  ]
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
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
  description = "Access Context Manager policy ID for key access justification"
  type        = string
  default     = ""
}

variable "data_bucket" {
  description = "GCS bucket name for DLP data scanning"
  type        = string
}

variable "bigquery_dataset_id" {
  description = "BigQuery dataset ID for DLP scanning"
  type        = string
  default     = "dlp_scan_dataset"
}

variable "default_region" {
  description = "Default GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "kms_key_ring_id" {
  description = "KMS key ring ID for DLP encryption"
  type        = string
}

variable "enable_dlp_automation" {
  description = "Enable DLP automation with Cloud Functions"
  type        = bool
  default     = false
}

variable "functions_bucket" {
  description = "GCS bucket for Cloud Functions source code"
  type        = string
}

variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
}

variable "application_service_accounts" {
  description = "Map of application service accounts"
  type        = map(object({
    email = string
  }))
  default = {}
}

variable "domain_name" {
  description = "Organization domain name"
  type        = string
}

variable "security_bucket" {
  description = "GCS bucket for security-related resources"
  type        = string
}

variable "notification_channels" {
  description = "List of notification channels for alerts"
  type        = list(string)
  default     = []
}