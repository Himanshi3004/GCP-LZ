# Monitoring Infrastructure Setup
# Creates monitoring workspace hierarchy, notification channels, and alert policies

# Monitoring workspace (automatically created with project)
# Configure workspace hierarchy
resource "google_monitoring_monitored_project" "monitored_projects" {
  for_each = var.projects
  
  metrics_scope = var.project_id
  name          = each.value.project_id
}

# Notification channels
resource "google_monitoring_notification_channel" "email_channels" {
  for_each = toset(var.notification_emails)
  
  project      = var.project_id
  display_name = "Email - ${each.value}"
  type         = "email"
  
  labels = {
    email_address = each.value
  }
  
  user_labels = var.labels
}

resource "google_monitoring_notification_channel" "slack_channel" {
  count = var.slack_webhook_url != "" ? 1 : 0
  
  project      = var.project_id
  display_name = "Slack Notifications"
  type         = "slack"
  
  labels = {
    url = var.slack_webhook_url
  }
  
  user_labels = var.labels
  
  sensitive_labels {
    auth_token = var.slack_auth_token
  }
}

resource "google_monitoring_notification_channel" "pagerduty_channel" {
  count = var.pagerduty_service_key != "" ? 1 : 0
  
  project      = var.project_id
  display_name = "PagerDuty Alerts"
  type         = "pagerduty"
  
  labels = {
    service_key = var.pagerduty_service_key
  }
  
  user_labels = var.labels
}

resource "google_monitoring_notification_channel" "sms_channels" {
  for_each = toset(var.sms_numbers)
  
  project      = var.project_id
  display_name = "SMS - ${each.value}"
  type         = "sms"
  
  labels = {
    number = each.value
  }
  
  user_labels = var.labels
}

# Alert policies for infrastructure monitoring
resource "google_monitoring_alert_policy" "high_cpu_usage" {
  project      = var.project_id
  display_name = "High CPU Usage"
  combiner     = "OR"
  
  conditions {
    display_name = "CPU usage above 80%"
    
    condition_threshold {
      filter          = "resource.type=\"gce_instance\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.8
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = local.critical_notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
  
  documentation {
    content = "CPU usage is consistently high. Check for resource-intensive processes."
  }
}

resource "google_monitoring_alert_policy" "high_memory_usage" {
  project      = var.project_id
  display_name = "High Memory Usage"
  combiner     = "OR"
  
  conditions {
    display_name = "Memory usage above 85%"
    
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/memory/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.85
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = local.critical_notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_alert_policy" "disk_space_low" {
  project      = var.project_id
  display_name = "Low Disk Space"
  combiner     = "OR"
  
  conditions {
    display_name = "Disk usage above 90%"
    
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/disk/utilization\""
      duration        = "600s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.9
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = local.warning_notification_channels
  
  alert_strategy {
    auto_close = "3600s"
  }
}

# Network monitoring alerts
resource "google_monitoring_alert_policy" "network_errors" {
  project      = var.project_id
  display_name = "High Network Error Rate"
  combiner     = "OR"
  
  conditions {
    display_name = "Network error rate above threshold"
    
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/network/received_packets_count\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 1000
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = local.warning_notification_channels
}

# Application monitoring alerts
resource "google_monitoring_alert_policy" "application_errors" {
  project      = var.project_id
  display_name = "High Application Error Rate"
  combiner     = "OR"
  
  conditions {
    display_name = "Error rate above 5%"
    
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_count\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.05
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.labels.service_name"]
      }
    }
  }
  
  notification_channels = local.critical_notification_channels
}

resource "google_monitoring_alert_policy" "response_time_high" {
  project      = var.project_id
  display_name = "High Response Time"
  combiner     = "OR"
  
  conditions {
    display_name = "Response time above 2 seconds"
    
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_latencies\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 2000
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
      }
    }
  }
  
  notification_channels = local.warning_notification_channels
}

# Security monitoring alerts
resource "google_monitoring_alert_policy" "security_findings" {
  project      = var.project_id
  display_name = "High Severity Security Findings"
  combiner     = "OR"
  
  conditions {
    display_name = "Critical security findings detected"
    
    condition_threshold {
      filter          = "resource.type=\"organization\" AND metric.type=\"logging.googleapis.com/user/security_events\""
      duration        = "60s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }
  
  notification_channels = local.security_notification_channels
  
  alert_strategy {
    auto_close = "86400s"  # 24 hours
  }
}

# Cost monitoring alerts
resource "google_monitoring_alert_policy" "budget_exceeded" {
  project      = var.project_id
  display_name = "Budget Exceeded"
  combiner     = "OR"
  
  conditions {
    display_name = "Monthly spend above budget"
    
    condition_threshold {
      filter          = "resource.type=\"billing_account\""
      duration        = "3600s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = var.budget_threshold
      
      aggregations {
        alignment_period   = "3600s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }
  
  notification_channels = local.billing_notification_channels
}

# Escalation procedures
resource "google_monitoring_alert_policy" "critical_system_down" {
  project      = var.project_id
  display_name = "Critical System Down"
  combiner     = "AND"
  
  conditions {
    display_name = "Service unavailable"
    
    condition_threshold {
      filter          = "resource.type=\"uptime_check\" AND metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\""
      duration        = "300s"
      comparison      = "COMPARISON_EQUAL"
      threshold_value = 0
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_FRACTION_TRUE"
      }
    }
  }
  
  notification_channels = concat(
    local.critical_notification_channels,
    var.pagerduty_service_key != "" ? [google_monitoring_notification_channel.pagerduty_channel[0].id] : [],
    local.sms_notification_channels
  )
  
  alert_strategy {
    auto_close = "300s"
  }
  
  documentation {
    content = "CRITICAL: System is completely down. Immediate response required."
  }
}

# Local variables for notification channel groupings
locals {
  email_notification_channels = [
    for channel in google_monitoring_notification_channel.email_channels : channel.id
  ]
  
  sms_notification_channels = [
    for channel in google_monitoring_notification_channel.sms_channels : channel.id
  ]
  
  slack_notification_channels = var.slack_webhook_url != "" ? [
    google_monitoring_notification_channel.slack_channel[0].id
  ] : []
  
  critical_notification_channels = concat(
    local.email_notification_channels,
    local.slack_notification_channels
  )
  
  warning_notification_channels = local.email_notification_channels
  
  security_notification_channels = concat(
    local.critical_notification_channels,
    local.sms_notification_channels
  )
  
  billing_notification_channels = local.email_notification_channels
}

# Monitoring service account
resource "google_service_account" "monitoring_sa" {
  project      = var.project_id
  account_id   = "monitoring-service-account"
  display_name = "Monitoring Service Account"
  description  = "Service account for monitoring operations"
}

resource "google_project_iam_member" "monitoring_sa_roles" {
  for_each = toset([
    "roles/monitoring.editor",
    "roles/logging.viewer",
    "roles/compute.viewer"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.monitoring_sa.email}"
}

# Monitoring configuration backup
resource "google_storage_bucket_object" "monitoring_config_backup" {
  bucket  = var.backup_bucket
  name    = "monitoring/config-backup-${formatdate("YYYY-MM-DD", timestamp())}.json"
  content = jsonencode({
    timestamp = timestamp()
    notification_channels = {
      email     = var.notification_emails
      slack     = var.slack_webhook_url
      pagerduty = var.pagerduty_service_key
      sms       = var.sms_numbers
    }
    alert_policies = {
      infrastructure = ["high_cpu_usage", "high_memory_usage", "disk_space_low"]
      network       = ["network_errors"]
      application   = ["application_errors", "response_time_high"]
      security      = ["security_findings"]
      cost          = ["budget_exceeded"]
      critical      = ["critical_system_down"]
    }
  })
}