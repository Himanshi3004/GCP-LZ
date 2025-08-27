# Role Testing Framework for IAM Custom Roles

# Cloud Function for role permission validation
resource "google_cloudfunctions_function" "role_validator" {
  count = var.enable_role_testing ? 1 : 0

  project               = var.projects["security"].project_id
  name                  = "${var.organization_name}-role-validator"
  description           = "Validates custom role permissions against least privilege principles"
  runtime               = "python39"
  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.role_testing_bucket[0].name
  source_archive_object = google_storage_bucket_object.role_validator_source[0].name
  trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.role_validation_trigger[0].name
  }
  entry_point = "validate_role"
  
  environment_variables = {
    ORGANIZATION_ID = var.organization_id
    PROJECT_ID     = var.projects["security"].project_id
  }
}

# Storage bucket for role testing artifacts
resource "google_storage_bucket" "role_testing_bucket" {
  count = var.enable_role_testing ? 1 : 0

  project  = var.projects["security"].project_id
  name     = "${var.organization_name}-role-testing-${var.environment}"
  location = var.default_region
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
}

# Pub/Sub topic for role validation triggers
resource "google_pubsub_topic" "role_validation_trigger" {
  count = var.enable_role_testing ? 1 : 0

  project = var.projects["security"].project_id
  name    = "${var.organization_name}-role-validation-trigger"
}

# Cloud Function source code for role validator
resource "google_storage_bucket_object" "role_validator_source" {
  count = var.enable_role_testing ? 1 : 0

  bucket = google_storage_bucket.role_testing_bucket[0].name
  name   = "role-validator-source.zip"
  source = data.archive_file.role_validator_zip[0].output_path
}

data "archive_file" "role_validator_zip" {
  count = var.enable_role_testing ? 1 : 0

  type        = "zip"
  output_path = "/tmp/role-validator.zip"
  
  source {
    content = templatefile("${path.module}/templates/role_validator.py", {
      organization_id = var.organization_id
    })
    filename = "main.py"
  }
  
  source {
    content = file("${path.module}/templates/requirements.txt")
    filename = "requirements.txt"
  }
}

# BigQuery dataset for role analytics
resource "google_bigquery_dataset" "role_analytics" {
  count = var.enable_role_testing ? 1 : 0

  project    = var.projects["security"].project_id
  dataset_id = "role_analytics"
  location   = var.default_region
  
  description = "Dataset for IAM role usage analytics and testing"
  
  access {
    role          = "OWNER"
    user_by_email = google_service_account.security_sa[0].email
  }
  
  access {
    role   = "READER"
    domain = var.domain_name
  }
}

# BigQuery table for role usage tracking
resource "google_bigquery_table" "role_usage" {
  count = var.enable_role_testing ? 1 : 0

  project    = var.projects["security"].project_id
  dataset_id = google_bigquery_dataset.role_analytics[0].dataset_id
  table_id   = "role_usage"
  
  schema = jsonencode([
    {
      name = "timestamp"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    },
    {
      name = "role_name"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "permission"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "principal"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "resource"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "action"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "result"
      type = "STRING"
      mode = "REQUIRED"
    }
  ])
  
  time_partitioning {
    type  = "DAY"
    field = "timestamp"
  }
}

# Log sink for role usage analytics
resource "google_logging_project_sink" "role_usage_analytics" {
  count = var.enable_role_testing ? 1 : 0

  project     = var.projects["security"].project_id
  name        = "role-usage-analytics"
  destination = "bigquery.googleapis.com/projects/${var.projects["security"].project_id}/datasets/${google_bigquery_dataset.role_analytics[0].dataset_id}"
  
  filter = <<-EOT
    protoPayload.authorizationInfo.granted=true AND
    protoPayload.authorizationInfo.permission!="" AND
    protoPayload.authenticationInfo.principalEmail!=""
  EOT
  
  unique_writer_identity = true
  
  bigquery_options {
    use_partitioned_tables = true
  }
}

# Cloud Scheduler job for periodic role analysis
resource "google_cloud_scheduler_job" "role_analysis" {
  count = var.enable_role_testing ? 1 : 0

  project   = var.projects["security"].project_id
  region    = var.default_region
  name      = "role-analysis-job"
  
  schedule  = "0 6 * * 1" # Weekly on Monday at 6 AM
  time_zone = "UTC"
  
  pubsub_target {
    topic_name = google_pubsub_topic.role_validation_trigger[0].id
    data       = base64encode(jsonencode({
      action = "analyze_roles"
      type   = "weekly"
    }))
  }
}

# Monitoring alert for unused permissions
resource "google_monitoring_alert_policy" "unused_permissions" {
  count = var.enable_role_testing ? 1 : 0

  project      = var.projects["security"].project_id
  display_name = "Unused Role Permissions"
  
  conditions {
    display_name = "Permissions not used in 30 days"
    
    condition_threshold {
      filter = "resource.type=\"bigquery_table\" AND resource.labels.table_id=\"role_usage\""
      duration        = "300s"
      comparison      = "COMPARISON_LESS_THAN"
      threshold_value = 1
      
      aggregations {
        alignment_period     = "86400s"
        per_series_aligner  = "ALIGN_COUNT"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields     = ["resource.labels.permission"]
      }
    }
  }
  
  notification_channels = var.notification_channels
}

# Data Studio dashboard for role analytics
resource "google_storage_bucket_object" "role_dashboard_config" {
  count = var.enable_role_testing ? 1 : 0

  bucket  = google_storage_bucket.role_testing_bucket[0].name
  name    = "dashboards/role-analytics-dashboard.json"
  content = jsonencode({
    dashboard_name = "IAM Role Analytics"
    data_source = {
      type       = "bigquery"
      project_id = var.projects["security"].project_id
      dataset_id = google_bigquery_dataset.role_analytics[0].dataset_id
      table_id   = google_bigquery_table.role_usage[0].table_id
    }
    charts = [
      {
        type  = "time_series"
        title = "Role Usage Over Time"
        metrics = ["role_name", "permission"]
      },
      {
        type  = "table"
        title = "Least Used Permissions"
        metrics = ["permission", "usage_count"]
      },
      {
        type  = "pie_chart"
        title = "Permission Distribution by Role"
        metrics = ["role_name", "permission_count"]
      }
    ]
  })
}

# Local variables for role testing
locals {
  # Role testing configuration
  role_testing_config = {
    validation_schedule = "0 6 * * 1"
    retention_days     = 90
    alert_threshold    = 30
  }
  
  # Permissions that should be monitored closely
  sensitive_permissions = [
    "iam.serviceAccounts.actAs",
    "iam.serviceAccounts.getAccessToken",
    "resourcemanager.projects.setIamPolicy",
    "compute.instances.setMetadata",
    "storage.buckets.setIamPolicy"
  ]
  
  # Role categories for analysis
  role_categories = {
    admin      = ["networkAdmin", "emergencyResponder", "emergencyNetworkAdmin"]
    viewer     = ["securityReviewer", "monitoringViewerPlus", "computeViewerPlus"]
    deployer   = ["ciCdDeployer", "terraformDeployer"]
    specialist = ["dataAnalyst", "projectCreator"]
  }
}