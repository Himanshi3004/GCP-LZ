# SCC Automated Remediation Configuration

# Cloud Function for automated remediation
resource "google_cloudfunctions2_function" "auto_remediation" {
  count    = var.auto_remediation_enabled ? 1 : 0
  name     = "scc-auto-remediation"
  project  = var.project_id
  location = "us-central1"
  
  build_config {
    runtime     = "python39"
    entry_point = "remediate_finding"
    source {
      storage_source {
        bucket = google_storage_bucket.remediation_source[0].name
        object = google_storage_bucket_object.remediation_source[0].name
      }
    }
  }
  
  service_config {
    max_instance_count = 10
    available_memory   = "512M"
    timeout_seconds    = 300
    environment_variables = {
      PROJECT_ID = var.project_id
      ORG_ID     = var.organization_id
    }
  }
  
  event_trigger {
    trigger_region = "us-central1"
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.scc_findings[0].id
  }
}

# Storage bucket for remediation function source
resource "google_storage_bucket" "remediation_source" {
  count    = var.auto_remediation_enabled ? 1 : 0
  name     = "${var.project_id}-scc-remediation-source"
  project  = var.project_id
  location = "US"
  
  uniform_bucket_level_access = true
}

# Remediation function source code
resource "google_storage_bucket_object" "remediation_source" {
  count  = var.auto_remediation_enabled ? 1 : 0
  name   = "remediation-source.zip"
  bucket = google_storage_bucket.remediation_source[0].name
  source = "${path.module}/templates/remediation_function.zip"
}

# Pub/Sub subscription for remediation
resource "google_pubsub_subscription" "remediation_subscription" {
  count = var.auto_remediation_enabled ? 1 : 0
  name  = "scc-remediation-subscription"
  topic = google_pubsub_topic.scc_findings[0].name
  
  ack_deadline_seconds = 300
  
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
  
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.remediation_dead_letter[0].id
    max_delivery_attempts = 5
  }
}

# Dead letter topic for failed remediations
resource "google_pubsub_topic" "remediation_dead_letter" {
  count   = var.auto_remediation_enabled ? 1 : 0
  name    = "scc-remediation-dead-letter"
  project = var.project_id
}

# Service account for remediation function
resource "google_service_account" "remediation_sa" {
  count        = var.auto_remediation_enabled ? 1 : 0
  account_id   = "scc-remediation-sa"
  display_name = "SCC Remediation Service Account"
  project      = var.project_id
}

# IAM roles for remediation service account
resource "google_project_iam_member" "remediation_roles" {
  for_each = var.auto_remediation_enabled ? toset([
    "roles/compute.instanceAdmin.v1",
    "roles/storage.admin",
    "roles/iam.securityAdmin",
    "roles/securitycenter.findingsEditor"
  ]) : []
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.remediation_sa[0].email}"
}

# Remediation playbooks configuration
resource "google_storage_bucket" "remediation_playbooks" {
  count    = var.auto_remediation_enabled ? 1 : 0
  name     = "${var.project_id}-scc-playbooks"
  project  = var.project_id
  location = "US"
  
  uniform_bucket_level_access = true
}

# Upload remediation playbooks
resource "google_storage_bucket_object" "playbooks" {
  for_each = var.auto_remediation_enabled ? toset([
    "vm_security_playbook.yaml",
    "storage_security_playbook.yaml",
    "iam_security_playbook.yaml"
  ]) : []
  
  name   = each.value
  bucket = google_storage_bucket.remediation_playbooks[0].name
  source = "${path.module}/templates/playbooks/${each.value}"
}

# Audit trail for remediation actions
resource "google_bigquery_dataset" "remediation_audit" {
  count       = var.auto_remediation_enabled ? 1 : 0
  dataset_id  = "scc_remediation_audit"
  project     = var.project_id
  location    = "US"
  description = "Audit trail for SCC automated remediation actions"
  
  labels = var.labels
}

# Remediation audit table
resource "google_bigquery_table" "remediation_log" {
  count      = var.auto_remediation_enabled ? 1 : 0
  dataset_id = google_bigquery_dataset.remediation_audit[0].dataset_id
  table_id   = "remediation_log"
  project    = var.project_id
  
  schema = jsonencode([
    {
      name = "timestamp"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    },
    {
      name = "finding_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "resource_name"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "remediation_action"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "status"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "details"
      type = "JSON"
      mode = "NULLABLE"
    }
  ])
}

# Notification for remediation failures
resource "google_monitoring_alert_policy" "remediation_failures" {
  count        = var.auto_remediation_enabled ? 1 : 0
  display_name = "SCC Remediation Failures"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Remediation function errors"
    condition_threshold {
      filter          = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"scc-auto-remediation\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5
    }
  }
  
  notification_channels = concat(
    [for ch in google_monitoring_notification_channel.email_channels : ch.id],
    var.notification_config.slack_webhook != null ? [google_monitoring_notification_channel.slack_channel[0].id] : []
  )
}