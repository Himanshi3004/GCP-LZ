# Enhanced Synthetic Monitoring with Uptime Checks

# HTTP/HTTPS uptime checks for critical services
resource "google_monitoring_uptime_check_config" "http_checks" {
  for_each     = var.enable_uptime_checks ? var.http_uptime_checks : {}
  display_name = "HTTP Check - ${each.key}"
  project      = var.project_id
  timeout      = each.value.timeout
  period       = each.value.period
  
  http_check {
    path           = each.value.path
    port           = each.value.port
    use_ssl        = each.value.use_ssl
    validate_ssl   = each.value.validate_ssl
    request_method = each.value.request_method
    
    dynamic "headers" {
      for_each = each.value.headers
      content {
        key   = headers.key
        value = headers.value
      }
    }
    
    body = each.value.body
    content_type = each.value.content_type
    
    dynamic "auth_info" {
      for_each = each.value.auth_info != null ? [each.value.auth_info] : []
      content {
        username = auth_info.value.username
        password = auth_info.value.password
      }
    }
  }
  
  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = each.value.host
    }
  }
  
  dynamic "content_matchers" {
    for_each = each.value.content_matchers
    content {
      content = content_matchers.value.content
      matcher = content_matchers.value.matcher
    }
  }
  
  selected_regions = each.value.regions
  
  checker_type = each.value.checker_type
}

# TCP uptime checks for non-HTTP services
resource "google_monitoring_uptime_check_config" "tcp_checks" {
  for_each     = var.enable_uptime_checks ? var.tcp_uptime_checks : {}
  display_name = "TCP Check - ${each.key}"
  project      = var.project_id
  timeout      = each.value.timeout
  period       = each.value.period
  
  tcp_check {
    port = each.value.port
  }
  
  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = each.value.host
    }
  }
  
  selected_regions = each.value.regions
  checker_type     = each.value.checker_type
}

# User journey monitoring (multi-step checks)
resource "google_monitoring_uptime_check_config" "user_journey_checks" {
  for_each     = var.enable_uptime_checks ? var.user_journey_checks : {}
  display_name = "User Journey - ${each.key}"
  project      = var.project_id
  timeout      = each.value.timeout
  period       = each.value.period
  
  http_check {
    path         = each.value.initial_path
    port         = each.value.port
    use_ssl      = each.value.use_ssl
    validate_ssl = each.value.validate_ssl
    
    dynamic "headers" {
      for_each = each.value.headers
      content {
        key   = headers.key
        value = headers.value
      }
    }
  }
  
  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = each.value.host
    }
  }
  
  dynamic "content_matchers" {
    for_each = each.value.content_matchers
    content {
      content = content_matchers.value.content
      matcher = content_matchers.value.matcher
    }
  }
  
  selected_regions = each.value.regions
  checker_type     = "STATIC_IP_CHECKERS"
}

# Global uptime monitoring for CDN endpoints
resource "google_monitoring_uptime_check_config" "global_checks" {
  for_each     = var.enable_uptime_checks ? var.global_uptime_checks : {}
  display_name = "Global Check - ${each.key}"
  project      = var.project_id
  timeout      = each.value.timeout
  period       = each.value.period
  
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
  
  # Global monitoring from all regions
  selected_regions = [
    "USA",
    "EUROPE", 
    "SOUTH_AMERICA",
    "ASIA_PACIFIC"
  ]
  
  checker_type = "STATIC_IP_CHECKERS"
}

# Alert policies for uptime check failures
resource "google_monitoring_alert_policy" "http_uptime_failure" {
  for_each     = var.enable_uptime_checks ? var.http_uptime_checks : {}
  display_name = "HTTP Uptime Failure - ${each.key}"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "HTTP uptime check failed"
    
    condition_threshold {
      filter = join(" AND ", [
        "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\"",
        "resource.label.check_id=\"${google_monitoring_uptime_check_config.http_checks[each.key].uptime_check_id}\""
      ])
      comparison      = "COMPARISON_LT"
      threshold_value = each.value.failure_threshold
      duration        = each.value.failure_duration
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_FRACTION_TRUE"
        cross_series_reducer = "REDUCE_MEAN"
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = each.value.auto_close_duration
    
    notification_rate_limit {
      period = "300s"
    }
  }
  
  documentation {
    content = "HTTP uptime check for ${each.key} has failed. Service may be unavailable."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "tcp_uptime_failure" {
  for_each     = var.enable_uptime_checks ? var.tcp_uptime_checks : {}
  display_name = "TCP Uptime Failure - ${each.key}"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "TCP uptime check failed"
    
    condition_threshold {
      filter = join(" AND ", [
        "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\"",
        "resource.label.check_id=\"${google_monitoring_uptime_check_config.tcp_checks[each.key].uptime_check_id}\""
      ])
      comparison      = "COMPARISON_LT"
      threshold_value = each.value.failure_threshold
      duration        = each.value.failure_duration
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_FRACTION_TRUE"
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = each.value.auto_close_duration
  }
}

resource "google_monitoring_alert_policy" "user_journey_failure" {
  for_each     = var.enable_uptime_checks ? var.user_journey_checks : {}
  display_name = "User Journey Failure - ${each.key}"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "User journey check failed"
    
    condition_threshold {
      filter = join(" AND ", [
        "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\"",
        "resource.label.check_id=\"${google_monitoring_uptime_check_config.user_journey_checks[each.key].uptime_check_id}\""
      ])
      comparison      = "COMPARISON_LT"
      threshold_value = each.value.failure_threshold
      duration        = each.value.failure_duration
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_FRACTION_TRUE"
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = each.value.auto_close_duration
  }
  
  documentation {
    content = "User journey ${each.key} has failed. Critical user flow may be broken."
    mime_type = "text/markdown"
  }
}

# Performance baseline alerts
resource "google_monitoring_alert_policy" "uptime_latency_degradation" {
  for_each     = var.enable_uptime_checks ? var.http_uptime_checks : {}
  display_name = "Uptime Latency Degradation - ${each.key}"
  project      = var.project_id
  combiner     = "OR"
  enabled      = each.value.enable_latency_alerts
  
  conditions {
    display_name = "Response time degradation"
    
    condition_threshold {
      filter = join(" AND ", [
        "metric.type=\"monitoring.googleapis.com/uptime_check/request_latency\"",
        "resource.label.check_id=\"${google_monitoring_uptime_check_config.http_checks[each.key].uptime_check_id}\""
      ])
      comparison      = "COMPARISON_GT"
      threshold_value = each.value.latency_threshold_ms
      duration        = "600s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "3600s"
  }
  
  documentation {
    content = "Response time for ${each.key} has degraded beyond acceptable levels."
    mime_type = "text/markdown"
  }
}

# Availability reporting dashboard
resource "google_monitoring_dashboard" "uptime_overview" {
  count          = var.enable_uptime_checks ? 1 : 0
  project        = var.project_id
  dashboard_json = jsonencode({
    displayName = "Uptime and Availability Overview"
    mosaicLayout = {
      tiles = [
        {
          width  = 12
          height = 4
          widget = {
            title = "Service Availability (24h)"
            xyChart = {
              dataSets = [
                for check_name, check_config in var.http_uptime_checks : {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = join(" AND ", [
                        "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\"",
                        "resource.label.check_id=\"${google_monitoring_uptime_check_config.http_checks[check_name].uptime_check_id}\""
                      ])
                      aggregation = {
                        alignmentPeriod    = "300s"
                        perSeriesAligner   = "ALIGN_FRACTION_TRUE"
                      }
                    }
                  }
                  plotType = "LINE"
                }
              ]
              yAxis = {
                label = "Availability %"
                scale = "LINEAR"
              }
              thresholds = [{
                value = 0.99
                color = "RED"
                direction = "BELOW"
              }]
            }
          }
        },
        {
          width  = 6
          height = 4
          yPos   = 4
          widget = {
            title = "Response Time Distribution"
            xyChart = {
              dataSets = [
                for check_name, check_config in var.http_uptime_checks : {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = join(" AND ", [
                        "metric.type=\"monitoring.googleapis.com/uptime_check/request_latency\"",
                        "resource.label.check_id=\"${google_monitoring_uptime_check_config.http_checks[check_name].uptime_check_id}\""
                      ])
                      aggregation = {
                        alignmentPeriod    = "300s"
                        perSeriesAligner   = "ALIGN_MEAN"
                      }
                    }
                  }
                  plotType = "LINE"
                }
              ]
              yAxis = {
                label = "Latency (ms)"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          width  = 6
          height = 4
          xPos   = 6
          yPos   = 4
          widget = {
            title = "Global Availability Heatmap"
            xyChart = {
              dataSets = [
                for check_name, check_config in var.global_uptime_checks : {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = join(" AND ", [
                        "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\"",
                        "resource.label.check_id=\"${google_monitoring_uptime_check_config.global_checks[check_name].uptime_check_id}\""
                      ])
                      aggregation = {
                        alignmentPeriod     = "300s"
                        perSeriesAligner    = "ALIGN_FRACTION_TRUE"
                        crossSeriesReducer  = "REDUCE_MEAN"
                        groupByFields       = ["metric.label.checker_location"]
                      }
                    }
                  }
                  plotType = "STACKED_AREA"
                }
              ]
              yAxis = {
                label = "Availability by Region"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          width  = 4
          height = 3
          yPos   = 8
          widget = {
            title = "Overall SLA"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\""
                  aggregation = {
                    alignmentPeriod     = "86400s"
                    perSeriesAligner    = "ALIGN_FRACTION_TRUE"
                    crossSeriesReducer  = "REDUCE_MEAN"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_LINE"
              }
              gaugeView = {
                lowerBound = 0.99
                upperBound = 1.0
              }
            }
          }
        },
        {
          width  = 4
          height = 3
          xPos   = 4
          yPos   = 8
          widget = {
            title = "Failed Checks (24h)"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\""
                  aggregation = {
                    alignmentPeriod     = "86400s"
                    perSeriesAligner    = "ALIGN_FRACTION_TRUE"
                    crossSeriesReducer  = "REDUCE_COUNT_FALSE"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_BAR"
              }
            }
          }
        },
        {
          width  = 4
          height = 3
          xPos   = 8
          yPos   = 8
          widget = {
            title = "Average Response Time"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"monitoring.googleapis.com/uptime_check/request_latency\""
                  aggregation = {
                    alignmentPeriod     = "86400s"
                    perSeriesAligner    = "ALIGN_MEAN"
                    crossSeriesReducer  = "REDUCE_MEAN"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_LINE"
              }
            }
          }
        }
      ]
    }
  })
}