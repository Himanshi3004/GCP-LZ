output "backup_service_account_email" {
  description = "Email of the backup service account"
  value       = google_service_account.backup_sa.email
}

output "backup_monitor_service_account_email" {
  description = "Email of the backup monitoring service account"
  value       = google_service_account.backup_monitor_sa.email
}

output "snapshot_policies" {
  description = "Compute snapshot policies"
  value = {
    daily  = google_compute_resource_policy.snapshot_policy.name
    weekly = google_compute_resource_policy.weekly_snapshot_policy.name
  }
}

output "gke_backup_plans" {
  description = "GKE backup plan names"
  value = {
    daily  = { for k, v in google_gke_backup_backup_plan.plans : k => v.name }
    weekly = { for k, v in google_gke_backup_backup_plan.weekly_plans : k => v.name }
  }
}

output "gke_restore_plans" {
  description = "GKE restore plan names"
  value = { for k, v in google_gke_backup_restore_plan.plans : k => v.name }
}

output "backup_buckets" {
  description = "Backup storage bucket names"
  value = { for k, v in google_storage_bucket.backup_buckets : k => v.name }
}

output "application_backup_buckets" {
  description = "Application backup bucket names"
  value = { for k, v in google_storage_bucket.application_backup : k => v.name }
}

output "sql_backup_instances" {
  description = "SQL instances with backup configuration"
  value = { for k, v in google_sql_database_instance.backup_config : k => v.name }
}

output "sql_replica_instances" {
  description = "Cross-region SQL replica instances"
  value = { for k, v in google_sql_database_instance.cross_region_replica : k => v.name }
}

output "backup_notification_topics" {
  description = "PubSub topics for backup notifications"
  value = {
    gke_notifications    = google_pubsub_topic.gke_backup_notifications.name
    test_results        = google_pubsub_topic.backup_test_results.name
    validation_results  = google_pubsub_topic.backup_validation_results.name
  }
}

output "backup_monitoring_policies" {
  description = "Backup monitoring alert policy names"
  value = {
    snapshot_failure     = var.enable_backup_monitoring ? google_monitoring_alert_policy.snapshot_failure[0].name : null
    sql_backup_failure   = var.enable_backup_monitoring ? google_monitoring_alert_policy.sql_backup_failure[0].name : null
    sql_backup_age       = var.enable_backup_monitoring ? google_monitoring_alert_policy.sql_backup_age[0].name : null
    gke_backup_failure   = var.enable_backup_monitoring ? google_monitoring_alert_policy.gke_backup_failure[0].name : null
    app_backup_failure   = var.enable_backup_monitoring ? google_monitoring_alert_policy.application_backup_failure[0].name : null
    backup_sla_violation = var.enable_backup_monitoring ? google_monitoring_alert_policy.backup_sla_violation[0].name : null
  }
}

output "backup_test_triggers" {
  description = "Cloud Build triggers for backup testing"
  value = {
    backup_test        = var.enable_backup_testing ? google_cloudbuild_trigger.backup_test[0].name : null
    restore_test       = var.enable_backup_testing ? google_cloudbuild_trigger.backup_restore_test[0].name : null
  }
}

output "backup_schedules" {
  description = "Backup schedule configurations"
  value = {
    snapshot_schedule    = var.snapshot_schedule
    backup_test_schedule = var.backup_test_schedule
    retention_days       = var.backup_retention_days
    long_term_retention  = var.long_term_retention_days
  }
}