variable "organization_id" {
  description = "The GCP organization ID"
  type        = string
}

variable "billing_account" {
  description = "The billing account ID"
  type        = string
}

variable "folders" {
  description = "Folder hierarchy from organization module"
  type        = any
  default     = {}
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "name_prefix" {
  description = "Naming prefix for projects"
  type        = string
}

variable "default_region" {
  description = "Default region for resources"
  type        = string
  default     = "us-central1"
}

variable "enable_billing_export" {
  description = "Enable billing export to BigQuery"
  type        = bool
  default     = true
}

variable "budget_alert_threshold" {
  description = "Budget alert threshold percentage"
  type        = number
  default     = 80
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "projects" {
  description = "Projects to create with enhanced configuration"
  type = map(object({
    type           = string
    department     = string
    owner          = string
    budget_amount  = number
    budget_services = optional(list(string))
    labels         = optional(map(string), {})
    additional_contacts = optional(list(object({
      email      = string
      categories = list(string)
    })), [])
    budget_filters = optional(object({
      services                = optional(list(string))
      credit_types_treatment = optional(string)
    }))
  }))
  default = {
    "shared-vpc" = {
      type          = "shared-vpc-host"
      department    = "networking"
      owner         = "network-team@example.com"
      budget_amount = 1000
    }
    "security" = {
      type          = "security"
      department    = "security"
      owner         = "security-team@example.com"
      budget_amount = 500
    }
    "logging" = {
      type          = "application"
      department    = "shared-services"
      owner         = "platform-team@example.com"
      budget_amount = 300
    }
  }
}

variable "budget_thresholds" {
  description = "Budget threshold rules"
  type = list(object({
    threshold_percent = number
    spend_basis      = string
  }))
  default = [
    {
      threshold_percent = 50
      spend_basis      = "CURRENT_SPEND"
    },
    {
      threshold_percent = 80
      spend_basis      = "CURRENT_SPEND"
    },
    {
      threshold_percent = 100
      spend_basis      = "CURRENT_SPEND"
    }
  ]
}

variable "budget_notification_emails" {
  description = "Email addresses for budget notifications"
  type        = list(string)
  default     = []
}

variable "budget_pubsub_topic" {
  description = "Pub/Sub topic for budget notifications"
  type        = string
  default     = null
}

variable "enable_forecast_alerts" {
  description = "Enable forecast-based budget alerts"
  type        = bool
  default     = true
}

variable "forecast_budget_multiplier" {
  description = "Multiplier for forecast budget amount"
  type        = number
  default     = 1.2
}

variable "forecast_threshold_percent" {
  description = "Threshold percentage for forecast alerts"
  type        = number
  default     = 90
}

variable "enable_quota_monitoring" {
  description = "Enable quota monitoring alerts"
  type        = bool
  default     = true
}

variable "quota_alert_threshold" {
  description = "Quota usage threshold for alerts (percentage)"
  type        = number
  default     = 80
}

variable "quota_notification_emails" {
  description = "Email addresses for quota notifications"
  type        = list(string)
  default     = []
}

variable "project_policy_exceptions" {
  description = "Project-level organization policy exceptions"
  type = map(object({
    project             = string
    constraint          = string
    type               = string # "list" or "boolean"
    enforced           = optional(bool)
    allowed_values     = optional(list(string))
    denied_values      = optional(list(string))
    inherit_from_parent = optional(bool)
  }))
  default = {}
}
# Enhanced project configuration variables
variable "domain_name" {
  description = "Organization domain name for essential contacts"
  type        = string
}

variable "project_id" {
  description = "Management project ID for resources"
  type        = string
}

variable "budget_alert_emails" {
  description = "Email addresses for budget alerts"
  type        = list(string)
  default     = []
}

variable "enable_budget_pubsub" {
  description = "Enable Pub/Sub topic for budget alerts"
  type        = bool
  default     = false
}

variable "enable_budget_automation" {
  description = "Enable automated budget alert processing"
  type        = bool
  default     = false
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for budget notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "quota_alert_emails" {
  description = "Email addresses for quota alerts"
  type        = list(string)
  default     = []
}

variable "enable_quota_automation" {
  description = "Enable automated quota increase requests"
  type        = bool
  default     = false
}

variable "organization_contacts" {
  description = "Organization-level essential contacts"
  type = map(object({
    email      = string
    categories = list(string)
  }))
  default = {}
}

variable "folder_contacts" {
  description = "Folder-level essential contacts"
  type = map(map(object({
    email      = string
    categories = list(string)
  })))
  default = {}
}

variable "enable_project_archival" {
  description = "Enable project archival capabilities"
  type        = bool
  default     = true
}

variable "enable_project_lifecycle_automation" {
  description = "Enable automated project lifecycle management"
  type        = bool
  default     = false
}

variable "enable_project_migration" {
  description = "Enable project migration capabilities"
  type        = bool
  default     = false
}

variable "enable_automated_cleanup" {
  description = "Enable automated project cleanup"
  type        = bool
  default     = false
}

variable "cleanup_dry_run" {
  description = "Run cleanup in dry-run mode"
  type        = bool
  default     = true
}

variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
}