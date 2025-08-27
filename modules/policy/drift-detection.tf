# Cloud Scheduler job for drift detection
resource "google_cloud_scheduler_job" "drift_detection" {
  count = var.enable_drift_detection ? 1 : 0
  
  name        = "drift-detection-job"
  project     = var.project_id
  region      = var.region
  description = "Scheduled drift detection for infrastructure"
  schedule    = var.drift_detection_schedule
  
  http_target {
    http_method = "POST"
    uri         = "https://cloudbuild.googleapis.com/v1/projects/${var.project_id}/triggers/${google_cloudbuild_trigger.drift_detection[0].trigger_id}:run"
    
    headers = {
      "Content-Type" = "application/json"
    }
    
    body = base64encode(jsonencode({
      branchName = "main"
    }))
    
    oauth_token {
      service_account_email = google_service_account.policy_enforcer.email
    }
  }
}

# Cloud Build trigger for drift detection
resource "google_cloudbuild_trigger" "drift_detection" {
  count = var.enable_drift_detection ? 1 : 0
  
  project     = var.project_id
  name        = "drift-detection-trigger"
  description = "Detects infrastructure drift"
  
  source_to_build {
    uri       = var.source_repo_url
    ref       = "refs/heads/main"
    repo_type = "CLOUD_SOURCE_REPOSITORIES"
  }
  
  build {
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = ["config", "set", "project", var.project_id]
    }
    
    step {
      name = "hashicorp/terraform:1.5"
      args = ["init"]
    }
    
    step {
      name = "hashicorp/terraform:1.5"
      args = ["plan", "-detailed-exitcode", "-out=drift-plan"]
    }
    
    step {
      name = "gcr.io/cloud-builders/gcloud"
      script = <<-EOF
        #!/bin/bash
        if [ $? -eq 2 ]; then
          echo "Infrastructure drift detected!"
          gcloud pubsub topics publish drift-alerts --message="Infrastructure drift detected in project ${var.project_id}"
          
          # Upload drift report
          gsutil cp drift-plan gs://${google_storage_bucket.policy_artifacts.name}/drift-reports/$(date +%Y%m%d-%H%M%S)-drift-plan
        else
          echo "No infrastructure drift detected"
        fi
      EOF
    }
  }
  
  service_account = google_service_account.policy_enforcer.id
}

# Pub/Sub topic for drift alerts
resource "google_pubsub_topic" "drift_alerts" {
  count = var.enable_drift_detection ? 1 : 0
  
  name    = "drift-alerts"
  project = var.project_id
  
  labels = var.labels
}

# Pub/Sub subscription for drift alerts
resource "google_pubsub_subscription" "drift_alerts_sub" {
  count = var.enable_drift_detection ? 1 : 0
  
  name    = "drift-alerts-sub"
  topic   = google_pubsub_topic.drift_alerts[0].name
  project = var.project_id
  
  message_retention_duration = "604800s"
  retain_acked_messages      = false
  ack_deadline_seconds       = 300
  
  labels = var.labels
}

# Cloud Function for drift remediation
resource "google_cloudfunctions_function" "drift_remediation" {
  count = var.policy_violation_actions.auto_remediate ? 1 : 0
  
  name        = "drift-remediation"
  project     = var.project_id
  region      = var.region
  runtime     = "python39"
  
  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.policy_artifacts.name
  source_archive_object = "drift-remediation.zip"
  
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.drift_alerts[0].name
  }
  
  entry_point = "remediate_drift"
  
  service_account_email = google_service_account.policy_enforcer.email
  
  labels = var.labels
}