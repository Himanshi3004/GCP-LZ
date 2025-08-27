# FinOps Practices Implementation
# Implements financial operations practices for cloud cost management

# Chargeback reporting view
resource "google_bigquery_table" "chargeback_report" {
  count      = var.chargeback_enabled ? 1 : 0
  dataset_id = google_bigquery_dataset.billing[0].dataset_id
  table_id   = "chargeback_report"
  project    = var.project_id
  
  view {
    query = <<EOF
WITH cost_allocation AS (
  SELECT
    project.name as project_name,
    labels.value as cost_center,
    labels.value as team,
    service.description as service_name,
    SUM(cost) as allocated_cost,
    currency,
    DATE_TRUNC(DATE(usage_start_time), MONTH) as billing_month
  FROM `${var.project_id}.billing_export.gcp_billing_export_v1_${replace(var.billing_account, "-", "_")}`,
  UNNEST(labels) as labels
  WHERE labels.key IN ('cost_center', 'team')
    AND DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
  GROUP BY project_name, cost_center, team, service_name, currency, billing_month
)
SELECT
  billing_month,
  cost_center,
  team,
  project_name,
  service_name,
  allocated_cost,
  currency,
  SUM(allocated_cost) OVER (PARTITION BY cost_center, billing_month) as total_cost_center_cost
FROM cost_allocation
ORDER BY billing_month DESC, allocated_cost DESC
EOF
    use_legacy_sql = false
  }
  
  labels = var.labels
}

# Showback dashboard data
resource "google_bigquery_table" "showback_data" {
  count      = var.showback_enabled ? 1 : 0
  dataset_id = google_bigquery_dataset.billing[0].dataset_id
  table_id   = "showback_data"
  project    = var.project_id
  
  view {
    query = <<EOF
SELECT
  project.name as project_name,
  service.description as service_name,
  SUM(cost) as monthly_cost,
  currency,
  DATE_TRUNC(DATE(usage_start_time), MONTH) as billing_month,
  LAG(SUM(cost)) OVER (PARTITION BY project.name, service.description ORDER BY DATE_TRUNC(DATE(usage_start_time), MONTH)) as previous_month_cost,
  ROUND((SUM(cost) - LAG(SUM(cost)) OVER (PARTITION BY project.name, service.description ORDER BY DATE_TRUNC(DATE(usage_start_time), MONTH))) / LAG(SUM(cost)) OVER (PARTITION BY project.name, service.description ORDER BY DATE_TRUNC(DATE(usage_start_time), MONTH)) * 100, 2) as cost_change_percent
FROM `${var.project_id}.billing_export.gcp_billing_export_v1_${replace(var.billing_account, "-", "_")}`
WHERE DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
GROUP BY project_name, service_name, currency, billing_month
ORDER BY billing_month DESC, monthly_cost DESC
EOF
    use_legacy_sql = false
  }
  
  labels = var.labels
}

# Cost forecasting view
resource "google_bigquery_table" "cost_forecast" {
  count      = var.enable_finops_practices ? 1 : 0
  dataset_id = google_bigquery_dataset.billing[0].dataset_id
  table_id   = "cost_forecast"
  project    = var.project_id
  
  view {
    query = <<EOF
WITH monthly_costs AS (
  SELECT
    DATE_TRUNC(DATE(usage_start_time), MONTH) as billing_month,
    SUM(cost) as monthly_cost
  FROM `${var.project_id}.billing_export.gcp_billing_export_v1_${replace(var.billing_account, "-", "_")}`
  WHERE DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
  GROUP BY billing_month
),
trend_analysis AS (
  SELECT
    billing_month,
    monthly_cost,
    AVG(monthly_cost) OVER (ORDER BY billing_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as three_month_avg,
    (monthly_cost - LAG(monthly_cost) OVER (ORDER BY billing_month)) / LAG(monthly_cost) OVER (ORDER BY billing_month) as growth_rate
  FROM monthly_costs
)
SELECT
  billing_month,
  monthly_cost,
  three_month_avg,
  growth_rate,
  three_month_avg * (1 + COALESCE(growth_rate, 0)) as forecasted_next_month
FROM trend_analysis
ORDER BY billing_month DESC
EOF
    use_legacy_sql = false
  }
  
  labels = var.labels
}

# Cost governance alerts
resource "google_monitoring_alert_policy" "cost_governance" {
  count        = var.enable_finops_practices ? 1 : 0
  display_name = "Cost Governance Violations"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Untagged resources detected"
    
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metadata.user_labels.cost_center=\"\""
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0
      duration        = "300s"
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "3600s"
  }
}