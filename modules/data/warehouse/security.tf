resource "google_bigquery_table" "secure_customer_data" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "secure_customer_data"
  project    = var.project_id
  
  schema = jsonencode([
    {
      name = "customer_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "email"
      type = "STRING"
      mode = "REQUIRED"
      policyTags = {
        names = ["projects/${var.project_id}/locations/${var.region}/taxonomies/customer-data/policyTags/pii"]
      }
    },
    {
      name = "region"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "total_spent"
      type = "NUMERIC"
      mode = "REQUIRED"
    }
  ])
  
  labels = var.labels
}

resource "google_bigquery_dataset_access" "regional_access" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  project    = var.project_id
  
  role = "roles/bigquery.dataViewer"
  
  routine {
    project_id = var.project_id
    dataset_id = google_bigquery_dataset.analytics.dataset_id
    routine_id = "regional_filter_function"
  }
}

resource "google_bigquery_routine" "regional_filter_function" {
  dataset_id      = google_bigquery_dataset.analytics.dataset_id
  routine_id      = "regional_filter_function"
  project         = var.project_id
  routine_type    = "TABLE_VALUED_FUNCTION"
  language        = "SQL"
  
  definition_body = <<-SQL
    CREATE OR REPLACE TABLE FUNCTION `${var.project_id}.${google_bigquery_dataset.analytics.dataset_id}.regional_filter_function`(user_region STRING)
    AS (
      SELECT *
      FROM `${var.project_id}.${google_bigquery_dataset.analytics.dataset_id}.secure_customer_data`
      WHERE region = user_region
    )
  SQL
  
  arguments {
    name      = "user_region"
    data_type = jsonencode({ "typeKind": "STRING" })
  }
}