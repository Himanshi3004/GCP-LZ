# Quota Management
# Manages quotas per project type and monitors usage

locals {
  # Default quotas per project type
  default_quotas = {
    shared-vpc-host = {
      "compute.googleapis.com/cpus" = 100
      "compute.googleapis.com/instances" = 50
      "compute.googleapis.com/networks" = 5
      "compute.googleapis.com/firewalls" = 200
    }
    application = {
      "compute.googleapis.com/cpus" = 50
      "compute.googleapis.com/instances" = 25
      "container.googleapis.com/clusters" = 5
      "run.googleapis.com/services" = 100
    }
    data = {
      "bigquery.googleapis.com/slots" = 2000
      "storage.googleapis.com/buckets" = 100
      "pubsub.googleapis.com/topics" = 1000
      "dataflow.googleapis.com/jobs" = 25
    }
    security = {
      "securitycenter.googleapis.com/findings" = 10000
      "cloudkms.googleapis.com/keys" = 1000
      "dlp.googleapis.com/jobs" = 100
    }
    tooling = {
      "cloudbuild.googleapis.com/builds" = 1000
      "artifactregistry.googleapis.com/repositories" = 50
      "sourcerepo.googleapis.com/repositories" = 100
    }
  }
}

# Service account for quota management
resource "google_service_account" "quota_manager" {
  project      = var.project_id
  account_id   = "quota-manager"
  display_name = "Quota Management Service Account"
  description  = "Manages project quotas and monitors usage"
}

# IAM roles for quota management
resource "google_project_iam_member" "quota_manager_roles" {
  for_each = toset([
    "roles/serviceusage.serviceUsageConsumer",
    "roles/monitoring.editor",
    "roles/pubsub.editor"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.quota_manager.email}"
}

# Quota monitoring alerts
resource "google_monitoring_alert_policy" "quota_alerts" {
  for_each = var.projects
  
  project      = var.project_id
  display_name = "Quota Alert - ${each.key}"
  combiner     = "OR"
  
  conditions {
    display_name = "Quota usage high"
    
    condition_threshold {
      filter          = "resource.type=\"consumer_quota\" AND resource.labels.project_id=\"${google_project.projects[each.key].project_id}\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.8
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [
    for email in var.quota_alert_emails : 
    google_monitoring_notification_channel.quota_alerts[email].id
  ]
  
  alert_strategy {
    auto_close = "1800s"
  }
  
  depends_on = [google_project.projects]
}

# Notification channels for quota alerts
resource "google_monitoring_notification_channel" "quota_alerts" {
  for_each = toset(var.quota_alert_emails)
  
  project      = var.project_id
  display_name = "Quota Alert - ${each.value}"
  type         = "email"
  
  labels = {
    email_address = each.value
  }
}

# Pub/Sub topic for quota increase requests
resource "google_pubsub_topic" "quota_requests" {
  project = var.project_id
  name    = "quota-increase-requests"
  
  labels = var.labels
}

# Cloud Function for automated quota increase requests
resource "google_storage_bucket_object" "quota_function_zip" {
  count  = var.enable_quota_automation ? 1 : 0
  name   = "quota-manager.zip"
  bucket = google_storage_bucket.budget_function_source[0].name
  source = "${path.module}/functions/quota-manager.zip"
}

resource "google_cloudfunctions_function" "quota_manager" {
  count   = var.enable_quota_automation ? 1 : 0
  project = var.project_id
  region  = var.default_region
  name    = "quota-increase-manager"
  
  source_archive_bucket = google_storage_bucket.budget_function_source[0].name
  source_archive_object = google_storage_bucket_object.quota_function_zip[0].name
  
  entry_point = "processQuotaRequest"
  runtime     = "python39"
  
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.quota_requests.id
  }
  
  environment_variables = {
    PROJECT_ID = var.project_id
  }
  
  labels = var.labels
}

# Quota usage dashboard
resource "google_monitoring_dashboard" "quota_dashboard" {
  project        = var.project_id
  dashboard_json = jsonencode({
    displayName = "Project Quotas Dashboard"
    mosaicLayout = {
      tiles = [
        {
          width = 6
          height = 4
          widget = {
            title = "Quota Usage by Project"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"consumer_quota\""
                    aggregation = {
                      alignmentPeriod = "300s"
                      perSeriesAligner = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields = ["resource.labels.project_id"]
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Usage Percentage"
                scale = "LINEAR"
              }
            }
          }
        }
      ]
    }
  })
}