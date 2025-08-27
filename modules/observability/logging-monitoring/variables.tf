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

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_log_sinks" {
  description = "Enable organization-level log sinks"
  type        = bool
  default     = true
}

variable "enable_bigquery_export" {
  description = "Enable BigQuery log export"
  type        = bool
  default     = true
}

variable "enable_log_archival" {
  description = "Enable long-term log archival to Cloud Storage"
  type        = bool
  default     = true
}

variable "enable_log_exclusions" {
  description = "Enable log exclusions to reduce costs"
  type        = bool
  default     = true
}

variable "enable_monitoring_dashboards" {
  description = "Enable monitoring dashboards"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention period in days for security logs"
  type        = number
  default     = 90
}

variable "application_log_retention_days" {
  description = "Log retention period in days for application logs"
  type        = number
  default     = 30
}

variable "archive_retention_days" {
  description = "Archive retention period in days"
  type        = number
  default     = 2555  # 7 years
}

variable "audit_log_sample_rate" {
  description = "Sampling rate for audit logs (0.0 to 1.0)"
  type        = number
  default     = 0.1
  
  validation {
    condition     = var.audit_log_sample_rate >= 0.0 && var.audit_log_sample_rate <= 1.0
    error_message = "Sample rate must be between 0.0 and 1.0."
  }
}

variable "network_log_sample_rate" {
  description = "Sampling rate for network logs (0.0 to 1.0)"
  type        = number
  default     = 0.01
  
  validation {
    condition     = var.network_log_sample_rate >= 0.0 && var.network_log_sample_rate <= 1.0
    error_message = "Sample rate must be between 0.0 and 1.0."
  }
}

variable "application_log_sample_rate" {
  description = "Sampling rate for application logs (0.0 to 1.0)"
  type        = number
  default     = 0.05
  
  validation {
    condition     = var.application_log_sample_rate >= 0.0 && var.application_log_sample_rate <= 1.0
    error_message = "Sample rate must be between 0.0 and 1.0."
  }
}

variable "archive_log_sample_rate" {
  description = "Sampling rate for archived logs (0.0 to 1.0)"
  type        = number
  default     = 0.001
  
  validation {
    condition     = var.archive_log_sample_rate >= 0.0 && var.archive_log_sample_rate <= 1.0
    error_message = "Sample rate must be between 0.0 and 1.0."
  }
}

variable "compliance_folders" {
  description = "Map of compliance folders requiring special log handling"
  type = map(object({
    folder_id = string
    name      = string
  }))
  default = {}
}

variable "folders" {
  description = "Folder structure for log sinks"
  type        = map(any)
  default     = {}
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}# Notification configuration
variable "security_email" {
  description = "Email address for security team notifications"
  type        = string
  default     = "security-team@example.com"
}

variable "operations_email" {
  description = "Email address for operations team notifications"
  type        = string
  default     = "ops-team@example.com"
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "pagerduty_key" {
  description = "PagerDuty service key for critical alerts"
  type        = string
  default     = ""
  sensitive   = true
}

# Alert thresholds
variable "failed_login_threshold" {
  description = "Threshold for failed login attempts per 5 minutes"
  type        = number
  default     = 10
}

variable "vpc_flow_anomaly_threshold" {
  description = "Threshold for VPC flow anomalies per 10 minutes"
  type        = number
  default     = 50
}

variable "data_exfiltration_threshold" {
  description = "Threshold for data exfiltration indicators per 5 minutes"
  type        = number
  default     = 5
}

variable "application_error_threshold" {
  description = "Threshold for application errors per 5 minutes"
  type        = number
  default     = 100
}

variable "high_latency_threshold" {
  description = "Threshold for high latency requests per 10 minutes"
  type        = number
  default     = 20
}

variable "expensive_operations_threshold" {
  description = "Threshold for expensive operations per 5 minutes"
  type        = number
  default     = 5
}

variable "disk_utilization_threshold" {
  description = "Disk utilization threshold (0.0 to 1.0)"
  type        = number
  default     = 0.85
  
  validation {
    condition     = var.disk_utilization_threshold >= 0.0 && var.disk_utilization_threshold <= 1.0
    error_message = "Disk utilization threshold must be between 0.0 and 1.0."
  }
}

# Uptime check configuration
variable "uptime_check_urls" {
  description = "Map of uptime check configurations"
  type = map(object({
    host             = string
    path             = string
    port             = number
    use_ssl          = bool
    validate_ssl     = bool
    expected_content = string
  }))
  default = {}
}# SLO Configuration
variable "availability_slo_target" {
  description = "Target availability SLO (0.0 to 1.0)"
  type        = number
  default     = 0.999
  
  validation {
    condition     = var.availability_slo_target >= 0.0 && var.availability_slo_target <= 1.0
    error_message = "Availability SLO target must be between 0.0 and 1.0."
  }
}

variable "latency_slo_target" {
  description = "Target latency SLO (0.0 to 1.0)"
  type        = number
  default     = 0.95
  
  validation {
    condition     = var.latency_slo_target >= 0.0 && var.latency_slo_target <= 1.0
    error_message = "Latency SLO target must be between 0.0 and 1.0."
  }
}

variable "error_rate_slo_target" {
  description = "Target error rate SLO (0.0 to 1.0)"
  type        = number
  default     = 0.999
  
  validation {
    condition     = var.error_rate_slo_target >= 0.0 && var.error_rate_slo_target <= 1.0
    error_message = "Error rate SLO target must be between 0.0 and 1.0."
  }
}

variable "security_response_slo_target" {
  description = "Target security response SLO (0.0 to 1.0)"
  type        = number
  default     = 0.95
  
  validation {
    condition     = var.security_response_slo_target >= 0.0 && var.security_response_slo_target <= 1.0
    error_message = "Security response SLO target must be between 0.0 and 1.0."
  }
}

variable "data_processing_slo_target" {
  description = "Target data processing SLO (0.0 to 1.0)"
  type        = number
  default     = 0.98
  
  validation {
    condition     = var.data_processing_slo_target >= 0.0 && var.data_processing_slo_target <= 1.0
    error_message = "Data processing SLO target must be between 0.0 and 1.0."
  }
}

variable "latency_threshold_ms" {
  description = "Latency threshold in milliseconds"
  type        = number
  default     = 2000
}

variable "security_incident_threshold" {
  description = "Security incident threshold for SLO"
  type        = number
  default     = 5
}

variable "burn_rate_threshold" {
  description = "Burn rate threshold for alerts"
  type        = number
  default     = 2.0
}

variable "error_budget_threshold" {
  description = "Error budget threshold for alerts (0.0 to 1.0)"
  type        = number
  default     = 0.1
  
  validation {
    condition     = var.error_budget_threshold >= 0.0 && var.error_budget_threshold <= 1.0
    error_message = "Error budget threshold must be between 0.0 and 1.0."
  }
}