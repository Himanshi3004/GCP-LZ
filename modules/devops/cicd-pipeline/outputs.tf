output "ci_pipeline_triggers" {
  description = "CI pipeline trigger IDs"
  value       = { for k, v in google_cloudbuild_trigger.ci_pipeline : k => v.trigger_id }
}

output "test_pipeline_triggers" {
  description = "Test pipeline trigger IDs"
  value       = { for k, v in google_cloudbuild_trigger.test_pipeline : k => v.trigger_id }
}

output "delivery_pipelines" {
  description = "Cloud Deploy delivery pipeline names"
  value       = { for k, v in google_clouddeploy_delivery_pipeline.pipeline : k => v.name }
}

output "deployment_targets" {
  description = "Cloud Deploy target names"
  value       = { for k, v in google_clouddeploy_target.targets : k => v.name }
}

output "cloud_run_services" {
  description = "Cloud Run service URLs"
  value       = { for k, v in google_cloud_run_service.services : k => v.status[0].url }
}

output "rollback_trigger_id" {
  description = "Rollback trigger ID"
  value       = var.enable_rollback ? google_cloudbuild_trigger.rollback_trigger[0].trigger_id : null
}

output "pubsub_topics" {
  description = "Pub/Sub topic names"
  value = {
    approval_requests  = google_pubsub_topic.approval_requests.name
    deployment_events = google_pubsub_topic.deployment_events.name
  }
}

output "build_artifacts_bucket" {
  description = "Build artifacts bucket name"
  value       = google_storage_bucket.build_artifacts.name
}

output "service_account_email" {
  description = "CI/CD pipeline service account email"
  value       = google_service_account.cicd_pipeline.email
}