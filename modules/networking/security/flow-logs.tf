# BigQuery dataset for VPC Flow Logs with optimized configuration
resource "google_bigquery_dataset" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  
  dataset_id  = "vpc_flow_logs"
  project     = var.project_id
  description = "VPC Flow Logs dataset with partitioning and clustering"
  location    = "US"
  
  default_table_expiration_ms = var.flow_logs_retention_days * 24 * 60 * 60 * 1000
  
  labels = merge(var.labels, {
    purpose = "vpc-flow-logs"
    network = var.network_name
  })
}

# Log sink for VPC Flow Logs with cost optimization filters
resource "google_logging_project_sink" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  
  name        = "${var.network_name}-vpc-flow-logs"
  project     = var.project_id
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/vpc_flow_logs"
  
  # Optimized filter to reduce costs while maintaining security visibility
  filter = var.flow_logs_config.filter_expr != "true" ? var.flow_logs_config.filter_expr : join(" AND ", [
    "resource.type=\"gce_subnetwork\"",
    "log_name=\"projects/${var.project_id}/logs/compute.googleapis.com%2Fvpc_flows\"",
    # Filter out internal health checks and known good traffic to reduce costs
    "NOT (jsonPayload.src_ip=\"169.254.169.254\" OR jsonPayload.dest_ip=\"169.254.169.254\")",
    "NOT (jsonPayload.src_port=\"0\" AND jsonPayload.dest_port=\"0\")"
  ])
  
  unique_writer_identity = true
  
  bigquery_options {
    use_partitioned_tables = true
  }
}

# IAM binding for log sink service account
resource "google_bigquery_dataset_iam_member" "vpc_flow_logs_writer" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  
  dataset_id = google_bigquery_dataset.vpc_flow_logs[0].dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.vpc_flow_logs[0].writer_identity
}

# BigQuery views for common flow log analysis
resource "google_bigquery_table" "top_talkers_view" {
  count = var.enable_vpc_flow_logs && var.create_flow_analysis_views ? 1 : 0
  
  dataset_id = google_bigquery_dataset.vpc_flow_logs[0].dataset_id
  table_id   = "top_talkers"
  project    = var.project_id
  
  view {
    query = <<-EOF
      SELECT
        jsonPayload.src_ip as source_ip,
        jsonPayload.dest_ip as destination_ip,
        COUNT(*) as connection_count,
        SUM(CAST(jsonPayload.bytes_sent AS INT64)) as total_bytes_sent,
        SUM(CAST(jsonPayload.packets_sent AS INT64)) as total_packets_sent
      FROM `${var.project_id}.vpc_flow_logs.compute_googleapis_com_vpc_flows_*`
      WHERE _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
      GROUP BY source_ip, destination_ip
      ORDER BY total_bytes_sent DESC
      LIMIT 100
    EOF
    use_legacy_sql = false
  }
}

resource "google_bigquery_table" "security_events_view" {
  count = var.enable_vpc_flow_logs && var.create_flow_analysis_views ? 1 : 0
  
  dataset_id = google_bigquery_dataset.vpc_flow_logs[0].dataset_id
  table_id   = "security_events"
  project    = var.project_id
  
  view {
    query = <<-EOF
      SELECT
        timestamp,
        jsonPayload.src_ip as source_ip,
        jsonPayload.dest_ip as destination_ip,
        jsonPayload.src_port as source_port,
        jsonPayload.dest_port as destination_port,
        jsonPayload.protocol,
        jsonPayload.action,
        resource.labels.subnetwork_name
      FROM `${var.project_id}.vpc_flow_logs.compute_googleapis_com_vpc_flows_*`
      WHERE _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
        AND (
          jsonPayload.action = "DENY" OR
          jsonPayload.dest_port IN ("22", "3389", "23", "21") OR
          jsonPayload.src_ip NOT LIKE "10.%" AND 
          jsonPayload.src_ip NOT LIKE "172.16.%" AND 
          jsonPayload.src_ip NOT LIKE "192.168.%"
        )
      ORDER BY timestamp DESC
    EOF
    use_legacy_sql = false
  }
}

resource "google_bigquery_table" "bandwidth_analysis_view" {
  count = var.enable_vpc_flow_logs && var.create_flow_analysis_views ? 1 : 0
  
  dataset_id = google_bigquery_dataset.vpc_flow_logs[0].dataset_id
  table_id   = "bandwidth_analysis"
  project    = var.project_id
  
  view {
    query = <<-EOF
      SELECT
        TIMESTAMP_TRUNC(timestamp, HOUR) as hour,
        resource.labels.subnetwork_name,
        SUM(CAST(jsonPayload.bytes_sent AS INT64)) as total_bytes_sent,
        SUM(CAST(jsonPayload.bytes_received AS INT64)) as total_bytes_received,
        COUNT(*) as flow_count
      FROM `${var.project_id}.vpc_flow_logs.compute_googleapis_com_vpc_flows_*`
      WHERE _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
      GROUP BY hour, subnetwork_name
      ORDER BY hour DESC, total_bytes_sent DESC
    EOF
    use_legacy_sql = false
  }
}

# Scheduled queries for anomaly detection
resource "google_bigquery_data_transfer_config" "anomaly_detection" {
  count = var.enable_vpc_flow_logs && var.enable_anomaly_detection ? 1 : 0
  
  display_name   = "VPC Flow Logs Anomaly Detection"
  project        = var.project_id
  location       = "US"
  data_source_id = "scheduled_query"
  
  schedule = "every 1 hours"
  
  destination_dataset_id = google_bigquery_dataset.vpc_flow_logs[0].dataset_id
  
  params = {
    destination_table_name_template = "anomaly_detection_{run_date}"
    write_disposition               = "WRITE_TRUNCATE"
    query = <<-EOF
      WITH hourly_stats AS (
        SELECT
          TIMESTAMP_TRUNC(timestamp, HOUR) as hour,
          jsonPayload.src_ip as source_ip,
          COUNT(*) as connection_count,
          SUM(CAST(jsonPayload.bytes_sent AS INT64)) as bytes_sent
        FROM `${var.project_id}.vpc_flow_logs.compute_googleapis_com_vpc_flows_*`
        WHERE _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
        GROUP BY hour, source_ip
      ),
      baseline AS (
        SELECT
          source_ip,
          AVG(connection_count) as avg_connections,
          STDDEV(connection_count) as stddev_connections,
          AVG(bytes_sent) as avg_bytes,
          STDDEV(bytes_sent) as stddev_bytes
        FROM hourly_stats
        WHERE hour < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
        GROUP BY source_ip
      )
      SELECT
        h.hour,
        h.source_ip,
        h.connection_count,
        h.bytes_sent,
        b.avg_connections,
        b.avg_bytes,
        CASE 
          WHEN h.connection_count > b.avg_connections + (3 * b.stddev_connections) THEN 'HIGH_CONNECTION_ANOMALY'
          WHEN h.bytes_sent > b.avg_bytes + (3 * b.stddev_bytes) THEN 'HIGH_BANDWIDTH_ANOMALY'
          ELSE 'NORMAL'
        END as anomaly_type
      FROM hourly_stats h
      JOIN baseline b ON h.source_ip = b.source_ip
      WHERE h.hour >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
        AND (
          h.connection_count > b.avg_connections + (3 * b.stddev_connections) OR
          h.bytes_sent > b.avg_bytes + (3 * b.stddev_bytes)
        )
    EOF
  }
}

# Monitoring dashboard for VPC Flow Logs
resource "google_monitoring_dashboard" "vpc_flow_dashboard" {
  count = var.enable_vpc_flow_logs && var.create_flow_dashboards ? 1 : 0
  
  dashboard_json = jsonencode({
    displayName = "VPC Flow Logs Network Insights"
    mosaicLayout = {
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Top Source IPs by Bandwidth"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_subnetwork\" AND metric.type=\"logging.googleapis.com/user/vpc_flow_bytes\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["metric.label.src_ip"]
                    }
                  }
                }
              }]
            }
          }
        },
        {
          width  = 6
          height = 4
          widget = {
            title = "Denied Connections"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_subnetwork\" AND metric.type=\"logging.googleapis.com/user/vpc_flow_denied\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          width  = 12
          height = 4
          widget = {
            title = "Network Traffic Heatmap"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_subnetwork\" AND metric.type=\"logging.googleapis.com/user/vpc_flow_connections\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["resource.label.subnetwork_name"]
                    }
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
  
  project = var.project_id
}

# Alert policies for flow log anomalies
resource "google_monitoring_alert_policy" "flow_anomaly_alerts" {
  count = var.enable_vpc_flow_logs && var.enable_flow_alerts ? 1 : 0
  
  display_name = "VPC Flow Log Anomalies"
  project      = var.project_id
  
  conditions {
    display_name = "High Denied Connection Rate"
    
    condition_threshold {
      filter          = "resource.type=\"gce_subnetwork\" AND metric.type=\"logging.googleapis.com/user/vpc_flow_denied\""
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = var.denied_connections_threshold
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = var.flow_notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# Cost optimization: Lifecycle policy for flow logs
resource "google_storage_bucket" "flow_logs_archive" {
  count = var.enable_vpc_flow_logs && var.enable_flow_archive ? 1 : 0
  
  name     = "${var.project_id}-vpc-flow-logs-archive"
  project  = var.project_id
  location = "US"
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
  
  labels = var.labels
}