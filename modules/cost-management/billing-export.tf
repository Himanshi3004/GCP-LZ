# Billing Export Configuration
# Sets up BigQuery and Cloud Storage exports for billing data

# BigQuery dataset for billing export
resource "google_bigquery_dataset" "billing_export" {
  project    = var.project_id
  dataset_id = "billing_export"
  location   = var.region
  
  description = "Billing data export for cost analysis"
  
  # No expiration for billing data
  default_table_expiration_ms = null
  
  labels = merge(var.labels, {
    purpose = "billing"
  })
}

# Detailed billing export to BigQuery
resource "google_billing_account_iam_member" "billing_export_bq" {
  billing_account_id = var.billing_account
  role              = "roles/billing.viewer"
  member            = "serviceAccount:${google_service_account.cost_management.email}"
}

# Cloud Storage bucket for billing export
resource "google_storage_bucket" "billing_export" {
  project  = var.project_id
  name     = "${var.project_id}-billing-export"
  location = var.region
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 2555  # 7 years for compliance
    }
    action {
      type = "Delete"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 365  # 1 year
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
  
  labels = merge(var.labels, {
    purpose = "billing-export"
  })
}

# Cost views in BigQuery
resource "google_bigquery_table" "cost_by_project" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.billing_export.dataset_id
  table_id   = "cost_by_project"
  
  view {
    query = <<-EOT
      SELECT
        project.id as project_id,
        project.name as project_name,
        service.description as service,
        sku.description as sku,
        DATE(usage_start_time) as usage_date,
        SUM(cost) as total_cost,
        currency
      FROM `${var.project_id}.${google_bigquery_dataset.billing_export.dataset_id}.gcp_billing_export_v1_${replace(var.billing_account, "-", "_")}`
      WHERE cost > 0
      GROUP BY 1, 2, 3, 4, 5, 7
      ORDER BY usage_date DESC, total_cost DESC
    EOT
    
    use_legacy_sql = false
  }
  
  labels = var.labels
}

resource "google_bigquery_table" "cost_by_service" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.billing_export.dataset_id
  table_id   = "cost_by_service"
  
  view {
    query = <<-EOT
      SELECT
        service.description as service,
        DATE(usage_start_time) as usage_date,
        SUM(cost) as total_cost,
        currency,
        COUNT(DISTINCT project.id) as project_count
      FROM `${var.project_id}.${google_bigquery_dataset.billing_export.dataset_id}.gcp_billing_export_v1_${replace(var.billing_account, "-", "_")}`
      WHERE cost > 0
      GROUP BY 1, 2, 4
      ORDER BY usage_date DESC, total_cost DESC
    EOT
    
    use_legacy_sql = false
  }
  
  labels = var.labels
}

resource "google_bigquery_table" "monthly_cost_trend" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.billing_export.dataset_id
  table_id   = "monthly_cost_trend"
  
  view {
    query = <<-EOT
      SELECT
        EXTRACT(YEAR FROM usage_start_time) as year,
        EXTRACT(MONTH FROM usage_start_time) as month,
        project.id as project_id,
        service.description as service,
        SUM(cost) as total_cost,
        currency,
        LAG(SUM(cost)) OVER (
          PARTITION BY project.id, service.description 
          ORDER BY EXTRACT(YEAR FROM usage_start_time), EXTRACT(MONTH FROM usage_start_time)
        ) as previous_month_cost,
        (SUM(cost) - LAG(SUM(cost)) OVER (
          PARTITION BY project.id, service.description 
          ORDER BY EXTRACT(YEAR FROM usage_start_time), EXTRACT(MONTH FROM usage_start_time)
        )) / NULLIF(LAG(SUM(cost)) OVER (
          PARTITION BY project.id, service.description 
          ORDER BY EXTRACT(YEAR FROM usage_start_time), EXTRACT(MONTH FROM usage_start_time)
        ), 0) * 100 as cost_change_percent
      FROM `${var.project_id}.${google_bigquery_dataset.billing_export.dataset_id}.gcp_billing_export_v1_${replace(var.billing_account, "-", "_")}`
      WHERE cost > 0
      GROUP BY 1, 2, 3, 4, 6
      ORDER BY year DESC, month DESC, total_cost DESC
    EOT
    
    use_legacy_sql = false
  }
  
  labels = var.labels
}

# Retention policies for billing data
resource "google_bigquery_table" "billing_data_retention" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.billing_export.dataset_id
  table_id   = "billing_retention_policy"
  
  schema = jsonencode([
    {
      name = "retention_date"
      type = "DATE"
      mode = "REQUIRED"
    },
    {
      name = "data_type"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "retention_days"
      type = "INTEGER"
      mode = "REQUIRED"
    },
    {
      name = "action"
      type = "STRING"
      mode = "REQUIRED"
    }
  ])
  
  labels = var.labels
}

# Scheduled query for cost anomaly detection
resource "google_bigquery_data_transfer_config" "cost_anomaly_detection" {
  project        = var.project_id
  display_name   = "Cost Anomaly Detection"
  location       = var.region
  data_source_id = "scheduled_query"
  
  schedule = "every day 09:00"
  
  destination_dataset_id = google_bigquery_dataset.billing_export.dataset_id
  
  params = {
    destination_table_name_template = "cost_anomalies_{run_date}"
    write_disposition              = "WRITE_TRUNCATE"
    query = <<-EOT
      WITH daily_costs AS (
        SELECT
          project.id as project_id,
          service.description as service,
          DATE(usage_start_time) as usage_date,
          SUM(cost) as daily_cost
        FROM `${var.project_id}.${google_bigquery_dataset.billing_export.dataset_id}.gcp_billing_export_v1_${replace(var.billing_account, "-", "_")}`
        WHERE DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
        AND cost > 0
        GROUP BY 1, 2, 3
      ),
      cost_stats AS (
        SELECT
          project_id,
          service,
          AVG(daily_cost) as avg_cost,
          STDDEV(daily_cost) as stddev_cost
        FROM daily_costs
        WHERE usage_date < CURRENT_DATE()
        GROUP BY 1, 2
        HAVING COUNT(*) >= 7  -- At least 7 days of data
      )
      SELECT
        dc.project_id,
        dc.service,
        dc.usage_date,
        dc.daily_cost,
        cs.avg_cost,
        cs.stddev_cost,
        (dc.daily_cost - cs.avg_cost) / NULLIF(cs.stddev_cost, 0) as z_score,
        CASE 
          WHEN ABS((dc.daily_cost - cs.avg_cost) / NULLIF(cs.stddev_cost, 0)) > ${var.cost_anomaly_threshold}
          THEN 'ANOMALY'
          ELSE 'NORMAL'
        END as anomaly_status
      FROM daily_costs dc
      JOIN cost_stats cs ON dc.project_id = cs.project_id AND dc.service = cs.service
      WHERE dc.usage_date = CURRENT_DATE() - 1
      AND ABS((dc.daily_cost - cs.avg_cost) / NULLIF(cs.stddev_cost, 0)) > ${var.cost_anomaly_threshold}
      ORDER BY z_score DESC
    EOT
  }
  
  depends_on = [google_bigquery_dataset.billing_export]
}

# Export configuration backup
resource "google_storage_bucket_object" "export_config_backup" {
  bucket  = google_storage_bucket.billing_export.name
  name    = "config/export-config-${formatdate("YYYY-MM-DD", timestamp())}.json"
  content = jsonencode({
    timestamp = timestamp()
    billing_account = var.billing_account
    project_id = var.project_id
    dataset_id = google_bigquery_dataset.billing_export.dataset_id
    bucket_name = google_storage_bucket.billing_export.name
    retention_days = var.billing_data_retention_days
    views_created = [
      "cost_by_project",
      "cost_by_service", 
      "monthly_cost_trend"
    ]
    anomaly_detection = {
      enabled = true
      threshold = var.cost_anomaly_threshold
      schedule = "daily"
    }
  })
}

# Data export monitoring
resource "google_monitoring_alert_policy" "billing_export_failure" {
  project      = var.project_id
  display_name = "Billing Export Failure"
  combiner     = "OR"
  
  conditions {
    display_name = "BigQuery job failed"
    
    condition_threshold {
      filter          = "resource.type=\"bigquery_project\" AND metric.type=\"bigquery.googleapis.com/job/num_failed_jobs\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
  
  documentation {
    content = "Billing data export to BigQuery has failed. Check export configuration and permissions."
  }
}