# Compliance Framework Module

This module implements comprehensive compliance controls including Assured Workloads, VPC Service Controls, Access Context Manager, and Binary Authorization.

## Features

- **Assured Workloads**: Regulated industry compliance (FedRAMP, HIPAA, etc.)
- **VPC Service Controls**: Data perimeter security
- **Access Context Manager**: Device and location-based access controls
- **Binary Authorization**: Container image security verification

## Usage

```hcl
module "compliance" {
  source = "./modules/security/compliance"
  
  project_id                   = var.project_id
  organization_id             = var.organization_id
  region                      = var.region
  enable_assured_workloads    = true
  enable_vpc_service_controls = true
  enable_binary_authorization = true
  compliance_regime           = "FEDRAMP_MODERATE"
  
  restricted_services = [
    "storage.googleapis.com",
    "bigquery.googleapis.com"
  ]
  
  labels = {
    environment = "prod"
    compliance  = "fedramp"
  }
}
```

## Requirements

- Access Context Manager API enabled
- Binary Authorization API enabled
- Assured Workloads API enabled
- Organization-level permissions

## Outputs

- `access_policy_name`: Access Context Manager policy name
- `service_perimeter_name`: VPC Service Controls perimeter name
- `binary_authorization_policy`: Binary Authorization policy name
- `attestor_name`: Binary Authorization attestor name
- `assured_workload_name`: Assured Workloads workload name
- `service_account_email`: Service account email