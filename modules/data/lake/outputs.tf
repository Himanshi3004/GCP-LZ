# Storage outputs
output "storage_buckets" {
  description = "Data lake storage bucket names"
  value       = { for k, v in google_storage_bucket.data_lake_buckets : k => v.name }
}

output "storage_bucket_urls" {
  description = "Data lake storage bucket URLs"
  value       = { for k, v in google_storage_bucket.data_lake_buckets : k => v.url }
}

output "dataflow_temp_bucket" {
  description = "Dataflow temporary storage bucket"
  value       = google_storage_bucket.dataflow_temp.name
}

output "dataflow_staging_bucket" {
  description = "Dataflow staging storage bucket"
  value       = google_storage_bucket.dataflow_staging.name
}

output "dataflow_templates_bucket" {
  description = "Dataflow templates storage bucket"
  value       = google_storage_bucket.dataflow_templates.name
}

output "access_logs_bucket" {
  description = "Access logs storage bucket"
  value       = google_storage_bucket.access_logs.name
}

# BigQuery outputs
output "bigquery_datasets" {
  description = "BigQuery dataset IDs"
  value = {
    data_lake = try(google_bigquery_dataset.data_lake.dataset_id, null)
    staging   = try(google_bigquery_dataset.staging.dataset_id, null)
  }
}

# Pub/Sub outputs
output "pubsub_topics" {
  description = "Pub/Sub topic names"
  value       = { for k, v in google_pubsub_topic.data_topics : k => v.name }
}

output "pubsub_topic_ids" {
  description = "Pub/Sub topic IDs"
  value       = { for k, v in google_pubsub_topic.data_topics : k => v.id }
}

output "dead_letter_topics" {
  description = "Dead letter topic names"
  value       = { for k, v in google_pubsub_topic.dead_letter_topics : k => v.name }
}

output "pubsub_subscriptions" {
  description = "Pub/Sub subscription names"
  value       = { for k, v in google_pubsub_subscription.data_subscriptions : k => v.name }
}

output "pubsub_schemas" {
  description = "Pub/Sub schema names"
  value       = { for k, v in google_pubsub_schema.schemas : k => v.name }
}

# Dataflow outputs
output "streaming_pipelines" {
  description = "Streaming Dataflow pipeline names"
  value       = { for k, v in google_dataflow_job.streaming_pipelines : k => v.name }
}

output "batch_pipelines" {
  description = "Batch Dataflow pipeline names"
  value       = { for k, v in google_dataflow_job.batch_pipelines : k => v.name }
}

output "flex_pipelines" {
  description = "Flex template Dataflow pipeline names"
  value       = { for k, v in google_dataflow_flex_template_job.flex_pipelines : k => v.name }
}

# Dataproc outputs
output "dataproc_clusters" {
  description = "Dataproc cluster names"
  value       = { for k, v in google_dataproc_cluster.processing_clusters : k => v.name }
}

output "dataproc_cluster_urls" {
  description = "Dataproc cluster URLs"
  value       = { for k, v in google_dataproc_cluster.processing_clusters : k => "https://console.cloud.google.com/dataproc/clusters/details/${var.region}/${v.name}?project=${var.project_id}" }
}

output "dataproc_jobs" {
  description = "Dataproc job names"
  value       = { for k, v in google_dataproc_job.scheduled_jobs : k => v.reference[0].job_id }
}

# Composer outputs
output "composer_environments" {
  description = "Cloud Composer environment names"
  value       = { for k, v in google_composer_environment.data_orchestration : k => v.name }
}

output "composer_environment_urls" {
  description = "Cloud Composer environment URLs"
  value = { 
    for k, v in google_composer_environment.data_orchestration : 
    k => "https://console.cloud.google.com/composer/environments/detail/${var.region}/${v.name}?project=${var.project_id}"
  }
}

output "composer_airflow_urls" {
  description = "Airflow web server URLs"
  value = { 
    for k, v in google_composer_environment.data_orchestration : 
    k => v.config[0].airflow_uri
  }
}

output "composer_dag_buckets" {
  description = "Composer DAG storage buckets"
  value = { 
    for k, v in google_composer_environment.data_orchestration : 
    k => split("/", v.config[0].dag_gcs_prefix)[2]
  }
}

# Service account outputs
output "service_account_email" {
  description = "Data lake service account email"
  value       = google_service_account.data_lake.email
}

output "service_account_id" {
  description = "Data lake service account ID"
  value       = google_service_account.data_lake.id
}

output "service_account_unique_id" {
  description = "Data lake service account unique ID"
  value       = google_service_account.data_lake.unique_id
}

# Configuration outputs
output "data_lake_config" {
  description = "Data lake configuration summary"
  value = {
    project_id   = var.project_id
    region       = var.region
    environment  = var.environment
    storage_classes = var.storage_classes
    retention_days  = var.retention_days
    data_classification = var.data_classification
  }
}

output "processing_config" {
  description = "Data processing configuration summary"
  value = {
    streaming_pipelines_count = length(var.streaming_pipelines)
    batch_pipelines_count     = length(var.batch_pipelines)
    flex_pipelines_count      = length(var.flex_pipelines)
    dataproc_clusters_count   = length(var.dataproc_clusters)
    composer_environments_count = length(var.composer_environments)
    pubsub_topics_count       = length(var.pubsub_topics)
    pubsub_subscriptions_count = length(var.pubsub_subscriptions)
  }
}