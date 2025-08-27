# Cloud Armor Security Policies with comprehensive protection
resource "google_compute_security_policy" "policies" {
  for_each = var.enable_cloud_armor ? { for policy in var.cloud_armor_policies : policy.name => policy } : {}
  
  name        = each.value.name
  project     = var.project_id
  description = each.value.description
  type        = "CLOUD_ARMOR"
  
  # Adaptive protection configuration
  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable          = true
      rule_visibility = "STANDARD"
    }
  }
  
  # Advanced DDoS protection
  advanced_options_config {
    json_parsing = "STANDARD"
    log_level    = "VERBOSE"
    user_ip_request_headers = [
      "X-Forwarded-For",
      "X-Real-IP"
    ]
  }
  
  # Default rule - deny all (lowest priority)
  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default deny rule"
  }
  
  # Allow trusted IP ranges
  rule {
    action   = "allow"
    priority = "100"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = lookup(each.value, "trusted_ip_ranges", [])
      }
    }
    description = "Allow trusted IP ranges"
  }
  
  # Geographic restrictions
  dynamic "rule" {
    for_each = lookup(each.value, "geo_restrictions", [])
    content {
      action   = rule.value.action
      priority = rule.value.priority
      match {
        expr {
          expression = "origin.region_code == '${rule.value.country_code}'"
        }
      }
      description = "Geographic restriction for ${rule.value.country_code}"
    }
  }
  
  # Rate limiting rules with different thresholds
  rule {
    action   = "rate_based_ban"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = lookup(each.value, "rate_limit_requests", 100)
        interval_sec = lookup(each.value, "rate_limit_interval", 60)
      }
      ban_duration_sec = lookup(each.value, "ban_duration", 600)
    }
    description = "Rate limiting rule"
  }
  
  # Advanced rate limiting for API endpoints
  rule {
    action   = "rate_based_ban"
    priority = "1001"
    match {
      expr {
        expression = "request.path.matches('/api/.*')"
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = 50
        interval_sec = 60
      }
      ban_duration_sec = 300
    }
    description = "API endpoint rate limiting"
  }
  
  # OWASP Top 10 protection rules
  rule {
    action   = "deny(403)"
    priority = "2000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }
    description = "XSS protection"
  }
  
  rule {
    action   = "deny(403)"
    priority = "2001"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-stable')"
      }
    }
    description = "SQL injection protection"
  }
  
  rule {
    action   = "deny(403)"
    priority = "2002"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('lfi-stable')"
      }
    }
    description = "Local file inclusion protection"
  }
  
  rule {
    action   = "deny(403)"
    priority = "2003"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('rfi-stable')"
      }
    }
    description = "Remote file inclusion protection"
  }
  
  rule {
    action   = "deny(403)"
    priority = "2004"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('scannerdetection-stable')"
      }
    }
    description = "Scanner detection protection"
  }
  
  rule {
    action   = "deny(403)"
    priority = "2005"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('protocolattack-stable')"
      }
    }
    description = "Protocol attack protection"
  }
  
  rule {
    action   = "deny(403)"
    priority = "2006"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sessionfixation-stable')"
      }
    }
    description = "Session fixation protection"
  }
  
  # Custom application-specific rules
  dynamic "rule" {
    for_each = each.value.rules
    content {
      action      = rule.value.action
      priority    = rule.value.priority
      description = rule.value.description
      
      match {
        versioned_expr = lookup(rule.value.match, "versioned_expr", null)
        
        dynamic "config" {
          for_each = lookup(rule.value.match, "config", null) != null ? [rule.value.match.config] : []
          content {
            src_ip_ranges = config.value.src_ip_ranges
          }
        }
        
        dynamic "expr" {
          for_each = lookup(rule.value.match, "expr", null) != null ? [rule.value.match.expr] : []
          content {
            expression = expr.value.expression
          }
        }
      }
      
      # Rate limiting for specific rules
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
          
          ban_duration_sec = lookup(rate_limit_options.value, "ban_duration_sec", 600)
        }
      }
    }
  }
}

# Cloud Armor edge security policy for CDN
resource "google_compute_security_policy" "edge_policy" {
  count = var.enable_cloud_armor && var.enable_edge_security ? 1 : 0
  
  name        = "${var.network_name}-edge-security"
  project     = var.project_id
  description = "Edge security policy for CDN"
  type        = "CLOUD_ARMOR_EDGE"
  
  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Allow all traffic at edge"
  }
  
  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default deny rule"
  }
}

# Security policy attachment to backend services
resource "google_compute_backend_service" "protected_backend" {
  for_each = var.protected_backend_services
  
  name        = each.value.name
  project     = var.project_id
  description = each.value.description
  
  security_policy = google_compute_security_policy.policies[each.value.security_policy].id
  
  backend {
    group = each.value.backend_group
  }
  
  health_checks = each.value.health_checks
}

# Monitoring and alerting for Cloud Armor
resource "google_monitoring_alert_policy" "cloud_armor_alerts" {
  count = var.enable_cloud_armor && var.enable_armor_monitoring ? 1 : 0
  
  display_name = "Cloud Armor Security Alerts"
  project      = var.project_id
  
  conditions {
    display_name = "High number of blocked requests"
    
    condition_threshold {
      filter          = "resource.type=\"gce_backend_service\" AND metric.type=\"loadbalancing.googleapis.com/https/request_count\""
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 1000
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = var.armor_notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}