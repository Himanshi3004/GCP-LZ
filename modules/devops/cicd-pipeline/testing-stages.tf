resource "google_cloudbuild_trigger" "test_pipeline" {
  for_each = var.pipelines
  
  project     = var.project_id
  name        = "${each.key}-test-pipeline"
  description = "Test pipeline for ${each.key}"
  
  source_to_build {
    uri       = "https://source.developers.google.com/p/${var.project_id}/r/${each.value.source_repo}"
    ref       = "refs/heads/*"
    repo_type = "CLOUD_SOURCE_REPOSITORIES"
  }
  
  build {
    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["build", "-t", "test-${each.key}:$BUILD_ID", "."]
    }
    
    step {
      name = "gcr.io/cloud-builders/docker"
      args = [
        "run", "--rm", "-v", "/workspace:/workspace",
        "test-${each.key}:$BUILD_ID",
        "sh", "-c", "npm install && npm run lint"
      ]
    }
    
    step {
      name = "gcr.io/cloud-builders/docker"
      args = [
        "run", "--rm", "-v", "/workspace:/workspace",
        "test-${each.key}:$BUILD_ID",
        "sh", "-c", "npm run test:unit"
      ]
    }
    
    step {
      name = "gcr.io/cloud-builders/docker"
      args = [
        "run", "--rm", "-v", "/workspace:/workspace",
        "test-${each.key}:$BUILD_ID",
        "sh", "-c", "npm run test:integration"
      ]
    }
    
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = [
        "builds", "submit",
        "--config=cloudbuild-e2e.yaml",
        "--substitutions=_SERVICE_URL=https://${each.value.target_service}-dev-${random_id.service_suffix.hex}.a.run.app"
      ]
    }
  }
  
  service_account = google_service_account.cicd_pipeline.id
}

resource "random_id" "service_suffix" {
  byte_length = 4
}

resource "google_monitoring_alert_policy" "test_failure" {
  display_name = "CI/CD Test Failure"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Test pipeline failed"
    
    condition_threshold {
      filter          = "resource.type=\"cloud_build\""
      comparison      = "COMPARISON_EQ"
      threshold_value = 0
      duration        = "300s"
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "86400s"
  }
}