# Organization policies for compliance
resource "google_org_policy_policy" "policies" {
  for_each = toset(var.policy_frameworks)
  
  name   = "projects/${var.project_id}/policies/${each.value}-compliance"
  parent = "projects/${var.project_id}"
  
  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Security policies for network protection
resource "google_compute_security_policy" "policies" {
  for_each = {
    "owasp-top-10" = {
      description = "OWASP Top 10 protection"
      rules = [
        {
          priority = 1000
          action   = "deny(403)"
          match = {
            expr = {
              expression = "origin.region_code == 'CN'"
            }
          }
        }
      ]
    }
    "ddos-protection" = {
      description = "DDoS protection policy"
      rules = [
        {
          priority = 2000
          action   = "rate_based_ban"
          match = {
            expr = {
              expression = "true"
            }
          }
          rate_limit_options = {
            conform_action = "allow"
            exceed_action  = "deny(429)"
            enforce_on_key = "IP"
            rate_limit_threshold = {
              count        = 100
              interval_sec = 60
            }
          }
        }
      ]
    }
  }
  
  name        = "${each.key}-policy"
  project     = var.project_id
  description = each.value.description
  
  dynamic "rule" {
    for_each = each.value.rules
    content {
      priority = rule.value.priority
      action   = rule.value.action
      
      match {
        expr {
          expression = rule.value.match.expr.expression
        }
      }
      
      dynamic "rate_limit_options" {
        for_each = lookup(rule.value, "rate_limit_options", null) != null ? [rule.value.rate_limit_options] : []
        content {
          conform_action = rate_limit_options.value.conform_action
          exceed_action  = rate_limit_options.value.exceed_action
          enforce_on_key = rate_limit_options.value.enforce_on_key
          
          rate_limit_threshold {
            count        = rate_limit_options.value.rate_limit_threshold.count
            interval_sec = rate_limit_options.value.rate_limit_threshold.interval_sec
          }
        }
      }
    }
  }
}

# Monitoring alert policies for compliance violations
resource "google_monitoring_alert_policy" "compliance_alerts" {
  for_each = {
    "policy-violation" = {
      display_name = "Policy Violation Alert"
      filter       = "resource.type=\"gce_instance\""
      comparison   = "COMPARISON_GREATER_THAN"
      threshold    = 0
    }
    "security-finding" = {
      display_name = "Security Finding Alert"
      filter       = "resource.type=\"gcs_bucket\""
      comparison   = "COMPARISON_GREATER_THAN"
      threshold    = 0
    }
  }
  
  display_name = each.value.display_name
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = each.value.display_name
    
    condition_threshold {
      filter          = each.value.filter
      comparison      = each.value.comparison
      threshold_value = each.value.threshold
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
  
  enabled = true
}