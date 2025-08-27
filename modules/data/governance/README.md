# Data Governance Module

Implements data governance and compliance with Data Catalog, DLP policies, data classification, audit logging, data lineage tracking, and policy enforcement.

## Features

- **Data Catalog**: Taxonomies and policy tags for data classification
- **DLP Policies**: PII detection, inspection, and de-identification templates
- **Data Classification**: Multi-level classification (PUBLIC, INTERNAL, CONFIDENTIAL, RESTRICTED)
- **Audit Logging**: Comprehensive data access logging and monitoring
- **Data Lineage**: Tracking data sources, transformations, and ownership
- **Policy Enforcement**: Organization policies and access controls

## Usage

```hcl
module "governance" {
  source = "./modules/data/governance"
  
  project_id      = var.project_id
  organization_id = var.organization_id
  region          = var.region
  
  enable_dlp          = true
  enable_data_catalog = true
  
  pii_info_types = [
    "EMAIL_ADDRESS",
    "PHONE_NUMBER",
    "CREDIT_CARD_NUMBER",
    "US_SOCIAL_SECURITY_NUMBER"
  ]
  
  data_classification_levels = [
    "PUBLIC",
    "INTERNAL", 
    "CONFIDENTIAL",
    "RESTRICTED"
  ]
  
  labels = {
    environment = "prod"
    team        = "governance"
  }
}
```

## Requirements

- Data Catalog API enabled
- DLP API enabled
- Cloud Logging API enabled
- Organization-level permissions for policy enforcement
- BigQuery datasets for audit logging

## Outputs

- `data_catalog_taxonomies`: Data Catalog taxonomy IDs
- `dlp_templates`: DLP template names
- `audit_dataset_id`: Audit logs dataset ID
- `data_access_sink_name`: Data access audit sink name
- `lineage_tag_template`: Data lineage tag template ID
- `service_account_email`: Governance service account email