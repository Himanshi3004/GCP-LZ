output "service_account_email" {
  description = "Email of the operations service account"
  value       = google_service_account.operations.email
}

output "trace_enabled" {
  description = "Whether Cloud Trace is enabled"
  value       = var.enable_trace
}

output "profiler_enabled" {
  description = "Whether Cloud Profiler is enabled"
  value       = var.enable_profiler
}

output "debugger_enabled" {
  description = "Whether Cloud Debugger is enabled"
  value       = var.enable_debugger
}

output "error_reporting_enabled" {
  description = "Whether Error Reporting is enabled"
  value       = var.enable_error_reporting
}

output "uptime_checks" {
  description = "List of uptime check configurations"
  value       = var.enable_uptime_checks ? google_monitoring_uptime_check_config.uptime_checks[*].display_name : []
}