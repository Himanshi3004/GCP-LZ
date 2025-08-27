resource "google_monitoring_alert_policy" "rto_alert" {
  display_name = "RTO Violation Alert"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Recovery time exceeds RTO"
    
    condition_threshold {
      filter          = "resource.type=\"gce_instance\""
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = var.rto_minutes * 60
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_alert_policy" "rpo_alert" {
  display_name = "RPO Violation Alert"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Data loss exceeds RPO"
    
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\""
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = var.rpo_minutes * 60
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_dashboard" "dr_dashboard" {
  dashboard_json = jsonencode({
    displayName = "Disaster Recovery Dashboard"
    mosaicLayout = {
      tiles = [
        {
          width = 6
          height = 4
          widget = {
            title = "Primary Region Health"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_instance\" AND resource.label.region=\"${var.primary_region}\""
                    aggregation = {
                      alignmentPeriod = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          width = 6
          height = 4
          widget = {
            title = "DR Region Health"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_instance\" AND resource.label.region=\"${var.dr_region}\""
                    aggregation = {
                      alignmentPeriod = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          width = 12
          height = 4
          widget = {
            title = "RTO/RPO Metrics"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"custom.googleapis.com/dr/rto\""
                      aggregation = {
                        alignmentPeriod = "300s"
                        perSeriesAligner = "ALIGN_MEAN"
                      }
                    }
                  }
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"custom.googleapis.com/dr/rpo\""
                      aggregation = {
                        alignmentPeriod = "300s"
                        perSeriesAligner = "ALIGN_MEAN"
                      }
                    }
                  }
                }
              ]
            }
          }
        }
      ]
    }
  })
  
  project = var.project_id
}