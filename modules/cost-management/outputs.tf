# Cost Management Module Outputs

# Service Account
output "cost_management_service_account" {
  description = "Cost management service account details"
  value = {
    email      = google_service_account.cost_management.email
    account_id = google_service_account.cost_management.account_id
    unique_id  = google_service_account.cost_management.unique_id
  }
}

# Billing Export
output "billing_export" {
  description = "Billing export configuration"
  value = var.enable_billing_export ? {
    dataset_id = google_bigquery_dataset.billing[0].dataset_id
    location   = google_bigquery_dataset.billing[0].location
    project_id = google_bigquery_dataset.billing[0].project
    storage_bucket = var.enable_storage_export ? google_storage_bucket.billing_export[0].name : null
  } : null
}

# Budget Configuration
output "budgets" {
  description = "Budget configuration details"
  value = var.enable_budget_alerts ? {
    project_budget = {
      name   = google_billing_budget.project_budget[0].display_name
      amount = var.budget_amount
    }
    compute_budget = {
      name   = google_billing_budget.compute_budget[0].display_name
      amount = var.budget_amount * 0.6
    }
    storage_budget = {
      name   = google_billing_budget.storage_budget[0].display_name
      amount = var.budget_amount * 0.2
    }
  } : null
}

# Cost Views
output "cost_views" {
  description = "BigQuery views for cost analysis"
  value = var.enable_billing_export ? {
    cost_by_service = "${var.project_id}.${google_bigquery_dataset.billing[0].dataset_id}.${google_bigquery_table.cost_by_service_view[0].table_id}"
    cost_by_project = "${var.project_id}.${google_bigquery_dataset.billing[0].dataset_id}.${google_bigquery_table.cost_by_project_view[0].table_id}"
    cost_allocation = "${var.project_id}.${google_bigquery_dataset.billing[0].dataset_id}.${google_bigquery_table.cost_allocation_view[0].table_id}"
  } : null
}

# Cost Optimization
output "cost_optimization" {
  description = "Cost optimization resources"
  value = var.enable_cost_optimization ? {
    cost_alerts_topic = google_pubsub_topic.cost_alerts[0].name
    rightsizing_view = var.enable_rightsizing_recommendations ? "${var.project_id}.${google_bigquery_dataset.billing[0].dataset_id}.${google_bigquery_table.rightsizing_recommendations[0].table_id}" : null
    idle_resources_view = var.enable_idle_resource_cleanup ? "${var.project_id}.${google_bigquery_dataset.billing[0].dataset_id}.${google_bigquery_table.idle_resources[0].table_id}" : null
  } : null
}

# FinOps Resources
output "finops" {
  description = "FinOps resources and views"
  value = var.enable_finops_practices ? {
    chargeback_report = var.chargeback_enabled ? "${var.project_id}.${google_bigquery_dataset.billing[0].dataset_id}.${google_bigquery_table.chargeback_report[0].table_id}" : null
    showback_data = var.showback_enabled ? "${var.project_id}.${google_bigquery_dataset.billing[0].dataset_id}.${google_bigquery_table.showback_data[0].table_id}" : null
    cost_forecast = "${var.project_id}.${google_bigquery_dataset.billing[0].dataset_id}.${google_bigquery_table.cost_forecast[0].table_id}"
  } : null
}

# Dashboards
output "dashboards" {
  description = "Cost management dashboards"
  value = {
    executive_dashboard = google_monitoring_dashboard.executive_cost_dashboard.id
    operational_dashboard = google_monitoring_dashboard.operational_cost_dashboard.id
    finops_dashboard = var.enable_finops_practices ? google_monitoring_dashboard.finops_dashboard[0].id : null
  }
}

# Notification Channels
output "notification_channels" {
  description = "Notification channels for cost alerts"
  value = length(var.cost_alert_emails) > 0 ? [
    for channel in google_monitoring_notification_channel.email : channel.id
  ] : []
}