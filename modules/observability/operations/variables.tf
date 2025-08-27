# Enhanced Operations Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

# Feature toggles
variable "enable_trace" {
  description = "Enable Cloud Trace"
  type        = bool
  default     = true
}

variable "enable_profiler" {
  description = "Enable Cloud Profiler"
  type        = bool
  default     = true
}

variable "enable_debugger" {
  description = "Enable Cloud Debugger"
  type        = bool
  default     = true
}

variable "enable_error_reporting" {
  description = "Enable Error Reporting"
  type        = bool
  default     = true
}

variable "enable_uptime_checks" {
  description = "Enable uptime monitoring"
  type        = bool
  default     = true
}

variable "enable_distributed_tracing" {
  description = "Enable distributed tracing features"
  type        = bool
  default     = true
}

variable "enable_trace_export" {
  description = "Enable trace export to BigQuery"
  type        = bool
  default     = true
}

# Trace configuration
variable "trace_latency_threshold_ms" {
  description = "Latency threshold for trace alerts (milliseconds)"
  type        = number
  default     = 2000
}

variable "trace_error_rate_threshold" {
  description = "Error rate threshold for trace alerts"
  type        = number
  default     = 0.05
}

variable "trace_span_threshold" {
  description = "Span count threshold for distributed trace anomaly detection"
  type        = number
  default     = 1000
}

variable "min_trace_sampling_rate" {
  description = "Minimum acceptable trace sampling rate"
  type        = number
  default     = 0.001
  
  validation {
    condition     = var.min_trace_sampling_rate >= 0.0 && var.min_trace_sampling_rate <= 1.0
    error_message = "Trace sampling rate must be between 0.0 and 1.0."
  }
}

variable "trace_retention_days" {
  description = "Trace data retention period in days"
  type        = number
  default     = 30
}

# HTTP uptime checks configuration
variable "http_uptime_checks" {
  description = "Configuration for HTTP uptime checks"
  type = map(object({
    host                  = string
    path                  = string
    port                  = number
    use_ssl              = bool
    validate_ssl         = bool
    timeout              = string
    period               = string
    request_method       = string
    headers              = map(string)
    body                 = string
    content_type         = string
    auth_info = object({
      username = string
      password = string
    })
    content_matchers = list(object({
      content = string
      matcher = string
    }))
    regions              = list(string)
    checker_type         = string
    failure_threshold    = number
    failure_duration     = string
    auto_close_duration  = string
    enable_latency_alerts = bool
    latency_threshold_ms = number
  }))
  default = {}
}

# TCP uptime checks configuration
variable "tcp_uptime_checks" {
  description = "Configuration for TCP uptime checks"
  type = map(object({
    host                = string
    port                = number
    timeout             = string
    period              = string
    regions             = list(string)
    checker_type        = string
    failure_threshold   = number
    failure_duration    = string
    auto_close_duration = string
  }))
  default = {}
}

# User journey checks configuration
variable "user_journey_checks" {
  description = "Configuration for user journey monitoring"
  type = map(object({
    host            = string
    initial_path    = string
    port            = number
    use_ssl         = bool
    validate_ssl    = bool
    timeout         = string
    period          = string
    headers         = map(string)
    content_matchers = list(object({
      content = string
      matcher = string
    }))
    regions             = list(string)
    failure_threshold   = number
    failure_duration    = string
    auto_close_duration = string
  }))
  default = {}
}

# Global uptime checks configuration
variable "global_uptime_checks" {
  description = "Configuration for global uptime checks"
  type = map(object({
    host             = string
    path             = string
    port             = number
    use_ssl          = bool
    validate_ssl     = bool
    timeout          = string
    period           = string
    expected_content = string
  }))
  default = {}
}

# Notification channels
variable "notification_channels" {
  description = "List of notification channel names for alerts"
  type        = list(string)
  default     = []
}

# Legacy support
variable "uptime_check_urls" {
  description = "URLs to monitor for uptime (legacy - use http_uptime_checks instead)"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}