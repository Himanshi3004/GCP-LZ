# Cost Management Dashboards
# Comprehensive dashboards for cost visibility and management

# Executive Cost Dashboard
resource "google_monitoring_dashboard" "executive_cost_dashboard" {
  project = var.project_id
  
  dashboard_json = jsonencode({
    displayName = "Executive Cost Dashboard"
    mosaicLayout = {
      tiles = [
        {
          width = 6
          height = 4
          widget = {
            title = "Monthly Spend Trend"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"billing_account\""
                    aggregation = {
                      alignmentPeriod = "86400s"
                      perSeriesAligner = "ALIGN_SUM"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Cost (USD)"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          width = 6
          height = 4
          widget = {
            title = "Budget Utilization"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"billing_account\""
                  aggregation = {
                    alignmentPeriod = "2592000s"
                    perSeriesAligner = "ALIGN_SUM"
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
          width = 12
          height = 4
          widget = {
            title = "Cost by Service"
            pieChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_instance\""
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
}

# Operational Cost Dashboard
resource "google_monitoring_dashboard" "operational_cost_dashboard" {
  project = var.project_id
  
  dashboard_json = jsonencode({
    displayName = "Operational Cost Management"
    mosaicLayout = {
      tiles = [
        {
          width = 4
          height = 4
          widget = {
            title = "Cost by Project"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_project\""
                  }
                }
                plotType = "STACKED_BAR"
              }]
            }
          }
        },
        {
          width = 4
          height = 4
          widget = {
            title = "Quota Usage"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"serviceruntime.googleapis.com/quota/used\""
                  }
                }
              }]
            }
          }
        },
        {
          width = 4
          height = 4
          widget = {
            title = "Cost Anomalies"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"billing_account\""
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
            title = "Rightsizing Opportunities"
            table = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
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
            title = "Idle Resources"
            table = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_instance\""
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
}

# FinOps Dashboard
resource "google_monitoring_dashboard" "finops_dashboard" {
  count   = var.enable_finops_practices ? 1 : 0
  project = var.project_id
  
  dashboard_json = jsonencode({
    displayName = "FinOps Dashboard"
    mosaicLayout = {
      tiles = [
        {
          width = 6
          height = 4
          widget = {
            title = "Cost Allocation by Team"
            pieChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_instance\" AND metadata.user_labels.team!=\"\""
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
            title = "Chargeback Summary"
            table = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"billing_account\""
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
            title = "Cost Forecast vs Actual"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"billing_account\""
                    }
                  }
                  plotType = "LINE"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"billing_account\""
                    }
                  }
                  plotType = "LINE"
                }
              ]
            }
          }
        },
        {
          width = 6
          height = 4
          widget = {
            title = "Savings Opportunities"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"gce_instance\""
                }
              }
            }
          }
        },
        {
          width = 6
          height = 4
          widget = {
            title = "Cost Governance Score"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"gce_instance\" AND metadata.user_labels.cost_center!=\"\""
                }
              }
            }
          }
        }
      ]
    }
  })
}