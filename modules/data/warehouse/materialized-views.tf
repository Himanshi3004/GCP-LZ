resource "google_bigquery_table" "daily_sales_mv" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "daily_sales_mv"
  project    = var.project_id
  
  materialized_view {
    query = <<-SQL
      SELECT
        DATE(order_timestamp) as sale_date,
        region,
        product_category,
        SUM(amount) as total_sales,
        COUNT(*) as order_count
      FROM `${var.project_id}.raw_data.orders`
      WHERE DATE(order_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
      GROUP BY 1, 2, 3
    SQL
    
    enable_refresh = true
    refresh_interval_ms = 3600000 # 1 hour
  }
  
  labels = var.labels
}

resource "google_bigquery_table" "customer_metrics_mv" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "customer_metrics_mv"
  project    = var.project_id
  
  materialized_view {
    query = <<-SQL
      SELECT
        customer_id,
        COUNT(*) as total_orders,
        SUM(amount) as total_spent,
        AVG(amount) as avg_order_value,
        MAX(order_timestamp) as last_order_date
      FROM `${var.project_id}.raw_data.orders`
      GROUP BY customer_id
    SQL
    
    enable_refresh = true
    refresh_interval_ms = 7200000 # 2 hours
  }
  
  labels = var.labels
}