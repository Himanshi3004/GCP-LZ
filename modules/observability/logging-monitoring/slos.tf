# SLO Monitoring and Error Budget Policies
# Defines Service Level Objectives and monitors error budgets

# SLO definitions for different service types
resource "google_monitoring_slo" "api_availability_slo" {
  for_each = var.api_services
  
  project      = var.project_id
  service      = google_monitoring_service.api_services[each.key].service_id
  slo_id       = "${each.key}-availability-slo"
  display_name = "${each.key} API Availability SLO"
  
  goal                = each.value.availability_target  # e.g., 0.999 for 99.9%
  calendar_period     = "MONTH"
  rolling_period_days = 30
  
  availability {
    enabled = true
  }
  
  user_labels = merge(var.labels, {
    service_type = "api"
    slo_type    = "availability"
  })
}

resource "google_monitoring_slo" "api_latency_slo" {
  for_each = var.api_services
  
  project      = var.project_id
  service      = google_monitoring_service.api_services[each.key].service_id
  slo_id       = "${each.key}-latency-slo"
  display_name = "${each.key} API Latency SLO"
  
  goal                = each.value.latency_target  # e.g., 0.95 for 95th percentile
  calendar_period     = "MONTH"
  rolling_period_days = 30
  
  request_based_sli {
    distribution_cut {
      distribution_filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${each.key}\" AND metric.type=\"run.googleapis.com/request_latencies\""
      
      range {
        max = each.value.latency_threshold_ms  # e.g., 500ms
      }
    }
  }
  
  user_labels = merge(var.labels, {
    service_type = "api"
    slo_type    = "latency"
  })
}

resource "google_monitoring_slo" "database_availability_slo" {
  for_each = var.database_services
  
  project      = var.project_id
  service      = google_monitoring_service.database_services[each.key].service_id
  slo_id       = "${each.key}-db-availability-slo"
  display_name = "${each.key} Database Availability SLO"
  
  goal                = each.value.availability_target
  calendar_period     = "MONTH"
  rolling_period_days = 30
  
  availability {
    enabled = true
  }
  
  user_labels = merge(var.labels, {
    service_type = "database"
    slo_type    = "availability"
  })
}

# Monitoring services for SLOs
resource "google_monitoring_service" "api_services" {
  for_each = var.api_services
  
  project      = var.project_id
  service_id   = "${each.key}-api-service"
  display_name = "${each.key} API Service"
  
  basic_service {
    service_type = "CLOUD_RUN"
    service_labels = {
      service_name = each.key
    }
  }
  
  user_labels = merge(var.labels, {
    service_type = "api"
  })
}

resource "google_monitoring_service" "database_services" {
  for_each = var.database_services
  
  project      = var.project_id
  service_id   = "${each.key}-db-service"
  display_name = "${each.key} Database Service"
  
  basic_service {
    service_type = "CLOUD_SQL"
    service_labels = {
      database_id = each.key
    }
  }
  
  user_labels = merge(var.labels, {
    service_type = "database"
  })
}

resource "google_monitoring_service" "infrastructure_services" {
  for_each = var.infrastructure_services
  
  project      = var.project_id
  service_id   = "${each.key}-infra-service"
  display_name = "${each.key} Infrastructure Service"
  
  basic_service {
    service_type = "GCE"
    service_labels = {
      instance_name = each.key
    }
  }
  
  user_labels = merge(var.labels, {
    service_type = "infrastructure"
  })
}

# Error budget policies
resource "google_monitoring_alert_policy" "error_budget_burn_rate" {
  for_each = merge(
    { for k, v in google_monitoring_slo.api_availability_slo : k => v },
    { for k, v in google_monitoring_slo.api_latency_slo : k => v },
    { for k, v in google_monitoring_slo.database_availability_slo : k => v }
  )
  
  project      = var.project_id
  display_name = "Error Budget Burn Rate - ${each.value.display_name}"
  combiner     = "OR"
  
  # Fast burn rate (2% budget consumed in 1 hour)
  conditions {
    display_name = "Fast burn rate"
    
    condition_threshold {
      filter          = "select_slo_burn_rate(\"${each.value.name}\", \"3600s\")"
      duration        = "120s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 14.4  # 2% of monthly budget in 1 hour
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  # Slow burn rate (10% budget consumed in 6 hours)
  conditions {
    display_name = "Slow burn rate"
    
    condition_threshold {
      filter          = "select_slo_burn_rate(\"${each.value.name}\", \"21600s\")"
      duration        = "900s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 6  # 10% of monthly budget in 6 hours
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = var.slo_notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
  
  documentation {
    content = "Error budget is being consumed rapidly for ${each.value.display_name}. Investigate service reliability issues."
  }
}

# SLO compliance alerts
resource "google_monitoring_alert_policy" "slo_compliance" {
  for_each = merge(
    { for k, v in google_monitoring_slo.api_availability_slo : k => v },
    { for k, v in google_monitoring_slo.api_latency_slo : k => v },
    { for k, v in google_monitoring_slo.database_availability_slo : k => v }
  )
  
  project      = var.project_id
  display_name = "SLO Compliance - ${each.value.display_name}"
  combiner     = "OR"
  
  conditions {
    display_name = "SLO compliance below threshold"
    
    condition_threshold {
      filter          = "select_slo_compliance(\"${each.value.name}\")"
      duration        = "300s"
      comparison      = "COMPARISON_LESS_THAN"
      threshold_value = each.value.goal * 0.95  # Alert when below 95% of SLO target
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = var.slo_notification_channels
  
  alert_strategy {
    auto_close = "3600s"
  }
}

# Error budget exhaustion alerts
resource "google_monitoring_alert_policy" "error_budget_exhausted" {
  for_each = merge(
    { for k, v in google_monitoring_slo.api_availability_slo : k => v },
    { for k, v in google_monitoring_slo.api_latency_slo : k => v },
    { for k, v in google_monitoring_slo.database_availability_slo : k => v }
  )
  
  project      = var.project_id
  display_name = "Error Budget Exhausted - ${each.value.display_name}"
  combiner     = "OR"
  
  conditions {
    display_name = "Error budget exhausted"
    
    condition_threshold {
      filter          = "select_slo_budget_fraction(\"${each.value.name}\")"
      duration        = "60s"
      comparison      = "COMPARISON_LESS_THAN"
      threshold_value = 0.1  # Alert when less than 10% budget remaining
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = concat(
    var.slo_notification_channels,
    var.critical_notification_channels
  )
  
  alert_strategy {
    auto_close = "300s"
  }
  
  documentation {
    content = "CRITICAL: Error budget for ${each.value.display_name} is nearly exhausted. Implement emergency response procedures."
  }
}

# SLO reporting dashboard
resource "google_monitoring_dashboard" "slo_dashboard" {
  project        = var.project_id
  dashboard_json = jsonencode({
    displayName = "SLO Dashboard"
    mosaicLayout = {
      tiles = [
        {
          width = 12
          height = 4
          widget = {
            title = "SLO Compliance Overview"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"slo\" AND metric.type=\"serviceruntime.googleapis.com/api/request_count\""
                    aggregation = {
                      alignmentPeriod = "3600s"
                      perSeriesAligner = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_MEAN"
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
            title = "Error Budget Burn Rate"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"slo\""
                    aggregation = {
                      alignmentPeriod = "3600s"
                      perSeriesAligner = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_MEAN"
                      groupByFields = ["resource.labels.slo_name"]
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
            title = "Remaining Error Budget"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"slo\""
                  aggregation = {
                    alignmentPeriod = "3600s"
                    perSeriesAligner = "ALIGN_MEAN"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_BAR"
              }
            }
          }
        }
      ]
    }
  })
}

# SLO documentation generation
resource "google_storage_bucket_object" "slo_documentation" {
  bucket  = var.documentation_bucket
  name    = "slos/slo-definitions-${formatdate("YYYY-MM-DD", timestamp())}.md"
  content = templatefile("${path.module}/templates/slo-documentation.md.tpl", {
    api_services = var.api_services
    database_services = var.database_services
    infrastructure_services = var.infrastructure_services
    slos_created = merge(
      { for k, v in google_monitoring_slo.api_availability_slo : k => v },
      { for k, v in google_monitoring_slo.api_latency_slo : k => v },
      { for k, v in google_monitoring_slo.database_availability_slo : k => v }
    )
  })
}

# SLO metrics export to BigQuery
resource "google_bigquery_dataset" "slo_metrics" {
  project    = var.project_id
  dataset_id = "slo_metrics"
  location   = var.default_region
  
  description = "SLO metrics and error budget tracking"
  
  default_table_expiration_ms = 31536000000  # 1 year
  
  labels = merge(var.labels, {
    purpose = "slo-tracking"
  })
}

# Scheduled query for SLO reporting
resource "google_bigquery_data_transfer_config" "slo_reporting" {
  project        = var.project_id
  display_name   = "SLO Metrics Export"
  location       = var.default_region
  data_source_id = "scheduled_query"
  
  schedule = "every day 00:00"
  
  destination_dataset_id = google_bigquery_dataset.slo_metrics.dataset_id
  
  params = {
    destination_table_name_template = "slo_daily_report_{run_date}"
    write_disposition              = "WRITE_TRUNCATE"
    query = <<-EOT
      SELECT
        CURRENT_DATE() as report_date,
        slo_name,
        service_name,
        slo_type,
        target_goal,
        actual_performance,
        error_budget_remaining,
        burn_rate_1h,
        burn_rate_6h,
        burn_rate_24h,
        compliance_status
      FROM (
        SELECT
          resource.labels.slo_name as slo_name,
          resource.labels.service_name as service_name,
          resource.labels.slo_type as slo_type,
          0.999 as target_goal,  -- This would be dynamic based on actual SLO config
          AVG(value.double_value) as actual_performance,
          1.0 - AVG(value.double_value) as error_budget_remaining,
          -- Calculate burn rates for different time windows
          0.0 as burn_rate_1h,   -- These would be calculated from actual metrics
          0.0 as burn_rate_6h,
          0.0 as burn_rate_24h,
          CASE 
            WHEN AVG(value.double_value) >= 0.999 THEN 'COMPLIANT'
            ELSE 'NON_COMPLIANT'
          END as compliance_status
        FROM `${var.project_id}.monitoring.slo_metrics`
        WHERE DATE(timestamp) = CURRENT_DATE() - 1
        GROUP BY 1, 2, 3, 4
      )
    EOT
  }
  
  depends_on = [google_bigquery_dataset.slo_metrics]
}