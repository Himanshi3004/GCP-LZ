resource "google_bigquery_dataset" "analytics" {
  dataset_id  = "analytics"
  project     = var.project_id
  location    = var.region
  description = "Analytics dataset for business intelligence"
  
  labels = var.labels
}

resource "google_bigquery_dataset" "ml_models" {
  count       = var.enable_ml ? 1 : 0
  dataset_id  = "ml_models"
  project     = var.project_id
  location    = var.region
  description = "Dataset for BigQuery ML models"
  
  labels = var.labels
}

resource "google_bigquery_dataset_iam_member" "analytics_access" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.warehouse.email}"
  project    = var.project_id
}

resource "google_bigquery_dataset_iam_member" "ml_access" {
  count      = var.enable_ml ? 1 : 0
  dataset_id = google_bigquery_dataset.ml_models[0].dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.warehouse.email}"
  project    = var.project_id
}