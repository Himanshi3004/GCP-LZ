resource "google_bigquery_routine" "customer_ltv_model" {
  count           = var.enable_ml ? 1 : 0
  dataset_id      = google_bigquery_dataset.ml_models[0].dataset_id
  routine_id      = "customer_ltv_model"
  project         = var.project_id
  routine_type    = "SCALAR_FUNCTION"
  language        = "SQL"
  
  definition_body = <<-SQL
    CREATE OR REPLACE MODEL `${var.project_id}.${google_bigquery_dataset.ml_models[0].dataset_id}.customer_ltv_model`
    OPTIONS(
      model_type='linear_reg',
      input_label_cols=['total_spent']
    ) AS
    SELECT
      total_orders,
      avg_order_value,
      EXTRACT(DAYOFYEAR FROM last_order_date) as last_order_day,
      total_spent
    FROM `${var.project_id}.${google_bigquery_dataset.analytics.dataset_id}.customer_metrics_mv`
    WHERE total_orders > 1
  SQL
}

resource "google_bigquery_routine" "churn_prediction_model" {
  count           = var.enable_ml ? 1 : 0
  dataset_id      = google_bigquery_dataset.ml_models[0].dataset_id
  routine_id      = "churn_prediction_model"
  project         = var.project_id
  routine_type    = "SCALAR_FUNCTION"
  language        = "SQL"
  
  definition_body = <<-SQL
    CREATE OR REPLACE MODEL `${var.project_id}.${google_bigquery_dataset.ml_models[0].dataset_id}.churn_prediction_model`
    OPTIONS(
      model_type='logistic_reg',
      input_label_cols=['is_churned']
    ) AS
    SELECT
      total_orders,
      avg_order_value,
      DATE_DIFF(CURRENT_DATE(), DATE(last_order_date), DAY) as days_since_last_order,
      CASE 
        WHEN DATE_DIFF(CURRENT_DATE(), DATE(last_order_date), DAY) > 90 THEN 1 
        ELSE 0 
      END as is_churned
    FROM `${var.project_id}.${google_bigquery_dataset.analytics.dataset_id}.customer_metrics_mv`
  SQL
}