resource "google_project_service" "profiler" {
  count   = var.enable_profiler ? 1 : 0
  project = var.project_id
  service = "cloudprofiler.googleapis.com"
  disable_on_destroy = false
}

resource "google_monitoring_alert_policy" "cpu_usage" {
  count        = var.enable_profiler ? 1 : 0
  display_name = "High CPU Usage"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "CPU usage threshold exceeded"
    
    condition_threshold {
      filter          = "resource.type=\"gce_instance\""
      comparison      = "COMPARISON_GT"
      threshold_value = 80
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = []
  
  alert_strategy {
    auto_close = "1800s"
  }
}