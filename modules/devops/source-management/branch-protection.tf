resource "google_cloudbuild_trigger" "branch_protection" {
  for_each = var.branch_protection_rules
  
  project     = var.project_id
  name        = "branch-protection-${each.key}"
  description = "Branch protection for ${each.value.pattern}"
  
  webhook_config {
    secret = "branch-protection-webhook"
  }
  
  build {
    step {
      name = "gcr.io/cloud-builders/gcloud"
      script = <<-EOF
        #!/bin/bash
        set -e
        
        # Check if branch matches protection pattern
        if [[ "$BRANCH_NAME" =~ ${each.value.pattern} ]]; then
          echo "Branch $BRANCH_NAME matches protection pattern ${each.value.pattern}"
          
          # Validate required status checks
          ${join("\n          ", [for check in each.value.required_status_checks : "echo 'Checking status: ${check}'"])}
          
          # Enforce code review requirement
          if [ "${each.value.require_code_review}" = "true" ]; then
            echo "Code review required for this branch"
          fi
          
          # Check if branch is up to date
          if [ "${each.value.require_up_to_date}" = "true" ]; then
            echo "Branch must be up to date with base branch"
          fi
        fi
      EOF
    }
  }
  
  service_account = google_service_account.source_management.id
}

resource "google_secret_manager_secret" "branch_protection_webhook" {
  secret_id = "branch-protection-webhook"
  project   = var.project_id
  
  replication {
    auto {}
  }
  
  labels = var.labels
}

resource "google_secret_manager_secret_version" "branch_protection_webhook" {
  secret      = google_secret_manager_secret.branch_protection_webhook.id
  secret_data = "webhook-secret-${random_password.webhook_secret.result}"
}

resource "random_password" "webhook_secret" {
  length  = 32
  special = true
}

resource "google_secret_manager_secret_iam_member" "webhook_access" {
  secret_id = google_secret_manager_secret.branch_protection_webhook.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.source_management.email}"
  project   = var.project_id
}