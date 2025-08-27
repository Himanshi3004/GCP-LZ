# Cost Management Module

This module provides comprehensive cost management, optimization, and FinOps capabilities for GCP Landing Zone deployments.

## Features

### 7.1 Billing Configuration
- **Billing Export**: Automated export to BigQuery and Cloud Storage
- **Cost Views**: Pre-built BigQuery views for cost analysis
- **Cost Allocation**: Label-based cost allocation and tracking
- **Data Retention**: Configurable retention policies for cost data

### 7.2 Cost Optimization
- **Anomaly Detection**: Automated detection of cost spikes and anomalies
- **Rightsizing Recommendations**: Analysis of underutilized resources
- **Idle Resource Detection**: Identification of unused resources
- **Automated Cleanup**: Optional automated cleanup of idle resources

### FinOps Practices
- **Chargeback Reporting**: Detailed cost allocation by team/department
- **Showback Dashboards**: Cost visibility without direct billing
- **Cost Forecasting**: Predictive cost analysis and budgeting
- **Cost Governance**: Policy enforcement and compliance tracking

## Usage

```hcl
module "cost_management" {
  source = "./modules/cost-management"

  project_id      = var.project_id
  billing_account = var.billing_account
  region          = var.region

  # Billing Export Configuration
  enable_billing_export    = true
  enable_storage_export    = true
  billing_data_retention_days = 365

  # Budget Configuration
  enable_budget_alerts         = true
  budget_amount               = 5000
  budget_threshold_percentages = [50, 80, 90, 100]
  enable_forecast_alerts      = true

  # Cost Optimization
  enable_cost_optimization        = true
  enable_rightsizing_recommendations = true
  enable_idle_resource_cleanup    = false
  cost_anomaly_threshold         = 20

  # FinOps Configuration
  enable_finops_practices = true
  chargeback_enabled     = true
  showback_enabled       = true

  # Notifications
  cost_alert_emails = [
    "finance@company.com",
    "devops@company.com"
  ]

  # Cost Allocation Labels
  cost_allocation_labels = {
    team        = "platform"
    environment = "prod"
    cost_center = "engineering"
  }

  labels = var.labels
}
```

## Resources Created

### Core Resources
- BigQuery dataset for billing export
- Cloud Storage bucket for billing data
- Service account for cost management
- Notification channels for alerts

### Budget Resources
- Project-level budget with thresholds
- Service-specific budgets (Compute, Storage)
- Forecast-based budget alerts
- Budget utilization tracking

### Cost Optimization Resources
- Pub/Sub topic for cost alerts
- Cost anomaly detection alerts
- Rightsizing recommendations view
- Idle resource detection view

### FinOps Resources
- Chargeback reporting view
- Showback dashboard data
- Cost forecasting view
- Cost governance alerts

### Dashboards
- Executive cost dashboard
- Operational cost dashboard
- FinOps dashboard

## BigQuery Views

The module creates several BigQuery views for cost analysis:

### Cost Analysis Views
- `cost_by_service`: Cost breakdown by GCP service
- `cost_by_project`: Cost breakdown by project
- `cost_allocation`: Cost allocation by labels

### Optimization Views
- `rightsizing_recommendations`: Resource rightsizing opportunities
- `idle_resources`: Unused resources costing money
- `budget_utilization`: Budget usage tracking

### FinOps Views
- `chargeback_report`: Detailed chargeback data
- `showback_data`: Showback dashboard data
- `cost_forecast`: Cost forecasting and trends

## Monitoring and Alerting

### Budget Alerts
- Threshold-based alerts (50%, 80%, 100%)
- Forecast-based alerts
- Service-specific budget alerts

### Cost Optimization Alerts
- Cost anomaly detection
- Quota usage alerts
- Idle resource alerts

### FinOps Alerts
- Cost governance violations
- Untagged resource alerts
- Budget variance alerts

## Variables

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `project_id` | GCP project ID | string | - |
| `billing_account` | Billing account ID | string | - |
| `region` | GCP region | string | us-central1 |
| `enable_billing_export` | Enable billing export | bool | true |
| `enable_storage_export` | Enable storage export | bool | true |
| `billing_data_retention_days` | Data retention days | number | 365 |
| `enable_budget_alerts` | Enable budget alerts | bool | true |
| `budget_amount` | Monthly budget amount | number | 1000 |
| `enable_forecast_alerts` | Enable forecast alerts | bool | true |
| `enable_cost_optimization` | Enable cost optimization | bool | true |
| `enable_finops_practices` | Enable FinOps practices | bool | true |
| `cost_alert_emails` | Email addresses for alerts | list(string) | [] |

## Outputs

| Output | Description |
|--------|-------------|
| `cost_management_service_account` | Service account details |
| `billing_export` | Billing export configuration |
| `budgets` | Budget configuration |
| `cost_views` | BigQuery views for analysis |
| `cost_optimization` | Optimization resources |
| `finops` | FinOps resources |
| `dashboards` | Dashboard IDs |
| `notification_channels` | Notification channel IDs |

## Best Practices

### Cost Allocation
1. Use consistent labeling strategy
2. Implement label governance policies
3. Regular cost allocation reviews
4. Automated label validation

### Budget Management
1. Set realistic budget thresholds
2. Use forecast-based alerts
3. Service-specific budgets
4. Regular budget reviews

### Cost Optimization
1. Regular rightsizing reviews
2. Automated idle resource cleanup
3. Cost anomaly investigation
4. Optimization tracking

### FinOps Implementation
1. Regular chargeback reporting
2. Cost governance enforcement
3. Stakeholder cost visibility
4. Continuous optimization

## Prerequisites

- GCP project with billing enabled
- BigQuery API enabled
- Cloud Monitoring API enabled
- Appropriate IAM permissions

## Permissions Required

- `roles/billing.viewer`
- `roles/bigquery.dataEditor`
- `roles/monitoring.editor`
- `roles/pubsub.editor`
- `roles/storage.admin`

## Troubleshooting

### Common Issues
1. **Billing export not working**: Check billing account permissions
2. **Budget alerts not firing**: Verify notification channels
3. **Views returning no data**: Check billing export configuration
4. **Cost anomaly false positives**: Adjust threshold values

### Validation
```bash
# Check billing export
bq ls --project_id=${PROJECT_ID} billing_export

# Verify budget configuration
gcloud billing budgets list --billing-account=${BILLING_ACCOUNT}

# Test notification channels
gcloud alpha monitoring channels list --project=${PROJECT_ID}
```