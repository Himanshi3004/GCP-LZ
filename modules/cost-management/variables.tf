variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "billing_account" {
  description = "The billing account ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

# Billing Export Configuration
variable "enable_billing_export" {
  description = "Enable billing export to BigQuery"
  type        = bool
  default     = true
}

variable "enable_storage_export" {
  description = "Enable billing export to Cloud Storage"
  type        = bool
  default     = true
}

variable "billing_data_retention_days" {
  description = "Number of days to retain billing data"
  type        = number
  default     = 365
}

# Budget Configuration
variable "enable_budget_alerts" {
  description = "Enable budget alerts"
  type        = bool
  default     = true
}

variable "budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 1000
}

variable "budget_threshold_percentages" {
  description = "Budget alert thresholds"
  type        = list(number)
  default     = [50, 80, 100]
}

variable "enable_forecast_alerts" {
  description = "Enable forecast-based budget alerts"
  type        = bool
  default     = true
}

# Cost Allocation
variable "cost_allocation_labels" {
  description = "Labels for cost allocation"
  type        = map(string)
  default = {
    team        = "platform"
    environment = "prod"
    cost_center = "engineering"
  }
}

# Cost Optimization
variable "enable_cost_optimization" {
  description = "Enable cost optimization features"
  type        = bool
  default     = true
}

variable "enable_rightsizing_recommendations" {
  description = "Enable rightsizing recommendations"
  type        = bool
  default     = true
}

variable "enable_idle_resource_cleanup" {
  description = "Enable idle resource cleanup automation"
  type        = bool
  default     = false
}

variable "cost_anomaly_threshold" {
  description = "Threshold for cost anomaly detection (percentage)"
  type        = number
  default     = 20
}

# FinOps Configuration
variable "enable_finops_practices" {
  description = "Enable FinOps practices and reporting"
  type        = bool
  default     = true
}

variable "chargeback_enabled" {
  description = "Enable chargeback reporting"
  type        = bool
  default     = true
}

variable "showback_enabled" {
  description = "Enable showback dashboards"
  type        = bool
  default     = true
}

# Notification Configuration
variable "notification_channels" {
  description = "Notification channels for cost alerts"
  type        = list(string)
  default     = []
}

variable "cost_alert_emails" {
  description = "Email addresses for cost alerts"
  type        = list(string)
  default     = []
}

# Common Labels
variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}