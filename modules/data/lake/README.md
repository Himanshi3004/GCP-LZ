# Data Lake Module

Implements centralized data lake setup with Cloud Storage buckets, BigQuery datasets, Dataflow ETL pipelines, Pub/Sub topics for streaming, Cloud Composer for orchestration, and data classification.

## Features

- **Cloud Storage**: Multi-tier storage with lifecycle policies (raw, processed, archive)
- **BigQuery**: Datasets for data lake and staging with partitioning and clustering
- **Dataflow**: Streaming and batch ETL pipelines
- **Pub/Sub**: Topics and subscriptions for real-time data ingestion
- **Cloud Composer**: Airflow-based orchestration for data workflows
- **Data Classification**: Automated data tier management

## Usage

```hcl
module "data_lake" {
  source = "./modules/data/lake"
  
  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  
  enable_composer = true
  
  storage_classes = {
    raw       = "STANDARD"
    processed = "NEARLINE"
    archive   = "COLDLINE"
  }
  
  retention_days = {
    raw       = 30
    processed = 90
    archive   = 365
  }
  
  labels = {
    environment = "prod"
    team        = "data"
  }
}
```

## Requirements

- Cloud Storage API enabled
- BigQuery API enabled
- Dataflow API enabled
- Pub/Sub API enabled
- Cloud Composer API enabled
- Appropriate IAM permissions

## Outputs

- `storage_buckets`: Data lake storage bucket names by tier
- `bigquery_datasets`: BigQuery dataset IDs
- `pubsub_topics`: Pub/Sub topic names
- `dataflow_jobs`: Dataflow job names
- `composer_environment`: Cloud Composer environment name
- `service_account_email`: Data lake service account email