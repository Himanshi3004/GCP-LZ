# Cost Optimization Configuration
# Implements cost optimization features and FinOps practices

# Cloud Function for cost anomaly detection
resource "google_storage_bucket" "cost_functions" {
  count    = var.enable_cost_optimization ? 1 : 0
  name     = "${var.project_id}-cost-functions"
  project  = var.project_id
  location = var.region
  
  labels = var.labels
}

# Pub/Sub topic for cost alerts
resource "google_pubsub_topic" "cost_alerts" {
  count   = var.enable_cost_optimization ? 1 : 0
  name    = "cost-alerts"
  project = var.project_id
  
  labels = var.labels
}

# Cost anomaly detection alert policy
resource "google_monitoring_alert_policy" "cost_anomaly" {
  count        = var.enable_cost_optimization ? 1 : 0
  display_name = "Cost Anomaly Detection"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Unusual cost spike detected"
    
    condition_threshold {
      filter          = "resource.type=\"billing_account\""
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = var.cost_anomaly_threshold
      duration        = "3600s"
      
      aggregations {
        alignment_period   = "3600s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "86400s"
  }
}

# Rightsizing recommendations query
resource "google_bigquery_table" "rightsizing_recommendations" {
  count      = var.enable_rightsizing_recommendations ? 1 : 0
  dataset_id = google_bigquery_dataset.billing[0].dataset_id
  table_id   = "rightsizing_recommendations"
  project    = var.project_id
  
  view {
    query = <<EOF
WITH instance_usage AS (
  SELECT
    project.id as project_id,
    resource.global.name as instance_name,
    AVG(usage.amount) as avg_cpu_usage,
    MAX(usage.amount) as max_cpu_usage,
    SUM(cost) as total_cost
  FROM `${var.project_id}.billing_export.gcp_billing_export_v1_${replace(var.billing_account, "-", "_")}`
  WHERE service.description = 'Compute Engine'
    AND sku.description LIKE '%CPU%'
    AND DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  GROUP BY project_id, instance_name
)
SELECT
  project_id,
  instance_name,
  avg_cpu_usage,
  max_cpu_usage,
  total_cost,
  CASE 
    WHEN avg_cpu_usage < 0.2 THEN 'DOWNSIZE'
    WHEN avg_cpu_usage > 0.8 THEN 'UPSIZE'
    ELSE 'OPTIMAL'
  END as recommendation
FROM instance_usage
WHERE avg_cpu_usage < 0.2 OR avg_cpu_usage > 0.8
ORDER BY total_cost DESC
EOF
    use_legacy_sql = false
  }
  
  labels = var.labels
}

# Idle resource detection
resource "google_bigquery_table" "idle_resources" {
  count      = var.enable_idle_resource_cleanup ? 1 : 0
  dataset_id = google_bigquery_dataset.billing[0].dataset_id
  table_id   = "idle_resources"
  project    = var.project_id
  
  view {
    query = <<EOF
SELECT
  project.id as project_id,
  resource.global.name as resource_name,
  service.description as service_type,
  SUM(cost) as wasted_cost,
  COUNT(*) as idle_days
FROM `${var.project_id}.billing_export.gcp_billing_export_v1_${replace(var.billing_account, "-", "_")}`
WHERE usage.amount = 0
  AND cost > 0
  AND DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY project_id, resource_name, service_type
HAVING idle_days >= 3
ORDER BY wasted_cost DESC
EOF
    use_legacy_sql = false
  }
  
  labels = var.labels
}