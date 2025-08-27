output "analytics_dataset_id" {
  description = "Analytics dataset ID"
  value       = google_bigquery_dataset.analytics.dataset_id
}

output "ml_dataset_id" {
  description = "ML models dataset ID"
  value       = var.enable_ml ? google_bigquery_dataset.ml_models[0].dataset_id : null
}

output "reservation_name" {
  description = "BigQuery reservation name"
  value       = var.enable_slot_reservations ? google_bigquery_reservation.warehouse[0].name : null
}

output "bi_engine_reservation_id" {
  description = "BI Engine reservation ID"
  value       = var.enable_bi_engine ? google_bigquery_bi_reservation.warehouse[0].name : null
}

output "materialized_views" {
  description = "Materialized view names"
  value = {
    daily_sales      = google_bigquery_table.daily_sales_mv.table_id
    customer_metrics = google_bigquery_table.customer_metrics_mv.table_id
  }
}

output "scheduled_queries" {
  description = "Scheduled query names"
  value = {
    daily_aggregation = google_bigquery_data_transfer_config.daily_aggregation.display_name
    weekly_report     = google_bigquery_data_transfer_config.weekly_report.display_name
  }
}

output "service_account_email" {
  description = "Warehouse service account email"
  value       = google_service_account.warehouse.email
}