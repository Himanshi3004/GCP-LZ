resource "google_monitoring_alert_policy" "quota_usage" {
  display_name = "Quota Usage Alert"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Quota usage threshold exceeded"
    
    condition_threshold {
      filter          = "metric.type=\"serviceruntime.googleapis.com/quota/used\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = []
  
  alert_strategy {
    auto_close = "3600s"
  }
}

resource "google_monitoring_alert_policy" "api_usage" {
  display_name = "High API Usage"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "API usage spike detected"
    
    condition_threshold {
      filter          = "metric.type=\"serviceruntime.googleapis.com/api/request_count\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1000
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = []
  
  alert_strategy {
    auto_close = "1800s"
  }
}