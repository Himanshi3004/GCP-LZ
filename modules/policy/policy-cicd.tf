# Enhanced CI/CD integration for policy enforcement

# Cloud Build trigger for policy testing
resource "google_cloudbuild_trigger" "policy_test" {
  project     = var.project_id
  name        = "policy-test-trigger"
  description = "Tests OPA policies on pull requests"

  github {
    owner = var.github_owner
    name  = var.github_repo
    pull_request {
      branch = ".*"
    }
  }

  build {
    step {
      name = "gcr.io/cloud-builders/git"
      args = ["clone", "https://github.com/${var.github_owner}/${var.github_repo}.git", "."]
    }

    step {
      name = "openpolicyagent/opa:latest"
      args = ["test", "modules/policy/policies/", "modules/policy/tests/"]
    }

    step {
      name = "openpolicyagent/opa:latest"
      args = ["fmt", "--diff", "modules/policy/policies/"]
    }

    step {
      name = "gcr.io/cloud-builders/gcloud"
      script = <<-EOF
        #!/bin/bash
        echo "Policy validation completed successfully"
        if [ $? -eq 0 ]; then
          gcloud pubsub topics publish policy-validation-success --message="Policy tests passed for PR"
        else
          gcloud pubsub topics publish policy-validation-failure --message="Policy tests failed for PR"
          exit 1
        fi
      EOF
    }
  }

  service_account = google_service_account.policy_enforcer.id
}

# Cloud Build trigger for policy deployment
resource "google_cloudbuild_trigger" "policy_deploy" {
  project     = var.project_id
  name        = "policy-deploy-trigger"
  description = "Deploys validated policies to enforcement"

  github {
    owner = var.github_owner
    name  = var.github_repo
    push {
      branch = "^main$"
    }
  }

  build {
    step {
      name = "gcr.io/cloud-builders/git"
      args = ["clone", "https://github.com/${var.github_owner}/${var.github_repo}.git", "."]
    }

    step {
      name = "openpolicyagent/opa:latest"
      args = ["build", "modules/policy/policies/", "--bundle"]
    }

    step {
      name = "gcr.io/cloud-builders/gsutil"
      args = [
        "cp", "bundle.tar.gz",
        "gs://${google_storage_bucket.policy_artifacts.name}/bundles/policy-bundle-$(date +%Y%m%d-%H%M%S).tar.gz"
      ]
    }

    step {
      name = "gcr.io/cloud-builders/gsutil"
      args = [
        "cp", "bundle.tar.gz",
        "gs://${google_storage_bucket.policy_artifacts.name}/bundles/policy-bundle-latest.tar.gz"
      ]
    }

    step {
      name = "gcr.io/cloud-builders/gcloud"
      script = <<-EOF
        #!/bin/bash
        echo "Updating policy enforcement configuration..."
        gcloud functions deploy policy-enforcer \
          --source=modules/policy/functions/ \
          --entry-point=enforce_policies \
          --runtime=python39 \
          --trigger-topic=terraform-plan-events \
          --service-account=${google_service_account.policy_enforcer.email}
      EOF
    }
  }

  service_account = google_service_account.policy_enforcer.id
}

# Pub/Sub topics for policy events
resource "google_pubsub_topic" "policy_events" {
  for_each = toset([
    "policy-validation-success",
    "policy-validation-failure",
    "terraform-plan-events",
    "policy-violations"
  ])

  name    = each.value
  project = var.project_id

  labels = var.labels
}

# Cloud Function for policy enforcement
resource "google_cloudfunctions_function" "policy_enforcer" {
  name        = "policy-enforcer"
  project     = var.project_id
  region      = var.region
  runtime     = "python39"

  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.policy_artifacts.name
  source_archive_object = "policy-enforcer.zip"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.policy_events["terraform-plan-events"].name
  }

  entry_point = "enforce_policies"

  environment_variables = {
    POLICY_BUNDLE_URL = "gs://${google_storage_bucket.policy_artifacts.name}/bundles/policy-bundle-latest.tar.gz"
    PROJECT_ID        = var.project_id
  }

  service_account_email = google_service_account.policy_enforcer.email

  labels = var.labels
}

# Cloud Scheduler for continuous compliance checking
resource "google_cloud_scheduler_job" "compliance_check" {
  name        = "continuous-compliance-check"
  project     = var.project_id
  region      = var.region
  description = "Continuous compliance checking"
  schedule    = var.compliance_check_schedule

  http_target {
    http_method = "POST"
    uri         = "https://cloudbuild.googleapis.com/v1/projects/${var.project_id}/triggers/${google_cloudbuild_trigger.compliance_scan.trigger_id}:run"

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

# Cloud Build trigger for compliance scanning
resource "google_cloudbuild_trigger" "compliance_scan" {
  project     = var.project_id
  name        = "compliance-scan-trigger"
  description = "Scans infrastructure for compliance violations"

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
      args = ["plan", "-out=compliance-plan.tfplan"]
    }

    step {
      name = "openpolicyagent/conftest:latest"
      args = [
        "verify",
        "--policy", "modules/policy/policies/",
        "compliance-plan.tfplan"
      ]
    }

    step {
      name = "gcr.io/cloud-builders/gcloud"
      script = <<-EOF
        #!/bin/bash
        if [ $? -ne 0 ]; then
          echo "Compliance violations detected!"
          gcloud pubsub topics publish policy-violations \
            --message="Compliance violations detected in infrastructure"
          
          # Upload compliance report
          gsutil cp compliance-plan.tfplan \
            gs://${google_storage_bucket.policy_artifacts.name}/compliance-reports/$(date +%Y%m%d-%H%M%S)-violations.tfplan
        else
          echo "No compliance violations detected"
        fi
      EOF
    }
  }

  service_account = google_service_account.policy_enforcer.id
}