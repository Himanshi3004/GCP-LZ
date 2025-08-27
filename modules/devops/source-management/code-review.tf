resource "google_cloudbuild_trigger" "code_review_trigger" {
  for_each = var.repositories
  
  project     = var.project_id
  name        = "${each.key}-code-review"
  description = "Code review automation for ${each.key}"
  
  source_to_build {
    uri       = google_sourcerepo_repository.repositories[each.key].url
    ref       = "refs/heads/*"
    repo_type = "CLOUD_SOURCE_REPOSITORIES"
  }
  
  build {
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = [
        "source", "repos", "clone", each.key,
        "--project=${var.project_id}"
      ]
    }
    
    step {
      name = "gcr.io/cloud-builders/git"
      args = [
        "diff", "--name-only", "HEAD~1", "HEAD"
      ]
      dir = each.key
    }
    
    step {
      name = "gcr.io/cloud-builders/docker"
      args = [
        "run", "--rm", "-v", "/workspace/${each.key}:/code",
        "github/super-linter:latest"
      ]
      env = [
        "DEFAULT_BRANCH=main",
        "RUN_LOCAL=true",
        "VALIDATE_ALL_CODEBASE=false"
      ]
    }
  }
  
  service_account = google_service_account.source_management.id
}

resource "google_pubsub_topic" "code_review_events" {
  name    = "code-review-events"
  project = var.project_id
  
  labels = var.labels
}

resource "google_cloud_scheduler_job" "code_quality_report" {
  name        = "code-quality-report"
  project     = var.project_id
  region      = "us-central1"
  description = "Weekly code quality report"
  schedule    = "0 9 * * 1"
  
  http_target {
    http_method = "POST"
    uri         = "https://cloudbuild.googleapis.com/v1/projects/${var.project_id}/triggers/${google_cloudbuild_trigger.code_review_trigger["landing-zone"].trigger_id}:run"
    
    oauth_token {
      service_account_email = google_service_account.source_management.email
    }
  }
}