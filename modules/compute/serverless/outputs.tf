output "cloud_run_url" {
  description = "URL of the Cloud Run service"
  value       = var.enable_cloud_run ? google_cloud_run_service.default[0].status[0].url : null
}

output "cloud_function_url" {
  description = "URL of the Cloud Function"
  value       = var.enable_cloud_functions ? google_cloudfunctions_function.default[0].https_trigger_url : null
}

output "app_engine_url" {
  description = "URL of the App Engine application"
  value       = var.enable_app_engine ? "https://${var.project_id}.appspot.com" : null
}

output "vpc_connector_name" {
  description = "Name of the VPC Access Connector"
  value       = var.enable_cloud_run ? google_vpc_access_connector.connector[0].name : null
}

output "service_account_email" {
  description = "Email of the serverless service account"
  value       = google_service_account.serverless.email
}

output "task_queues" {
  description = "Cloud Tasks queue names"
  value       = var.enable_tasks ? [google_cloud_tasks_queue.default[0].name, google_cloud_tasks_queue.high_priority[0].name] : []
}

output "scheduler_jobs" {
  description = "Cloud Scheduler job names"
  value       = var.enable_scheduler ? [for job in google_cloud_scheduler_job.default : job.name] : []
}