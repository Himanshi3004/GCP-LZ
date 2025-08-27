resource "google_pubsub_topic" "approval_requests" {
  name    = "deployment-approval-requests"
  project = var.project_id
  
  labels = var.labels
}

resource "google_pubsub_subscription" "approval_requests_sub" {
  name    = "deployment-approval-requests-sub"
  topic   = google_pubsub_topic.approval_requests.name
  project = var.project_id
  
  message_retention_duration = "604800s"
  retain_acked_messages      = false
  ack_deadline_seconds       = 600
  
  labels = var.labels
}

resource "google_cloud_scheduler_job" "approval_reminder" {
  name        = "approval-reminder"
  project     = var.project_id
  region      = var.region
  description = "Reminder for pending approvals"
  schedule    = "0 9 * * 1-5"
  
  http_target {
    http_method = "POST"
    uri         = "https://cloudfunctions.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/functions/approval-reminder"
    
    headers = {
      "Content-Type" = "application/json"
    }
    
    body = base64encode(jsonencode({
      message = "Pending deployment approvals require attention"
    }))
    
    oauth_token {
      service_account_email = google_service_account.cicd_pipeline.email
    }
  }
}

resource "google_cloudfunctions_function" "approval_handler" {
  name        = "approval-handler"
  project     = var.project_id
  region      = var.region
  runtime     = "python39"
  
  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.build_artifacts.name
  source_archive_object = "approval-handler.zip"
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.approval_requests.name
  }
  
  entry_point = "handle_approval"
  
  service_account_email = google_service_account.cicd_pipeline.email
  
  labels = var.labels
}

resource "google_storage_bucket_object" "approval_handler_source" {
  name   = "approval-handler.zip"
  bucket = google_storage_bucket.build_artifacts.name
  source = "${path.module}/functions/approval-handler.zip"
}