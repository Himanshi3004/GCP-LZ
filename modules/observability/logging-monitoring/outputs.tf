# Enhanced Outputs for Observability Module

# BigQuery Datasets
output "bigquery_dataset_id" {
  description = "The ID of the BigQuery dataset for security logs"
  value       = var.enable_bigquery_export ? google_bigquery_dataset.logs[0].dataset_id : null
}

output "application_logs_dataset_id" {
  description = "The ID of the BigQuery dataset for application logs"
  value       = var.enable_bigquery_export ? google_bigquery_dataset.application_logs[0].dataset_id : null
}

# Log Sinks
output "audit_logs_sink_name" {
  description = "The name of the aggregated audit logs sink"
  value       = var.enable_log_sinks ? google_logging_organization_sink.audit_logs_aggregated[0].name : null
}

output "security_events_sink_name" {
  description = "The name of the critical security events sink"
  value       = var.enable_log_sinks ? google_logging_organization_sink.security_events_critical[0].name : null
}

output "network_security_sink_name" {
  description = "The name of the network security logs sink"
  value       = var.enable_log_sinks ? google_logging_organization_sink.network_security[0].name : null
}

output "application_logs_sink_name" {
  description = "The name of the application logs sink"
  value       = var.enable_log_sinks ? google_logging_project_sink.application_logs[0].name : null
}

output "log_archive_bucket" {
  description = "The name of the log archive storage bucket"
  value       = var.enable_log_archival ? google_storage_bucket.log_archive[0].name : null
}

# Dashboards
output "security_dashboard_url" {
  description = "URL of the security overview dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.security_overview.id}?project=${var.project_id}"
}

output "infrastructure_dashboard_url" {
  description = "URL of the infrastructure overview dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.infrastructure_overview.id}?project=${var.project_id}"
}

output "application_dashboard_url" {
  description = "URL of the application overview dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.application_overview.id}?project=${var.project_id}"
}

output "cost_dashboard_url" {
  description = "URL of the cost overview dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.cost_overview.id}?project=${var.project_id}"
}

output "executive_dashboard_url" {
  description = "URL of the executive overview dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.executive_overview.id}?project=${var.project_id}"
}

output "slo_dashboard_url" {
  description = "URL of the SLO overview dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.slo_overview.id}?project=${var.project_id}"
}

# Log Metrics
output "log_metrics" {
  description = "List of created log-based metrics"
  value = [
    google_logging_metric.failed_login_attempts.name,
    google_logging_metric.privilege_escalation_attempts.name,
    google_logging_metric.firewall_rule_violations.name,
    google_logging_metric.vpc_flow_anomalies.name,
    google_logging_metric.data_exfiltration_indicators.name,
    google_logging_metric.application_errors.name,
    google_logging_metric.high_latency_requests.name,
    google_logging_metric.expensive_operations.name,
    google_logging_metric.policy_violations.name,
    google_logging_metric.encryption_key_usage.name
  ]
}

# SLO Resources
output "slo_service_id" {
  description = "The service ID for SLO monitoring"
  value       = google_monitoring_service.landing_zone_service.service_id
}

output "availability_slo_id" {
  description = "The ID of the availability SLO"
  value       = google_monitoring_slo.availability_slo.slo_id
}

output "latency_slo_id" {
  description = "The ID of the latency SLO"
  value       = google_monitoring_slo.latency_slo.slo_id
}

output "error_rate_slo_id" {
  description = "The ID of the error rate SLO"
  value       = google_monitoring_slo.error_rate_slo.slo_id
}

output "security_response_slo_id" {
  description = "The ID of the security response SLO"
  value       = google_monitoring_slo.security_response_slo.slo_id
}

output "data_processing_slo_id" {
  description = "The ID of the data processing SLO"
  value       = google_monitoring_slo.data_processing_slo.slo_id
}

# Notification Channels
output "security_notification_channel" {
  description = "The name of the security team notification channel"
  value       = google_monitoring_notification_channel.email_security.name
}

output "operations_notification_channel" {
  description = "The name of the operations team notification channel"
  value       = google_monitoring_notification_channel.email_ops.name
}

output "slack_notification_channel" {
  description = "The name of the Slack notification channel"
  value       = var.slack_webhook_url != "" ? google_monitoring_notification_channel.slack_security[0].name : null
}

output "pagerduty_notification_channel" {
  description = "The name of the PagerDuty notification channel"
  value       = var.pagerduty_key != "" ? google_monitoring_notification_channel.pagerduty[0].name : null
}

# BigQuery Views
output "security_events_view" {
  description = "The name of the security events BigQuery view"
  value       = var.enable_bigquery_export ? google_bigquery_table.security_events_view[0].table_id : null
}

output "network_analysis_view" {
  description = "The name of the network analysis BigQuery view"
  value       = var.enable_bigquery_export ? google_bigquery_table.network_analysis_view[0].table_id : null
}

# Service Account
output "service_account_email" {
  description = "Email of the logging and monitoring service account"
  value       = google_service_account.logging_monitoring.email
}

# Uptime Checks
output "uptime_check_ids" {
  description = "Map of uptime check IDs"
  value = {
    for k, v in google_monitoring_uptime_check_config.critical_service_check : k => v.uptime_check_id
  }
}

# Alert Policies
output "alert_policy_names" {
  description = "List of created alert policy names"
  value = [
    google_monitoring_alert_policy.failed_login_attempts.display_name,
    google_monitoring_alert_policy.privilege_escalation.display_name,
    google_monitoring_alert_policy.firewall_violations.display_name,
    google_monitoring_alert_policy.vpc_flow_anomalies.display_name,
    google_monitoring_alert_policy.data_exfiltration.display_name,
    google_monitoring_alert_policy.application_errors.display_name,
    google_monitoring_alert_policy.high_latency.display_name,
    google_monitoring_alert_policy.expensive_operations.display_name,
    google_monitoring_alert_policy.policy_violations.display_name,
    google_monitoring_alert_policy.compute_instance_down.display_name,
    google_monitoring_alert_policy.disk_utilization_high.display_name,
    google_monitoring_alert_policy.availability_burn_rate.display_name,
    google_monitoring_alert_policy.latency_burn_rate.display_name,
    google_monitoring_alert_policy.error_budget_exhaustion.display_name
  ]
}