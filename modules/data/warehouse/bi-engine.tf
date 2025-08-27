resource "google_bigquery_bi_reservation" "warehouse" {
  count    = var.enable_bi_engine ? 1 : 0
  project  = var.project_id
  location = var.region
  size     = var.bi_engine_memory_size_gb * 1024 * 1024 * 1024 # Convert GB to bytes
}

resource "google_bigquery_table" "sales_summary" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "sales_summary"
  project    = var.project_id
  
  time_partitioning {
    type  = "DAY"
    field = "sale_date"
  }
  
  clustering = ["region", "product_category"]
  
  schema = jsonencode([
    {
      name = "sale_date"
      type = "DATE"
      mode = "REQUIRED"
    },
    {
      name = "region"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "product_category"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "total_sales"
      type = "NUMERIC"
      mode = "REQUIRED"
    },
    {
      name = "order_count"
      type = "INTEGER"
      mode = "REQUIRED"
    }
  ])
  
  labels = var.labels
}