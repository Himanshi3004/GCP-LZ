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

variable "enable_assured_workloads" {
  description = "Enable Assured Workloads"
  type        = bool
  default     = false
}

variable "enable_vpc_service_controls" {
  description = "Enable VPC Service Controls"
  type        = bool
  default     = true
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization"
  type        = bool
  default     = true
}

variable "compliance_regime" {
  description = "Compliance regime for Assured Workloads"
  type        = string
  default     = "FEDRAMP_MODERATE"
  validation {
    condition = contains([
      "FEDRAMP_MODERATE",
      "FEDRAMP_HIGH",
      "IL4",
      "CJIS",
      "HIPAA",
      "HITRUST",
      "EU_REGIONS_AND_SUPPORT",
      "CA_REGIONS_AND_SUPPORT"
    ], var.compliance_regime)
    error_message = "Invalid compliance regime."
  }
}

variable "restricted_services" {
  description = "List of services to restrict in VPC Service Controls"
  type        = list(string)
  default = [
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "bigtable.googleapis.com"
  ]
}

variable "billing_account" {
  description = "The billing account ID"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}