variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "source_repo_url" {
  description = "Source repository URL for policy validation"
  type        = string
}

variable "policy_frameworks" {
  description = "Compliance frameworks to enforce"
  type        = list(string)
  default     = ["cis", "nist", "pci-dss", "sox"]
}

variable "enable_drift_detection" {
  description = "Enable drift detection for infrastructure"
  type        = bool
  default     = true
}

variable "drift_detection_schedule" {
  description = "Cron schedule for drift detection"
  type        = string
  default     = "0 2 * * *"
}

variable "policy_violation_actions" {
  description = "Actions to take on policy violations"
  type = object({
    block_deployment = bool
    send_notification = bool
    create_ticket = bool
    auto_remediate = bool
  })
  default = {
    block_deployment = true
    send_notification = true
    create_ticket = false
    auto_remediate = false
  }
}

variable "notification_channels" {
  description = "Notification channels for policy violations"
  type        = list(string)
  default     = []
}

variable "exemption_labels" {
  description = "Labels that exempt resources from certain policies"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "github_owner" {
  description = "GitHub organization/user for policy repository"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository name for policies"
  type        = string
  default     = "gcp-landing-zone"
}

variable "compliance_check_schedule" {
  description = "Cron schedule for continuous compliance checking"
  type        = string
  default     = "0 */6 * * *"  # Every 6 hours
}

variable "organization_id" {
  description = "GCP Organization ID for SCC notifications"
  type        = string
  default     = ""
}

variable "enable_scc_notifications" {
  description = "Enable Security Command Center notifications"
  type        = bool
  default     = false
}

variable "policy_library_version" {
  description = "Version of the policy library to use"
  type        = string
  default     = "latest"
}

variable "auto_remediation_enabled" {
  description = "Enable automatic remediation of policy violations"
  type        = bool
  default     = false
}

variable "compliance_frameworks" {
  description = "Compliance frameworks to enforce with specific controls"
  type = map(object({
    enabled  = bool
    controls = list(string)
    severity = string
  }))
  default = {
    "cis-gcp" = {
      enabled  = true
      controls = ["1.1", "1.4", "2.2", "3.1", "3.6", "4.1", "4.2"]
      severity = "high"
    }
    "nist-800-53" = {
      enabled  = false
      controls = ["AC-2", "AC-3", "AU-2", "AU-3", "SC-7"]
      severity = "medium"
    }
    "pci-dss" = {
      enabled  = false
      controls = ["1.1", "2.1", "3.4", "8.1", "10.1"]
      severity = "high"
    }
  }
}

variable "remediation_timeout" {
  description = "Timeout for auto-remediation actions in seconds"
  type        = number
  default     = 300
}

variable "policy_exceptions" {
  description = "Policy exceptions for specific resources"
  type = map(object({
    resource_pattern = string
    policy_names     = list(string)
    justification    = string
    expiry_date      = string
  }))
  default = {}
}