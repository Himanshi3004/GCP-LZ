# Monitoring notification channels
resource "google_monitoring_notification_channel" "email_channels" {
  for_each = var.notification_config.email_addresses != null ? toset(var.notification_config.email_addresses) : []
  
  display_name = "SCC Email - ${each.value}"
  type         = "email"
  project      = var.project_id
  
  labels = {
    email_address = each.value
  }
}

resource "google_monitoring_notification_channel" "slack_channel" {
  count = var.notification_config.slack_webhook != null ? 1 : 0
  
  display_name = "SCC Slack Channel"
  type         = "slack"
  project      = var.project_id
  
  labels = {
    url = var.notification_config.slack_webhook
  }
}

# Alert policy for critical findings
resource "google_monitoring_alert_policy" "critical_findings" {
  display_name = "SCC Critical Findings"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Critical security findings"
    condition_threshold {
      filter          = "resource.type=\"gce_instance\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0
    }
  }
  
  notification_channels = concat(
    [for ch in google_monitoring_notification_channel.email_channels : ch.id],
    var.notification_config.slack_webhook != null ? [google_monitoring_notification_channel.slack_channel[0].id] : []
  )
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# Compliance monitoring dashboard
resource "google_monitoring_dashboard" "compliance_dashboard" {
  project        = var.project_id
  dashboard_json = jsonencode({
    displayName = "Security Compliance Dashboard"
    mosaicLayout = {
      tiles = []
    }
  })
}

# Service account for SCC operations
resource "google_service_account" "scc_service_account" {
  account_id   = "scc-service-account"
  display_name = "Security Command Center Service Account"
  project      = var.project_id
}

# BigQuery dataset for compliance data
resource "google_bigquery_dataset" "compliance_data" {
  dataset_id  = "scc_compliance_data"
  project     = var.project_id
  location    = "US"
  description = "Dataset for Security Command Center compliance data"

  labels = var.labels
}

# Pub/Sub topic for SCC findings
resource "google_pubsub_topic" "scc_findings" {
  count   = var.notification_config.pubsub_topic != null || var.auto_remediation_enabled ? 1 : 0
  name    = var.notification_config.pubsub_topic != null ? var.notification_config.pubsub_topic : "scc-findings"
  project = var.project_id

  labels = var.labels
}