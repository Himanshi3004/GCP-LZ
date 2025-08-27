# Enhanced Monitoring Infrastructure and Alert Policies

# Notification channels
resource "google_monitoring_notification_channel" "email_security" {
  display_name = "Security Team Email"
  project      = var.project_id
  type         = "email"
  
  labels = {
    email_address = var.security_email
  }
  
  enabled = true
}

resource "google_monitoring_notification_channel" "email_ops" {
  display_name = "Operations Team Email"
  project      = var.project_id
  type         = "email"
  
  labels = {
    email_address = var.operations_email
  }
  
  enabled = true
}

resource "google_monitoring_notification_channel" "slack_security" {
  count        = var.slack_webhook_url != "" ? 1 : 0
  display_name = "Security Slack Channel"
  project      = var.project_id
  type         = "slack"
  
  labels = {
    url = var.slack_webhook_url
  }
  
  enabled = true
}

resource "google_monitoring_notification_channel" "pagerduty" {
  count        = var.pagerduty_key != "" ? 1 : 0
  display_name = "PagerDuty Critical Alerts"
  project      = var.project_id
  type         = "pagerduty"
  
  labels = {
    service_key = var.pagerduty_key
  }
  
  enabled = true
}

# Security Alert Policies
resource "google_monitoring_alert_policy" "failed_login_attempts" {
  display_name = "High Failed Login Attempts"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Failed login threshold exceeded"
    
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/failed_login_attempts\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.failed_login_threshold
      duration        = "300s"
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["metric.label.user"]
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_security.name,
    var.slack_webhook_url != "" ? google_monitoring_notification_channel.slack_security[0].name : null
  ]
  
  alert_strategy {
    auto_close = "1800s"
    
    notification_rate_limit {
      period = "300s"
    }
  }
  
  documentation {
    content = "High number of failed login attempts detected. Investigate potential brute force attack."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "privilege_escalation" {
  display_name = "Privilege Escalation Detected"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Privilege escalation attempt"
    
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/privilege_escalation_attempts\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "60s"
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_security.name,
    var.pagerduty_key != "" ? google_monitoring_notification_channel.pagerduty[0].name : null
  ]
  
  alert_strategy {
    auto_close = "3600s"
  }
  
  documentation {
    content = "Privilege escalation attempt detected. Immediate investigation required."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "firewall_violations" {
  display_name = "Suspicious Firewall Rule Changes"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Suspicious firewall rule changes"
    
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/firewall_rule_violations\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "60s"
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_security.name,
    google_monitoring_notification_channel.email_ops.name
  ]
  
  alert_strategy {
    auto_close = "1800s"
  }
  
  documentation {
    content = "Suspicious firewall rule changes detected. Review changes for security compliance."
    mime_type = "text/markdown"
  }
}

# Network Security Alerts
resource "google_monitoring_alert_policy" "vpc_flow_anomalies" {
  display_name = "VPC Flow Anomalies"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Unusual network traffic patterns"
    
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/vpc_flow_anomalies\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.vpc_flow_anomaly_threshold
      duration        = "600s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_security.name
  ]
  
  alert_strategy {
    auto_close = "3600s"
  }
}

resource "google_monitoring_alert_policy" "data_exfiltration" {
  display_name = "Potential Data Exfiltration"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Suspicious data access patterns"
    
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/data_exfiltration_indicators\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.data_exfiltration_threshold
      duration        = "300s"
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_security.name,
    var.pagerduty_key != "" ? google_monitoring_notification_channel.pagerduty[0].name : null
  ]
  
  alert_strategy {
    auto_close = "7200s"
  }
  
  documentation {
    content = "Potential data exfiltration detected. Investigate data access patterns immediately."
    mime_type = "text/markdown"
  }
}

# Application Performance Alerts
resource "google_monitoring_alert_policy" "application_errors" {
  display_name = "High Application Error Rate"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Application error rate exceeded"
    
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/application_errors\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.application_error_threshold
      duration        = "300s"
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["metric.label.service"]
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_ops.name
  ]
  
  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_alert_policy" "high_latency" {
  display_name = "High Request Latency"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Request latency threshold exceeded"
    
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/high_latency_requests\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.high_latency_threshold
      duration        = "600s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_ops.name
  ]
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# Cost and Resource Alerts
resource "google_monitoring_alert_policy" "expensive_operations" {
  display_name = "Expensive Operations Alert"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "High-cost operations detected"
    
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/expensive_operations\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.expensive_operations_threshold
      duration        = "300s"
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_ops.name
  ]
  
  alert_strategy {
    auto_close = "3600s"
  }
  
  documentation {
    content = "High-cost operations detected. Review resource usage and optimize if necessary."
    mime_type = "text/markdown"
  }
}

# Compliance Alerts
resource "google_monitoring_alert_policy" "policy_violations" {
  display_name = "Organization Policy Violations"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Policy violation detected"
    
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/policy_violations\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "60s"
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_security.name,
    google_monitoring_notification_channel.email_ops.name
  ]
  
  alert_strategy {
    auto_close = "3600s"
  }
}

# Infrastructure Health Alerts
resource "google_monitoring_alert_policy" "compute_instance_down" {
  display_name = "Compute Instance Down"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Instance is down"
    
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/up\""
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_ops.name
  ]
  
  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_alert_policy" "disk_utilization_high" {
  display_name = "High Disk Utilization"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Disk utilization above threshold"
    
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/disk/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.disk_utilization_threshold
      duration        = "600s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_ops.name
  ]
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# Uptime checks for critical services
resource "google_monitoring_uptime_check_config" "critical_service_check" {
  for_each     = var.uptime_check_urls
  display_name = "Uptime Check - ${each.key}"
  project      = var.project_id
  timeout      = "10s"
  period       = "300s"
  
  http_check {
    path         = each.value.path
    port         = each.value.port
    use_ssl      = each.value.use_ssl
    validate_ssl = each.value.validate_ssl
  }
  
  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = each.value.host
    }
  }
  
  content_matchers {
    content = each.value.expected_content
    matcher = "CONTAINS_STRING"
  }
}

# Alert policy for uptime check failures
resource "google_monitoring_alert_policy" "uptime_check_failure" {
  for_each     = var.uptime_check_urls
  display_name = "Uptime Check Failure - ${each.key}"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Uptime check failure"
    
    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.label.check_id=\"${google_monitoring_uptime_check_config.critical_service_check[each.key].uptime_check_id}\""
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_FRACTION_TRUE"
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_ops.name,
    var.pagerduty_key != "" ? google_monitoring_notification_channel.pagerduty[0].name : null
  ]
  
  alert_strategy {
    auto_close = "1800s"
  }
}