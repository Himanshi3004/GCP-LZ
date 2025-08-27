# Enhanced Cloud Trace Configuration

# Enable Cloud Trace API
resource "google_project_service" "trace" {
  count   = var.enable_trace ? 1 : 0
  project = var.project_id
  service = "cloudtrace.googleapis.com"
  disable_on_destroy = false
}

# Trace sampling configuration
resource "google_project_service" "trace_agent" {
  count   = var.enable_trace ? 1 : 0
  project = var.project_id
  service = "cloudtrace.googleapis.com"
  disable_on_destroy = false
}

# Service account for trace collection
resource "google_service_account" "trace_agent" {
  count        = var.enable_trace ? 1 : 0
  project      = var.project_id
  account_id   = "trace-agent-sa"
  display_name = "Cloud Trace Agent Service Account"
  description  = "Service account for Cloud Trace agent operations"
}

# IAM binding for trace agent
resource "google_project_iam_member" "trace_agent_role" {
  count   = var.enable_trace ? 1 : 0
  project = var.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.trace_agent[0].email}"
}

# Trace latency alert policy
resource "google_monitoring_alert_policy" "trace_latency_high" {
  count        = var.enable_trace ? 1 : 0
  display_name = "High Application Latency (Trace)"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Application latency threshold exceeded"
    
    condition_threshold {
      filter = join(" AND ", [
        "metric.type=\"cloudtrace.googleapis.com/trace/latency\"",
        "resource.type=\"global\""
      ])
      comparison      = "COMPARISON_GT"
      threshold_value = var.trace_latency_threshold_ms
      duration        = "300s"
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "1800s"
    
    notification_rate_limit {
      period = "300s"
    }
  }
  
  documentation {
    content = "Application latency has exceeded the threshold. Check trace data for performance bottlenecks."
    mime_type = "text/markdown"
  }
}

# Trace error rate alert
resource "google_monitoring_alert_policy" "trace_error_rate" {
  count        = var.enable_trace ? 1 : 0
  display_name = "High Error Rate (Trace)"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Error rate threshold exceeded"
    
    condition_threshold {
      filter = join(" AND ", [
        "metric.type=\"cloudtrace.googleapis.com/trace/error_rate\"",
        "resource.type=\"global\""
      ])
      comparison      = "COMPARISON_GT"
      threshold_value = var.trace_error_rate_threshold
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
}

# Distributed tracing configuration for GKE
resource "google_monitoring_alert_policy" "distributed_trace_anomaly" {
  count        = var.enable_trace && var.enable_distributed_tracing ? 1 : 0
  display_name = "Distributed Trace Anomaly"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Unusual trace patterns detected"
    
    condition_threshold {
      filter = join(" AND ", [
        "metric.type=\"cloudtrace.googleapis.com/trace/span_count\"",
        "resource.type=\"k8s_container\""
      ])
      comparison      = "COMPARISON_GT"
      threshold_value = var.trace_span_threshold
      duration        = "600s"
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.label.container_name"]
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "3600s"
  }
}

# Trace sampling policy for cost control
resource "google_monitoring_alert_policy" "trace_sampling_rate" {
  count        = var.enable_trace ? 1 : 0
  display_name = "Trace Sampling Rate Monitor"
  project      = var.project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Trace sampling rate too low"
    
    condition_threshold {
      filter = join(" AND ", [
        "metric.type=\"cloudtrace.googleapis.com/trace/sampling_rate\"",
        "resource.type=\"global\""
      ])
      comparison      = "COMPARISON_LT"
      threshold_value = var.min_trace_sampling_rate
      duration        = "900s"
      
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
    content = "Trace sampling rate is too low. Consider increasing sampling for better observability."
    mime_type = "text/markdown"
  }
}

# Trace dashboard
resource "google_monitoring_dashboard" "trace_analysis" {
  count          = var.enable_trace ? 1 : 0
  project        = var.project_id
  dashboard_json = jsonencode({
    displayName = "Trace Analysis Dashboard"
    mosaicLayout = {
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Request Latency Distribution"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"cloudtrace.googleapis.com/trace/latency\""
                    aggregation = {
                      alignmentPeriod     = "300s"
                      perSeriesAligner    = "ALIGN_DELTA"
                      crossSeriesReducer  = "REDUCE_PERCENTILE_95"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Latency (ms)"
                scale = "LINEAR"
              }
              thresholds = [{
                value = var.trace_latency_threshold_ms
                color = "RED"
                direction = "ABOVE"
              }]
            }
          }
        },
        {
          width  = 6
          height = 4
          xPos   = 6
          widget = {
            title = "Trace Error Rate"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"cloudtrace.googleapis.com/trace/error_rate\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_RATE"
                    }
                  }
                }
                plotType = "STACKED_AREA"
              }]
              yAxis = {
                label = "Error Rate"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          width  = 12
          height = 4
          yPos   = 4
          widget = {
            title = "Distributed Trace Spans"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"cloudtrace.googleapis.com/trace/span_count\""
                    aggregation = {
                      alignmentPeriod     = "300s"
                      perSeriesAligner    = "ALIGN_RATE"
                      crossSeriesReducer  = "REDUCE_SUM"
                      groupByFields       = ["resource.label.service_name"]
                    }
                  }
                }
                plotType = "STACKED_BAR"
              }]
              yAxis = {
                label = "Spans/sec"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          width  = 6
          height = 3
          yPos   = 8
          widget = {
            title = "Top Slowest Services"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"cloudtrace.googleapis.com/trace/latency\""
                  aggregation = {
                    alignmentPeriod     = "3600s"
                    perSeriesAligner    = "ALIGN_MEAN"
                    crossSeriesReducer  = "REDUCE_PERCENTILE_99"
                    groupByFields       = ["resource.label.service_name"]
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
          width  = 6
          height = 3
          xPos   = 6
          yPos   = 8
          widget = {
            title = "Trace Sampling Rate"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"cloudtrace.googleapis.com/trace/sampling_rate\""
                  aggregation = {
                    alignmentPeriod    = "3600s"
                    perSeriesAligner   = "ALIGN_MEAN"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_LINE"
              }
              gaugeView = {
                lowerBound = 0.0
                upperBound = 1.0
              }
            }
          }
        }
      ]
    }
  })
}

# BigQuery export for trace analysis
resource "google_bigquery_dataset" "trace_export" {
  count       = var.enable_trace && var.enable_trace_export ? 1 : 0
  dataset_id  = "trace_analysis"
  project     = var.project_id
  location    = var.region
  description = "Dataset for Cloud Trace analysis"
  
  default_table_expiration_ms = var.trace_retention_days * 24 * 60 * 60 * 1000
  
  labels = var.labels
}

# Scheduled query for trace analysis
resource "google_bigquery_data_transfer_config" "trace_analysis" {
  count                  = var.enable_trace && var.enable_trace_export ? 1 : 0
  display_name           = "Trace Performance Analysis"
  project                = var.project_id
  location               = var.region
  data_source_id         = "scheduled_query"
  schedule               = "every 1 hours"
  destination_dataset_id = google_bigquery_dataset.trace_export[0].dataset_id
  
  params = {
    destination_table_name_template = "trace_performance_hourly_{run_date}_{run_time}"
    write_disposition               = "WRITE_TRUNCATE"
    query = <<-EOT
      SELECT
        TIMESTAMP_TRUNC(timestamp, HOUR) as hour,
        service_name,
        AVG(latency_ms) as avg_latency,
        APPROX_QUANTILES(latency_ms, 100)[OFFSET(95)] as p95_latency,
        APPROX_QUANTILES(latency_ms, 100)[OFFSET(99)] as p99_latency,
        COUNT(*) as request_count,
        COUNTIF(error_code IS NOT NULL) as error_count,
        SAFE_DIVIDE(COUNTIF(error_code IS NOT NULL), COUNT(*)) as error_rate
      FROM `${var.project_id}.cloudtrace_googleapis_com.traces`
      WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
      GROUP BY hour, service_name
      ORDER BY hour DESC, avg_latency DESC
    EOT
  }
  
  depends_on = [google_bigquery_dataset.trace_export]
}