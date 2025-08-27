# Serverless Platform Module

Implements serverless compute setup with Cloud Run, Cloud Functions, App Engine, service-to-service authentication, Cloud Scheduler, and Cloud Tasks.

## Features

- **Cloud Run**: Containerized serverless applications with custom domains
- **Cloud Functions**: Event-driven serverless functions with VPC connector
- **App Engine**: Fully managed serverless platform
- **Service Authentication**: OIDC-based service-to-service authentication
- **Cloud Scheduler**: Cron job scheduling for automation
- **Cloud Tasks**: Asynchronous task processing with queues

## Usage

```hcl
module "serverless" {
  source = "./modules/compute/serverless"
  
  project_id = var.project_id
  region     = var.region
  network    = var.network_name
  
  enable_cloud_run       = true
  enable_cloud_functions = true
  enable_app_engine      = false
  enable_scheduler       = true
  enable_tasks          = true
  
  custom_domains = [
    "api.example.com",
    "app.example.com"
  ]
  
  labels = {
    environment = "prod"
    team        = "platform"
  }
}
```

## Requirements

- Cloud Run API enabled
- Cloud Functions API enabled
- App Engine API enabled (if using App Engine)
- Cloud Scheduler API enabled
- Cloud Tasks API enabled
- VPC Access API enabled
- VPC network for connector

## Outputs

- `cloud_run_url`: Cloud Run service URL
- `cloud_function_url`: Cloud Function trigger URL
- `app_engine_url`: App Engine application URL
- `vpc_connector_name`: VPC Access Connector name
- `service_account_email`: Serverless service account email
- `task_queues`: Cloud Tasks queue names
- `scheduler_jobs`: Cloud Scheduler job names