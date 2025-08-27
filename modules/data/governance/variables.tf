variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "organization_id" {
  description = "The GCP organization ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "enable_dlp" {
  description = "Enable Data Loss Prevention"
  type        = bool
  default     = true
}

variable "enable_data_catalog" {
  description = "Enable Data Catalog"
  type        = bool
  default     = true
}

variable "pii_info_types" {
  description = "PII information types to detect"
  type        = list(string)
  default = [
    "EMAIL_ADDRESS",
    "PHONE_NUMBER",
    "CREDIT_CARD_NUMBER",
    "US_SOCIAL_SECURITY_NUMBER"
  ]
}

variable "data_classification_levels" {
  description = "Data classification levels"
  type        = list(string)
  default     = ["PUBLIC", "INTERNAL", "CONFIDENTIAL", "RESTRICTED"]
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}