# Custom Monitoring Dashboards
# Creates comprehensive dashboards for infrastructure, applications, and security

# Infrastructure Overview Dashboard
resource "google_monitoring_dashboard" "infrastructure_overview" {
  project        = var.project_id
  dashboard_json = jsonencode({
    displayName = "Infrastructure Overview"
    mosaicLayout = {
      tiles = [
        {
          width = 6
          height = 4
          widget = {
            title = "CPU Utilization by Instance"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
                    aggregation = {
                      alignmentPeriod = "300s"
                      perSeriesAligner = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_MEAN"
                      groupByFields = ["resource.labels.instance_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "CPU Utilization"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          width = 6
          height = 4
          widget = {
            title = "Memory Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/memory/utilization\""
                    aggregation = {
                      alignmentPeriod = "300s"
                      perSeriesAligner = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_MEAN"
                      groupByFields = ["resource.labels.instance_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        },
        {
          width = 12
          height = 4
          widget = {
            title = "Network Traffic"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/network/received_bytes_count\""
                      aggregation = {
                        alignmentPeriod = "300s"
                        perSeriesAligner = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_SUM"
                      }
                    }
                  }
                  plotType = "LINE"
                  legendTemplate = "Received"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/network/sent_bytes_count\""
                      aggregation = {
                        alignmentPeriod = "300s"
                        perSeriesAligner = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_SUM"
                      }
                    }
                  }
                  plotType = "LINE"
                  legendTemplate = "Sent"
                }
              ]
            }
          }
        }
      ]
    }
  })
}

# Application Performance Dashboard
resource "google_monitoring_dashboard" "application_performance" {
  project        = var.project_id
  dashboard_json = jsonencode({
    displayName = "Application Performance"
    mosaicLayout = {
      tiles = [
        {
          width = 6
          height = 4
          widget = {
            title = "Request Rate"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_count\""
                    aggregation = {
                      alignmentPeriod = "300s"
                      perSeriesAligner = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields = ["resource.labels.service_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        },
        {
          width = 6
          height = 4
          widget = {
            title = "Response Latency (95th percentile)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_latencies\""
                    aggregation = {
                      alignmentPeriod = "300s"
                      perSeriesAligner = "ALIGN_DELTA"
                      crossSeriesReducer = "REDUCE_PERCENTILE_95"
                      groupByFields = ["resource.labels.service_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        },
        {
          width = 6
          height = 4
          widget = {
            title = "Error Rate"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class!=\"2xx\""
                    aggregation = {
                      alignmentPeriod = "300s"
                      perSeriesAligner = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields = ["resource.labels.service_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        },
        {
          width = 6
          height = 4
          widget = {
            title = "Container CPU Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" AND metric.type=\"kubernetes.io/container/cpu/core_usage_time\""
                    aggregation = {
                      alignmentPeriod = "300s"
                      perSeriesAligner = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_MEAN"
                      groupByFields = ["resource.labels.container_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        }
      ]
    }
  })
}

# Security Dashboard
resource "google_monitoring_dashboard" "security_overview" {
  project        = var.project_id
  dashboard_json = jsonencode({
    displayName = "Security Overview"
    mosaicLayout = {
      tiles = [
        {
          width = 6
          height = 4
          widget = {
            title = "Security Findings by Severity"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"organization\" AND metric.type=\"logging.googleapis.com/user/security_events\""
                    aggregation = {
                      alignmentPeriod = "3600s"
                      perSeriesAligner = "ALIGN_SUM"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields = ["metric.labels.finding_type"]
                    }
                  }
                }
                plotType = "STACKED_BAR"
              }]
            }
          }
        },
        {
          width = 6
          height = 4
          widget = {
            title = "Failed Authentication Attempts"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"organization\" AND metric.type=\"logging.googleapis.com/user/failed_auth\""
                    aggregation = {
                      alignmentPeriod = "3600s"
                      perSeriesAligner = "ALIGN_SUM"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        },
        {
          width = 12
          height = 4
          widget = {
            title = "KMS Key Usage"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"kms_key\" AND metric.type=\"cloudkms.googleapis.com/api/request_count\""
                    aggregation = {
                      alignmentPeriod = "3600s"
                      perSeriesAligner = "ALIGN_SUM"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields = ["resource.labels.key_id"]
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        }
      ]
    }
  })
}

# Cost Dashboard
resource "google_monitoring_dashboard" "cost_overview" {
  project        = var.project_id
  dashboard_json = jsonencode({
    displayName = "Cost Overview"
    mosaicLayout = {
      tiles = [
        {
          width = 6
          height = 4
          widget = {
            title = "Daily Spend by Project"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"billing_account\""
                    aggregation = {
                      alignmentPeriod = "86400s"
                      perSeriesAligner = "ALIGN_SUM"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields = ["resource.labels.project_id"]
                    }
                  }
                }
                plotType = "STACKED_BAR"
              }]
            }
          }
        },
        {
          width = 6
          height = 4
          widget = {
            title = "Cost by Service"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"billing_account\""
                    aggregation = {
                      alignmentPeriod = "86400s"
                      perSeriesAligner = "ALIGN_SUM"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields = ["metric.labels.service"]
                    }
                  }
                }
                plotType = "PIE"
              }]
            }
          }
        },
        {
          width = 12
          height = 4
          widget = {
            title = "Budget vs Actual Spend"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"billing_account\" AND metric.type=\"billing.googleapis.com/billing/current_balance\""
                      aggregation = {
                        alignmentPeriod = "86400s"
                        perSeriesAligner = "ALIGN_MEAN"
                      }
                    }
                  }
                  plotType = "LINE"
                  legendTemplate = "Actual Spend"
                }
              ]
            }
          }
        }
      ]
    }
  })
}

# Executive Dashboard
resource "google_monitoring_dashboard" "executive_overview" {
  project        = var.project_id
  dashboard_json = jsonencode({
    displayName = "Executive Overview"
    mosaicLayout = {
      tiles = [
        {
          width = 3
          height = 3
          widget = {
            title = "System Uptime"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"uptime_check\" AND metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\""
                  aggregation = {
                    alignmentPeriod = "3600s"
                    perSeriesAligner = "ALIGN_FRACTION_TRUE"
                    crossSeriesReducer = "REDUCE_MEAN"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_LINE"
              }
            }
          }
        },
        {
          width = 3
          height = 3
          widget = {
            title = "Active Security Incidents"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"organization\" AND metric.type=\"logging.googleapis.com/user/security_events\""
                  aggregation = {
                    alignmentPeriod = "3600s"
                    perSeriesAligner = "ALIGN_SUM"
                  }
                }
              }
            }
          }
        },
        {
          width = 3
          height = 3
          widget = {
            title = "Monthly Cost"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"billing_account\""
                  aggregation = {
                    alignmentPeriod = "86400s"
                    perSeriesAligner = "ALIGN_SUM"
                  }
                }
              }
            }
          }
        },
        {
          width = 3
          height = 3
          widget = {
            title = "Error Rate"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class!=\"2xx\""
                  aggregation = {
                    alignmentPeriod = "3600s"
                    perSeriesAligner = "ALIGN_RATE"
                    crossSeriesReducer = "REDUCE_SUM"
                  }
                }
              }
            }
          }
        }
      ]
    }
  })
}

# Dashboard access control
resource "google_monitoring_dashboard" "dashboard_permissions" {
  for_each = {
    infrastructure = google_monitoring_dashboard.infrastructure_overview.id
    application   = google_monitoring_dashboard.application_performance.id
    security      = google_monitoring_dashboard.security_overview.id
    cost          = google_monitoring_dashboard.cost_overview.id
    executive     = google_monitoring_dashboard.executive_overview.id
  }
  
  # Note: Dashboard permissions are managed through project-level IAM
  # Users need monitoring.dashboards.get permission to view dashboards
}

# Dashboard backup and versioning
resource "google_storage_bucket_object" "dashboard_backup" {
  for_each = {
    infrastructure = google_monitoring_dashboard.infrastructure_overview.dashboard_json
    application   = google_monitoring_dashboard.application_performance.dashboard_json
    security      = google_monitoring_dashboard.security_overview.dashboard_json
    cost          = google_monitoring_dashboard.cost_overview.dashboard_json
    executive     = google_monitoring_dashboard.executive_overview.dashboard_json
  }
  
  bucket  = var.backup_bucket
  name    = "dashboards/${each.key}-${formatdate("YYYY-MM-DD", timestamp())}.json"
  content = each.value
}