resource "google_cloudbuild_trigger" "rollback_trigger" {
  count = var.enable_rollback ? 1 : 0
  
  project     = var.project_id
  name        = "rollback-trigger"
  description = "Automatic rollback on deployment failure"
  
  webhook_config {
    secret = "rollback-webhook-secret"
  }
  
  build {
    step {
      name = "gcr.io/cloud-builders/gcloud"
      script = <<-EOF
        #!/bin/bash
        set -e
        
        SERVICE_NAME=$1
        ENVIRONMENT=$2
        PREVIOUS_REVISION=$3
        
        echo "Rolling back $SERVICE_NAME in $ENVIRONMENT to revision $PREVIOUS_REVISION"
        
        gcloud run services update-traffic $SERVICE_NAME-$ENVIRONMENT \
          --to-revisions=$PREVIOUS_REVISION=100 \
          --region=${var.region} \
          --project=${var.project_id}
        
        echo "Rollback completed successfully"
      EOF
      args = ["$_SERVICE_NAME", "$_ENVIRONMENT", "$_PREVIOUS_REVISION"]
    }
    
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = [
        "pubsub", "topics", "publish", "deployment-events",
        "--message={\"event\":\"rollback_completed\",\"service\":\"$_SERVICE_NAME\",\"environment\":\"$_ENVIRONMENT\"}"
      ]
    }
  }
  
  service_account = google_service_account.cicd_pipeline.id
}

resource "google_monitoring_alert_policy" "deployment_failure" {
  display_name = "Deployment Failure Alert"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Cloud Run service unhealthy"
    
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\""
      comparison      = "COMPARISON_LT"
      threshold_value = 0.95
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_pubsub_topic" "deployment_events" {
  name    = "deployment-events"
  project = var.project_id
  
  labels = var.labels
}

resource "google_pubsub_subscription" "deployment_events_sub" {
  name    = "deployment-events-sub"
  topic   = google_pubsub_topic.deployment_events.name
  project = var.project_id
  
  message_retention_duration = "86400s"
  retain_acked_messages      = false
  ack_deadline_seconds       = 20
  
  labels = var.labels
}

resource "google_secret_manager_secret" "rollback_webhook" {
  secret_id = "rollback-webhook-secret"
  project   = var.project_id
  
  replication {
    auto {}
  }
  
  labels = var.labels
}

resource "google_secret_manager_secret_version" "rollback_webhook" {
  secret      = google_secret_manager_secret.rollback_webhook.id
  secret_data = "rollback-webhook-${random_password.rollback_secret.result}"
}

resource "random_password" "rollback_secret" {
  length  = 32
  special = true
}