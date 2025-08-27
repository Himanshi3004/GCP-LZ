# Budget Configuration
# Comprehensive budget management with forecasting and service-specific controls

# Main project budget
resource "google_billing_budget" "project_budget" {
  count           = var.enable_budget_alerts ? 1 : 0
  billing_account = var.billing_account
  display_name    = "Project Budget - ${var.project_id}"
  
  budget_filter {
    projects = ["projects/${var.project_id}"]
  }
  
  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.budget_amount)
    }
  }
  
  dynamic "threshold_rules" {
    for_each = var.budget_threshold_percentages
    content {
      threshold_percent = threshold_rules.value / 100
      spend_basis       = "CURRENT_SPEND"
    }
  }
  
  # Forecast-based threshold rules
  dynamic "threshold_rules" {
    for_each = var.enable_forecast_alerts ? var.budget_threshold_percentages : []
    content {
      threshold_percent = threshold_rules.value / 100
      spend_basis       = "FORECASTED_SPEND"
    }
  }
  
  all_updates_rule {
    monitoring_notification_channels = var.notification_channels
    disable_default_iam_recipients   = false
    
    dynamic "pubsub_topic" {
      for_each = var.enable_cost_optimization ? [1] : []
      content {
        topic = google_pubsub_topic.cost_alerts[0].id
      }
    }
  }
}

# Service-specific budgets for high-cost services
resource "google_billing_budget" "compute_budget" {
  count           = var.enable_budget_alerts ? 1 : 0
  billing_account = var.billing_account
  display_name    = "Compute Engine Budget - ${var.project_id}"
  
  budget_filter {
    projects = ["projects/${var.project_id}"]
    services = ["services/6F81-5844-456A"]  # Compute Engine service ID
  }
  
  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.budget_amount * 0.6)  # 60% of total budget
    }
  }
  
  threshold_rules {
    threshold_percent = 0.8
    spend_basis       = "CURRENT_SPEND"
  }
  
  threshold_rules {
    threshold_percent = 0.9
    spend_basis       = "FORECASTED_SPEND"
  }
  
  all_updates_rule {
    monitoring_notification_channels = var.notification_channels
    disable_default_iam_recipients   = false
  }
}

resource "google_billing_budget" "storage_budget" {
  count           = var.enable_budget_alerts ? 1 : 0
  billing_account = var.billing_account
  display_name    = "Cloud Storage Budget - ${var.project_id}"
  
  budget_filter {
    projects = ["projects/${var.project_id}"]
    services = ["services/95FF-2EF5-5EA1"]  # Cloud Storage service ID
  }
  
  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.budget_amount * 0.2)  # 20% of total budget
    }
  }
  
  threshold_rules {
    threshold_percent = 0.8
    spend_basis       = "CURRENT_SPEND"
  }
  
  all_updates_rule {
    monitoring_notification_channels = var.notification_channels
    disable_default_iam_recipients   = false
  }
}

# Budget alert monitoring policy
resource "google_monitoring_alert_policy" "budget_alert" {
  count        = var.enable_budget_alerts ? 1 : 0
  display_name = "Budget Alert - ${var.project_id}"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Budget threshold exceeded"
    
    condition_threshold {
      filter          = "resource.type=\"billing_account\""
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = var.budget_amount * 0.8
      duration        = "300s"
      
      aggregations {
        alignment_period   = "3600s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "86400s"
  }
}

# Budget utilization tracking
resource "google_bigquery_table" "budget_utilization" {
  count      = var.enable_budget_alerts ? 1 : 0
  dataset_id = google_bigquery_dataset.billing[0].dataset_id
  table_id   = "budget_utilization"
  project    = var.project_id
  
  view {
    query = <<EOF
WITH monthly_spend AS (
  SELECT
    DATE_TRUNC(DATE(usage_start_time), MONTH) as billing_month,
    SUM(cost) as actual_spend
  FROM `${var.project_id}.billing_export.gcp_billing_export_v1_${replace(var.billing_account, "-", "_")}`
  WHERE project.id = '${var.project_id}'
  GROUP BY billing_month
)
SELECT
  billing_month,
  actual_spend,
  ${var.budget_amount} as budget_amount,
  ROUND((actual_spend / ${var.budget_amount}) * 100, 2) as budget_utilization_percent,
  CASE 
    WHEN actual_spend > ${var.budget_amount} THEN 'OVER_BUDGET'
    WHEN actual_spend > ${var.budget_amount * 0.8} THEN 'WARNING'
    ELSE 'ON_TRACK'
  END as budget_status
FROM monthly_spend
ORDER BY billing_month DESC
EOF
    use_legacy_sql = false
  }
  
  labels = var.labels
}