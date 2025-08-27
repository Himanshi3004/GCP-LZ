resource "google_project_service" "debugger" {
  count   = var.enable_debugger ? 1 : 0
  project = var.project_id
  service = "clouddebugger.googleapis.com"
  disable_on_destroy = false
}

resource "google_monitoring_alert_policy" "debug_sessions" {
  count        = var.enable_debugger ? 1 : 0
  display_name = "Active Debug Sessions"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Debug sessions active"
    
    condition_threshold {
      filter          = "resource.type=\"debugger_breakpoint\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "60s"
    }
  }
  
  notification_channels = []
  
  alert_strategy {
    auto_close = "3600s"
  }
}