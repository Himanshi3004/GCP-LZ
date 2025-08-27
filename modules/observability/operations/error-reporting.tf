resource "google_project_service" "error_reporting" {
  count   = var.enable_error_reporting ? 1 : 0
  project = var.project_id
  service = "clouderrorreporting.googleapis.com"
  disable_on_destroy = false
}

resource "google_monitoring_alert_policy" "error_rate" {
  count        = var.enable_error_reporting ? 1 : 0
  display_name = "High Error Rate"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Error rate threshold exceeded"
    
    condition_threshold {
      filter          = "resource.type=\"gae_app\""
      comparison      = "COMPARISON_GT"
      threshold_value = 10
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