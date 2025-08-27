# Data Warehouse Module

Implements analytics platform setup with BigQuery slot reservations, BI Engine, materialized views, scheduled queries, BigQuery ML models, and row-level security.

## Features

- **BigQuery Datasets**: Analytics and ML model datasets
- **Slot Reservations**: Dedicated compute capacity with monthly commitments
- **BI Engine**: In-memory analytics acceleration
- **Materialized Views**: Pre-computed aggregations for performance
- **Scheduled Queries**: Automated data processing workflows
- **BigQuery ML**: Customer LTV and churn prediction models
- **Row-Level Security**: Regional data access controls

## Usage

```hcl
module "warehouse" {
  source = "./modules/data/warehouse"
  
  project_id = var.project_id
  region     = var.region
  
  enable_slot_reservations = true
  slot_capacity           = 100
  
  enable_bi_engine         = true
  bi_engine_memory_size_gb = 2
  
  enable_ml = true
  
  labels = {
    environment = "prod"
    team        = "analytics"
  }
}
```

## Requirements

- BigQuery API enabled
- BigQuery Reservation API enabled
- Appropriate IAM permissions for data transfer
- Source datasets for materialized views and ML models

## Outputs

- `analytics_dataset_id`: Analytics dataset ID
- `ml_dataset_id`: ML models dataset ID
- `reservation_name`: BigQuery reservation name
- `bi_engine_reservation_id`: BI Engine reservation ID
- `materialized_views`: Materialized view names
- `scheduled_queries`: Scheduled query names
- `service_account_email`: Warehouse service account email