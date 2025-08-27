resource "google_project" "cost_labels" {
  name       = var.project_id
  project_id = var.project_id
  
  labels = merge(var.labels, var.cost_allocation_labels)
  
  lifecycle {
    ignore_changes = [project_id]
  }
}

resource "google_monitoring_alert_policy" "unlabeled_resources" {
  display_name = "Unlabeled Resources Alert"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Resources without cost allocation labels"
    
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND NOT resource.label.cost_center"
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "300s"
    }
  }
  
  notification_channels = []
  
  alert_strategy {
    auto_close = "86400s"
  }
}