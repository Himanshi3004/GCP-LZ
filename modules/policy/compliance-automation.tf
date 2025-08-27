# Compliance automation and remediation

# Auto-remediation Cloud Function
resource "google_cloudfunctions_function" "auto_remediation" {
  count = var.policy_violation_actions.auto_remediate ? 1 : 0

  name        = "compliance-auto-remediation"
  project     = var.project_id
  region      = var.region
  runtime     = "python39"

  available_memory_mb   = 1024
  timeout               = 540
  source_archive_bucket = google_storage_bucket.policy_artifacts.name
  source_archive_object = "auto-remediation.zip"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.policy_events["policy-violations"].name
  }

  entry_point = "remediate_violations"

  environment_variables = {
    PROJECT_ID           = var.project_id
    REMEDIATION_ENABLED  = var.policy_violation_actions.auto_remediate
    NOTIFICATION_TOPIC   = google_pubsub_topic.compliance_notifications.name
  }

  service_account_email = google_service_account.policy_enforcer.email

  labels = var.labels
}

# Compliance reporting Cloud Function
resource "google_cloudfunctions_function" "compliance_reporter" {
  name        = "compliance-reporter"
  project     = var.project_id
  region      = var.region
  runtime     = "python39"

  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.policy_artifacts.name
  source_archive_object = "compliance-reporter.zip"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.compliance_reports.name
  }

  entry_point = "generate_compliance_report"

  environment_variables = {
    PROJECT_ID        = var.project_id
    BIGQUERY_DATASET  = google_bigquery_dataset.compliance_data.dataset_id
    REPORT_BUCKET     = google_storage_bucket.compliance_reports.name
  }

  service_account_email = google_service_account.policy_enforcer.email

  labels = var.labels
}

# BigQuery dataset for compliance data
resource "google_bigquery_dataset" "compliance_data" {
  dataset_id  = "compliance_data"
  project     = var.project_id
  location    = var.region

  description = "Compliance and policy violation data"

  labels = var.labels
}

# BigQuery table for policy violations
resource "google_bigquery_table" "policy_violations" {
  dataset_id = google_bigquery_dataset.compliance_data.dataset_id
  table_id   = "policy_violations"
  project    = var.project_id

  schema = jsonencode([
    {
      name = "timestamp"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    },
    {
      name = "resource_type"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "resource_name"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "policy_name"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "violation_message"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "severity"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "environment"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "remediation_status"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "remediation_timestamp"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    }
  ])

  labels = var.labels
}

# Storage bucket for compliance reports
resource "google_storage_bucket" "compliance_reports" {
  name     = "${var.project_id}-compliance-reports"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  labels = var.labels
}

# Pub/Sub topics for compliance events
resource "google_pubsub_topic" "compliance_notifications" {
  name    = "compliance-notifications"
  project = var.project_id

  labels = var.labels
}

resource "google_pubsub_topic" "compliance_reports" {
  name    = "compliance-reports"
  project = var.project_id

  labels = var.labels
}

# Cloud Scheduler for daily compliance reports
resource "google_cloud_scheduler_job" "daily_compliance_report" {
  name        = "daily-compliance-report"
  project     = var.project_id
  region      = var.region
  description = "Generate daily compliance report"
  schedule    = "0 8 * * *"  # Daily at 8 AM

  pubsub_target {
    topic_name = google_pubsub_topic.compliance_reports.id
    data = base64encode(jsonencode({
      report_type = "daily"
      timestamp   = "{{.timestamp}}"
    }))
  }
}

# Monitoring alert for policy violations
resource "google_monitoring_alert_policy" "policy_violation_alert" {
  display_name = "Policy Violation Alert"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "High severity policy violations"

    condition_threshold {
      filter = "resource.type=\"pubsub_topic\" AND resource.labels.topic_id=\"policy-violations\""
      comparison = "COMPARISON_GREATER_THAN"
      threshold_value = 0
      duration = "60s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "86400s"
  }

  enabled = true
}

# Log sink for audit trail
resource "google_logging_project_sink" "compliance_audit" {
  name        = "compliance-audit-sink"
  project     = var.project_id
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.compliance_data.dataset_id}"

  filter = <<-EOF
    (protoPayload.serviceName="cloudresourcemanager.googleapis.com" OR
     protoPayload.serviceName="iam.googleapis.com" OR
     protoPayload.serviceName="compute.googleapis.com") AND
    protoPayload.methodName!="storage.objects.get"
  EOF

  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
  }
}

# IAM binding for log sink
resource "google_project_iam_member" "compliance_audit_writer" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = google_logging_project_sink.compliance_audit.writer_identity
}

# Security Command Center notification for policy violations
resource "google_scc_notification_config" "policy_violations" {
  count = var.enable_scc_notifications ? 1 : 0

  config_id    = "policy-violations-notification"
  organization = var.organization_id
  description  = "Notification for policy violations detected by SCC"
  pubsub_topic = google_pubsub_topic.compliance_notifications.id

  streaming_config {
    filter = "category=\"POLICY_VIOLATION\" AND state=\"ACTIVE\""
  }
}