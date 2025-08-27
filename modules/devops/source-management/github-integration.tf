resource "google_cloudbuild_github_enterprise_config" "github_config" {
  count       = var.enable_github_integration && var.github_config != null ? 1 : 0
  project     = var.project_id
  config_id   = "github-integration"
  host_url    = "https://github.com"
  
  github_app {
    app_id           = var.github_config.app_id
    installation_id  = var.github_config.installation_id
  }
}

resource "google_cloudbuild_trigger" "github_pr_trigger" {
  for_each = var.enable_github_integration ? var.repositories : {}
  
  project     = var.project_id
  name        = "${each.key}-pr-trigger"
  description = "Trigger for ${each.key} pull requests"
  
  github {
    owner = var.github_config.owner
    name  = each.key
    
    pull_request {
      branch          = "^main$"
      comment_control = "COMMENTS_ENABLED"
    }
  }
  
  build {
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = ["builds", "submit", "--config=cloudbuild-pr.yaml"]
    }
  }
  
  service_account = google_service_account.source_management.id
}

resource "google_cloudbuild_trigger" "github_push_trigger" {
  for_each = var.enable_github_integration ? var.repositories : {}
  
  project     = var.project_id
  name        = "${each.key}-push-trigger"
  description = "Trigger for ${each.key} main branch pushes"
  
  github {
    owner = var.github_config.owner
    name  = each.key
    
    push {
      branch = "^main$"
    }
  }
  
  build {
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = ["builds", "submit", "--config=cloudbuild.yaml"]
    }
  }
  
  service_account = google_service_account.source_management.id
}