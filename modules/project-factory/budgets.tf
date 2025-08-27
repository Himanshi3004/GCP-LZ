# Budget Configuration
# Creates budgets per project with thresholds and notifications

# Budget for each project
resource "google_billing_budget" "project_budgets" {
  for_each = var.projects
  
  billing_account = var.billing_account
  display_name    = "${each.key}-budget"
  
  budget_filter {
    projects = ["projects/${google_project.projects[each.key].number}"]
    
    # Filter by specific services if specified
    dynamic "services" {
      for_each = each.value.budget_services != null ? [1] : []
      content {
        service_names = each.value.budget_services
      }
    }
    
    # Filter by labels
    labels = {
      for k, v in merge(var.labels, each.value.labels) : k => [v]
    }
  }
  
  amount {
    specified_amount {
      currency_code = "USD"
      units = tostring(floor(each.value.budget_amount * local.project_types[each.value.type].budget_multiplier))
    }
  }
  
  # Threshold rules
  dynamic "threshold_rules" {
    for_each = [
      { percent = 0.5, spend_basis = "CURRENT_SPEND" },
      { percent = 0.8, spend_basis = "CURRENT_SPEND" },
      { percent = 0.9, spend_basis = "CURRENT_SPEND" },
      { percent = 1.0, spend_basis = "CURRENT_SPEND" },
      { percent = 1.0, spend_basis = "FORECASTED_SPEND" }
    ]
    
    content {
      threshold_percent = threshold_rules.value.percent
      spend_basis      = threshold_rules.value.spend_basis
    }
  }
  
  # Notification channels
  all_updates_rule {
    monitoring_notification_channels = [
      for email in var.budget_alert_emails : 
      google_monitoring_notification_channel.budget_alerts[email].id
    ]
    
    pubsub_topic = var.enable_budget_pubsub ? google_pubsub_topic.budget_alerts[0].id : null
    
    disable_default_iam_recipients = false
  }
  
  depends_on = [google_project.projects]
}

# Notification channels for budget alerts
resource "google_monitoring_notification_channel" "budget_alerts" {
  for_each = toset(var.budget_alert_emails)
  
  project      = var.project_id
  display_name = "Budget Alert - ${each.value}"
  type         = "email"
  
  labels = {
    email_address = each.value
  }
}

# Pub/Sub topic for budget alerts
resource "google_pubsub_topic" "budget_alerts" {
  count   = var.enable_budget_pubsub ? 1 : 0
  project = var.project_id
  name    = "budget-alerts"
  
  labels = var.labels
}

# Cloud Function for budget alert processing
resource "google_storage_bucket" "budget_function_source" {
  count    = var.enable_budget_automation ? 1 : 0
  project  = var.project_id
  name     = "${var.project_id}-budget-function-source"
  location = var.default_region
  
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

# Budget alert processing function
resource "google_storage_bucket_object" "budget_function_zip" {
  count  = var.enable_budget_automation ? 1 : 0
  name   = "budget-processor.zip"
  bucket = google_storage_bucket.budget_function_source[0].name
  source = "${path.module}/functions/budget-processor.zip"
}

resource "google_cloudfunctions_function" "budget_processor" {
  count   = var.enable_budget_automation ? 1 : 0
  project = var.project_id
  region  = var.default_region
  name    = "budget-alert-processor"
  
  source_archive_bucket = google_storage_bucket.budget_function_source[0].name
  source_archive_object = google_storage_bucket_object.budget_function_zip[0].name
  
  entry_point = "processBudgetAlert"
  runtime     = "python39"
  
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.budget_alerts[0].id
  }
  
  environment_variables = {
    PROJECT_ID = var.project_id
    SLACK_WEBHOOK_URL = var.slack_webhook_url
  }
  
  labels = var.labels
}