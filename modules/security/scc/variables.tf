variable "project_id" {
  description = "The GCP project ID where SCC will be configured"
  type        = string
}

variable "organization_id" {
  description = "The GCP organization ID"
  type        = string
}

variable "enable_premium_tier" {
  description = "Enable Security Command Center Premium tier"
  type        = bool
  default     = true
}

variable "notification_channels" {
  description = "List of notification channels for security findings"
  type = list(object({
    name         = string
    type         = string
    display_name = string
    labels       = map(string)
  }))
  default = []
}

variable "custom_modules" {
  description = "Custom Security Command Center modules to enable"
  type = list(object({
    name           = string
    display_name   = string
    enablement_state = string
  }))
  default = []
}

variable "finding_filters" {
  description = "Filters for security findings"
  type = list(object({
    name        = string
    description = string
    filter      = string
  }))
  default = []
}

variable "compliance_standards" {
  description = "Compliance standards to monitor"
  type        = list(string)
  default     = ["CIS", "PCI-DSS", "NIST", "ISO27001"]
}

variable "auto_remediation_enabled" {
  description = "Enable automated remediation for security findings"
  type        = bool
  default     = false
}

variable "notification_config" {
  description = "Configuration for security notifications"
  type = object({
    pubsub_topic = optional(string)
    email_addresses = optional(list(string))
    slack_webhook = optional(string)
  })
  default = {}
}

variable "severity_threshold" {
  description = "Minimum severity level for notifications (LOW, MEDIUM, HIGH, CRITICAL)"
  type        = string
  default     = "MEDIUM"
  
  validation {
    condition     = contains(["LOW", "MEDIUM", "HIGH", "CRITICAL"], var.severity_threshold)
    error_message = "Severity threshold must be one of: LOW, MEDIUM, HIGH, CRITICAL."
  }
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "monitored_projects" {
  description = "List of project IDs to monitor with SCC"
  type        = list(string)
  default     = []
}

variable "enable_vulnerability_scanning" {
  description = "Enable vulnerability scanning"
  type        = bool
  default     = true
}

variable "web_applications" {
  description = "List of web applications to scan"
  type        = list(string)
  default     = []
}

variable "gke_clusters" {
  description = "List of GKE clusters to monitor"
  type        = list(string)
  default     = []
}

variable "build_attestor_public_key" {
  description = "Public key for build attestor"
  type        = string
  default     = ""
}

variable "security_attestor_public_key" {
  description = "Public key for security attestor"
  type        = string
  default     = ""
}

variable "enable_scc_automation" {
  description = "Enable SCC automation with Cloud Functions"
  type        = bool
  default     = false
}

variable "functions_bucket" {
  description = "GCS bucket for Cloud Functions source code"
  type        = string
  default     = ""
}

variable "default_region" {
  description = "Default GCP region"
  type        = string
  default     = "us-central1"
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
}

variable "enable_auto_remediation" {
  description = "Enable automatic remediation of security findings"
  type        = bool
  default     = false
}