output "policy_validation_trigger_id" {
  description = "Policy validation trigger ID"
  value       = google_cloudbuild_trigger.policy_validation.trigger_id
}

output "drift_detection_trigger_id" {
  description = "Drift detection trigger ID"
  value       = var.enable_drift_detection ? google_cloudbuild_trigger.drift_detection[0].trigger_id : null
}

output "policy_artifacts_bucket" {
  description = "Policy artifacts bucket name"
  value       = google_storage_bucket.policy_artifacts.name
}

output "service_account_email" {
  description = "Policy enforcer service account email"
  value       = google_service_account.policy_enforcer.email
}

output "organization_policies" {
  description = "Organization policies created"
  value       = { for k, v in google_org_policy_policy.policies : k => v.name }
}

output "security_policies" {
  description = "Security policies created"
  value       = { for k, v in google_compute_security_policy.policies : k => v.name }
}

output "monitoring_policies" {
  description = "Monitoring alert policies for compliance"
  value       = { for k, v in google_monitoring_alert_policy.compliance_alerts : k => v.name }
}

output "policy_test_trigger_id" {
  description = "Policy test trigger ID"
  value       = google_cloudbuild_trigger.policy_test.trigger_id
}

output "policy_deploy_trigger_id" {
  description = "Policy deploy trigger ID"
  value       = google_cloudbuild_trigger.policy_deploy.trigger_id
}

output "compliance_scan_trigger_id" {
  description = "Compliance scan trigger ID"
  value       = google_cloudbuild_trigger.compliance_scan.trigger_id
}

output "policy_enforcer_function_name" {
  description = "Policy enforcer Cloud Function name"
  value       = google_cloudfunctions_function.policy_enforcer.name
}

output "auto_remediation_function_name" {
  description = "Auto-remediation Cloud Function name"
  value       = var.policy_violation_actions.auto_remediate ? google_cloudfunctions_function.auto_remediation[0].name : null
}

output "compliance_reporter_function_name" {
  description = "Compliance reporter Cloud Function name"
  value       = google_cloudfunctions_function.compliance_reporter.name
}

output "compliance_data_dataset" {
  description = "BigQuery dataset for compliance data"
  value       = google_bigquery_dataset.compliance_data.dataset_id
}

output "compliance_reports_bucket" {
  description = "Compliance reports storage bucket"
  value       = google_storage_bucket.compliance_reports.name
}

output "policy_event_topics" {
  description = "Pub/Sub topics for policy events"
  value       = { for k, v in google_pubsub_topic.policy_events : k => v.name }
}

output "compliance_notification_topic" {
  description = "Compliance notifications topic"
  value       = google_pubsub_topic.compliance_notifications.name
}

output "drift_alerts_topic" {
  description = "Drift alerts topic"
  value       = var.enable_drift_detection ? google_pubsub_topic.drift_alerts[0].name : null
}