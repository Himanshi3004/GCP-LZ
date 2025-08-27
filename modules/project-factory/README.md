# Project Factory Module

## Overview
Enhanced project factory module that provides comprehensive project creation with type-specific configurations, advanced budget controls, quota management, and lifecycle management features.

## Features

### Project Types
- **shared-vpc-host**: Networking infrastructure projects
- **application**: Application workload projects  
- **data**: Data platform projects
- **security**: Security and compliance projects
- **tooling**: DevOps and tooling projects

### Budget Management
- Multi-threshold budget alerts (50%, 80%, 100%)
- Forecast-based budget monitoring
- Email and Pub/Sub notifications
- Service-specific budget filters

### Quota Management
- Project type-specific quota defaults
- Quota usage monitoring and alerts
- Automated quota threshold notifications

### Advanced Configuration
- Essential contacts per project type
- Project deletion protection (liens)
- Organization policy exceptions
- Automated project documentation

## Variables

### Core Variables
- `organization_id` - GCP organization ID
- `billing_account` - Billing account ID
- `folders` - Folder hierarchy from organization module
- `environment` - Environment name
- `name_prefix` - Naming prefix for projects
- `default_region` - Default region for resources
- `labels` - Labels to apply to resources
- `projects` - Projects to create with enhanced configuration

### Budget Variables
- `budget_thresholds` - Multi-level budget thresholds
- `budget_notification_emails` - Email addresses for budget alerts
- `budget_pubsub_topic` - Pub/Sub topic for budget notifications
- `enable_forecast_alerts` - Enable forecast-based alerts
- `forecast_budget_multiplier` - Multiplier for forecast budgets
- `forecast_threshold_percent` - Forecast alert threshold

### Quota Variables
- `enable_quota_monitoring` - Enable quota monitoring
- `quota_alert_threshold` - Quota usage alert threshold
- `quota_notification_emails` - Email addresses for quota alerts

### Advanced Variables
- `project_policy_exceptions` - Project-level organization policy exceptions

## Outputs

### Core Outputs
- `projects` - Created projects with details
- `service_accounts` - Service accounts per project
- `project_types` - Project type configurations used

### Budget Outputs
- `budgets` - Budget configurations
- `forecast_budgets` - Forecast budget configurations

### Advanced Outputs
- `essential_contacts` - Essential contacts configured
- `project_liens` - Project deletion protection liens

## Usage Example

```hcl
module "project_factory" {
  source = "./modules/project-factory"
  
  organization_id = var.organization_id
  billing_account = var.billing_account
  folders         = module.organization.folders
  environment     = var.environment
  name_prefix     = var.organization_name
  
  budget_notification_emails = ["finance@company.com", "ops@company.com"]
  quota_notification_emails  = ["ops@company.com"]
  
  projects = {
    "shared-vpc" = {
      department    = "networking"
      apis          = ["compute.googleapis.com", "servicenetworking.googleapis.com"]
      budget_amount = 2000
      budget_filters = {
        services = ["compute.googleapis.com"]
        credit_types_treatment = "EXCLUDE_ALL_CREDITS"
      }
    }
    "application" = {
      department    = "engineering"
      apis          = ["compute.googleapis.com", "container.googleapis.com"]
      budget_amount = 1500
    }
  }
  
  project_policy_exceptions = {
    "allow-external-ip" = {
      project        = "application"
      constraint     = "compute.vmExternalIpAccess"
      type          = "list"
      allowed_values = ["projects/my-project/zones/us-central1-a"]
    }
  }
}
```

## Project Type Configurations

Each project type includes:
- **APIs**: Required APIs for the project type
- **Default Roles**: Standard IAM roles for the type
- **Labels**: Type-specific labels and metadata
- **Budget Multiplier**: Cost scaling factor
- **Essential Contacts**: Default contacts for notifications
- **Deletion Protection**: Whether to apply project liens
- **Criticality Level**: Business criticality classification

## Files Structure

- `main.tf` - Core project creation logic
- `budgets.tf` - Enhanced budget configuration
- `quotas.tf` - Quota management and monitoring
- `project-types.tf` - Project type definitions
- `advanced-config.tf` - Essential contacts, liens, policies
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `templates/project-doc.tpl` - Project documentation template
- `docs/` - Generated project documentation

## Validation

The module includes validation for:
- Valid project types
- Required variables
- Budget threshold ranges
- Email format validation

Generated: 2025-01-28 (Enhanced with Task 2 implementations)