resource "google_bigquery_dataset" "data_lake" {
  dataset_id  = "data_lake"
  project     = var.project_id
  location    = var.region
  description = "Data lake dataset for raw and processed data"
  
  default_table_expiration_ms = var.retention_days.processed * 24 * 60 * 60 * 1000
  
  labels = var.labels
}

resource "google_bigquery_dataset" "staging" {
  dataset_id  = "staging"
  project     = var.project_id
  location    = var.region
  description = "Staging dataset for data processing"
  
  default_table_expiration_ms = var.retention_days.raw * 24 * 60 * 60 * 1000
  
  labels = var.labels
}

resource "google_bigquery_dataset_iam_member" "data_lake_access" {
  for_each = toset([
    google_bigquery_dataset.data_lake.dataset_id,
    google_bigquery_dataset.staging.dataset_id
  ])
  
  dataset_id = each.value
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.data_lake.email}"
  project    = var.project_id
}

resource "google_bigquery_table" "raw_events" {
  dataset_id = google_bigquery_dataset.data_lake.dataset_id
  table_id   = "raw_events"
  project    = var.project_id
  
  time_partitioning {
    type  = "DAY"
    field = "event_timestamp"
  }
  
  clustering = ["event_type", "source_system"]
  
  schema = jsonencode([
    {
      name = "event_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "event_timestamp"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    },
    {
      name = "event_type"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "source_system"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "payload"
      type = "JSON"
      mode = "NULLABLE"
    }
  ])
  
  labels = var.labels
}