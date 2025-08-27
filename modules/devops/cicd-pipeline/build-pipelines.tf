resource "google_cloudbuild_trigger" "ci_pipeline" {
  for_each = var.pipelines
  
  project     = var.project_id
  name        = "${each.key}-ci-pipeline"
  description = "CI pipeline for ${each.key}"
  
  source_to_build {
    uri       = "https://source.developers.google.com/p/${var.project_id}/r/${each.value.source_repo}"
    ref       = "refs/heads/main"
    repo_type = "CLOUD_SOURCE_REPOSITORIES"
  }
  
  build {
    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["build", "-t", "gcr.io/${var.project_id}/${each.key}:$BUILD_ID", "."]
    }
    
    dynamic "step" {
      for_each = each.value.test_commands
      content {
        name = "gcr.io/cloud-builders/docker"
        args = ["run", "--rm", "gcr.io/${var.project_id}/${each.key}:$BUILD_ID", step.value]
      }
    }
    
    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["push", "gcr.io/${var.project_id}/${each.key}:$BUILD_ID"]
    }
    
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = [
        "run", "deploy", each.value.target_service,
        "--image=gcr.io/${var.project_id}/${each.key}:$BUILD_ID",
        "--region=${var.region}",
        "--platform=managed"
      ]
    }
  }
  
  service_account = google_service_account.cicd_pipeline.id
}

resource "google_storage_bucket" "build_artifacts" {
  name     = "${var.project_id}-build-artifacts"
  location = var.region
  project  = var.project_id
  
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
  
  labels = var.labels
}