resource "google_bigquery_data_transfer_config" "daily_aggregation" {
  display_name   = "Daily Sales Aggregation"
  project        = var.project_id
  location       = var.region
  data_source_id = "scheduled_query"
  
  destination_dataset_id = google_bigquery_dataset.analytics.dataset_id
  
  schedule = "every day 02:00"
  
  params = {
    query = <<-SQL
      CREATE OR REPLACE TABLE `${var.project_id}.${google_bigquery_dataset.analytics.dataset_id}.daily_sales`
      PARTITION BY sale_date
      CLUSTER BY region, product_category
      AS
      SELECT
        DATE(order_timestamp) as sale_date,
        region,
        product_category,
        SUM(amount) as total_sales,
        COUNT(*) as order_count,
        COUNT(DISTINCT customer_id) as unique_customers
      FROM `${var.project_id}.raw_data.orders`
      WHERE DATE(order_timestamp) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
      GROUP BY 1, 2, 3
    SQL
  }
  
  service_account_name = google_service_account.warehouse.email
}

resource "google_bigquery_data_transfer_config" "weekly_report" {
  display_name   = "Weekly Performance Report"
  project        = var.project_id
  location       = var.region
  data_source_id = "scheduled_query"
  
  destination_dataset_id = google_bigquery_dataset.analytics.dataset_id
  
  schedule = "every monday 08:00"
  
  params = {
    query = <<-SQL
      CREATE OR REPLACE TABLE `${var.project_id}.${google_bigquery_dataset.analytics.dataset_id}.weekly_performance`
      AS
      SELECT
        DATE_TRUNC(sale_date, WEEK) as week_start,
        region,
        SUM(total_sales) as weekly_sales,
        SUM(order_count) as weekly_orders,
        AVG(total_sales) as avg_daily_sales
      FROM `${var.project_id}.${google_bigquery_dataset.analytics.dataset_id}.daily_sales`
      WHERE sale_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
      GROUP BY 1, 2
      ORDER BY 1 DESC, 2
    SQL
  }
  
  service_account_name = google_service_account.warehouse.email
}