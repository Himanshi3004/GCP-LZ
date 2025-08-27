resource "google_logging_project_sink" "data_access_sink" {
  name        = "data-access-audit-sink"
  project     = var.project_id
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/audit_logs"
  
  filter = <<-EOT
    protoPayload.serviceName="bigquery.googleapis.com"
    OR protoPayload.serviceName="storage.googleapis.com"
    OR protoPayload.serviceName="datacatalog.googleapis.com"
  EOT
  
  unique_writer_identity = true
}

resource "google_bigquery_dataset" "audit_logs" {
  dataset_id  = "audit_logs"
  project     = var.project_id
  location    = var.region
  description = "Dataset for data access audit logs"
  
  default_table_expiration_ms = 7776000000 # 90 days
  
  labels = var.labels
}

resource "google_bigquery_dataset_iam_member" "sink_writer" {
  dataset_id = google_bigquery_dataset.audit_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.data_access_sink.writer_identity
  project    = var.project_id
}

resource "google_logging_metric" "data_access_metric" {
  name   = "data_access_count"
  project = var.project_id
  filter = google_logging_project_sink.data_access_sink.filter
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    display_name = "Data Access Count"
  }
  
  label_extractors = {
    "user"    = "EXTRACT(protoPayload.authenticationInfo.principalEmail)"
    "service" = "EXTRACT(protoPayload.serviceName)"
    "method"  = "EXTRACT(protoPayload.methodName)"
  }
}

resource "google_monitoring_alert_policy" "unusual_data_access" {
  display_name = "Unusual Data Access Pattern"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "High data access rate"
    
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/data_access_count\""
      comparison      = "COMPARISON_GT"
      threshold_value = 100
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = []
  
  alert_strategy {
    auto_close = "86400s"
  }
}