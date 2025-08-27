# output "scc_organization_settings" {
#   description = "Security Command Center organization settings"
#   value = {
#     organization = google_scc_organization_settings.scc_settings.organization
#     asset_discovery_enabled = google_scc_organization_settings.scc_settings.enable_asset_discovery
#   }
# }

output "notification_config_id" {
  description = "Security Command Center notification configuration ID"
  value       = google_scc_notification_config.scc_notification.name
}

output "pubsub_topic_name" {
  description = "Pub/Sub topic name for SCC findings"
  value       = var.notification_config.pubsub_topic != null || var.auto_remediation_enabled ? google_pubsub_topic.scc_findings[0].name : null
}

output "custom_sources" {
  description = "Custom SCC sources created"
  value = {
    for k, v in google_scc_source.custom_sources : k => {
      name         = v.name
      display_name = v.display_name
    }
  }
}

output "custom_modules" {
  description = "Custom SCC modules created"
  value = {
    for k, v in google_scc_organization_custom_module.custom_modules : k => {
      name         = v.name
      display_name = v.display_name
      enablement_state = v.enablement_state
    }
  }
}

output "mute_configs" {
  description = "SCC mute configurations created"
  value = {
    for k, v in google_scc_mute_config.mute_rules : k => {
      name   = v.name
      filter = v.filter
    }
  }
}

output "notification_channels" {
  description = "Monitoring notification channels created"
  value = {
    email_channels = {
      for k, v in google_monitoring_notification_channel.email_channels : k => {
        id           = v.id
        display_name = v.display_name
        type         = v.type
      }
    }
    slack_channel = var.notification_config.slack_webhook != null ? {
      id           = google_monitoring_notification_channel.slack_channel[0].id
      display_name = google_monitoring_notification_channel.slack_channel[0].display_name
      type         = google_monitoring_notification_channel.slack_channel[0].type
    } : null
  }
}

output "compliance_dashboard_url" {
  description = "URL to the compliance monitoring dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.compliance_dashboard.id}?project=${var.project_id}"
}

output "bigquery_dataset" {
  description = "BigQuery dataset for compliance data"
  value = {
    dataset_id = google_bigquery_dataset.compliance_data.dataset_id
    project    = google_bigquery_dataset.compliance_data.project
    location   = google_bigquery_dataset.compliance_data.location
  }
}

output "service_account_email" {
  description = "Service account email for SCC operations"
  value       = google_service_account.scc_service_account.email
}

output "alert_policy_id" {
  description = "Alert policy ID for critical findings"
  value       = google_monitoring_alert_policy.critical_findings.name
}

output "organization_policies" {
  description = "Organization policies created for compliance"
  value = {}
}

output "compliance_report_schedule" {
  description = "Cloud Scheduler job for compliance reports"
  value = {
    name     = google_cloud_scheduler_job.compliance_report.name
    schedule = google_cloud_scheduler_job.compliance_report.schedule
  }
}

output "function_name" {
  description = "Cloud Function name for finding processing (if enabled)"
  value       = var.auto_remediation_enabled ? google_cloudfunctions2_function.finding_processor[0].name : null
}