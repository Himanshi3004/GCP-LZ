# GCP Landing Zone - Terraform Infrastructure

A production-ready, modular GCP landing zone implementation using Terraform that addresses enterprise requirements including security, compliance, networking, identity management, and operational excellence.

## Architecture Overview

This landing zone implements a hub-and-spoke architecture with the following key components:

- **Organization & Folder Hierarchy**: Structured resource organization
- **Project Factory**: Standardized project creation and management
- **IAM Foundation**: Comprehensive identity and access management
- **Shared VPC**: Centralized networking with security controls
- **Security Command Center**: Centralized security monitoring
- **Observability**: Logging, monitoring, and alerting

## Directory Structure

```
/
├── main.tf                    # Root module orchestration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── versions.tf                # Provider and Terraform version constraints
├── terraform.tfvars.example   # Example configuration
├── README.md                  # This file
├── environments/              # Environment-specific configurations
│   ├── dev/
│   │   ├── backend.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── backend.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── backend.tf
│       └── terraform.tfvars
└── modules/                   # Terraform modules (to be implemented)
    ├── organization/
    ├── project-factory/
    ├── iam/
    ├── networking/
    ├── security/
    └── observability/
```

## Prerequisites

1. **GCP Organization**: You must have a GCP organization set up
2. **Billing Account**: Active billing account with appropriate permissions
3. **Terraform**: Version >= 1.5
4. **GCP CLI**: Authenticated with appropriate permissions
5. **State Storage**: GCS buckets for Terraform state (see Bootstrap section)

## Required Permissions

The service account or user running Terraform needs the following organization-level roles:

- Organization Administrator
- Billing Account Administrator
- Project Creator
- Folder Admin
- Security Admin
- Compute Network Admin

## Bootstrap Process

Before deploying the landing zone, you need to create the GCS buckets for Terraform state:

```bash
# Create state buckets (replace with your organization name)
gsutil mb gs://netskope-terraform-state-dev
gsutil mb gs://netskope-terraform-state-staging
gsutil mb gs://netskope-terraform-state-prod

# Enable versioning
gsutil versioning set on gs://netskope-terraform-state-dev
gsutil versioning set on gs://netskope-terraform-state-staging
gsutil versioning set on gs://netskope-terraform-state-prod
```

## Quick Start

1. **Clone and Configure**:
   ```bash
   cd "GCP LANDING ZONE"
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your organization details
   ```

2. **Initialize for Development**:
   ```bash
   # Copy environment-specific backend config
   cp environments/dev/backend.tf .
   
   terraform init
   terraform plan
   terraform apply
   ```

3. **Deploy to Other Environments**:
   ```bash
   # For staging
   cp environments/staging/backend.tf .
   cp environments/staging/terraform.tfvars .
   terraform init -reconfigure
   terraform apply
   
   # For production
   cp environments/prod/backend.tf .
   cp environments/prod/terraform.tfvars .
   terraform init -reconfigure
   terraform apply
   ```

## Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `organization_id` | GCP Organization ID | `"123456789012"` |
| `billing_account` | Billing Account ID | `"ABCDEF-123456-GHIJKL"` |
| `project_id` | Management project ID | `"netskope-landing-zone-dev"` |
| `environment` | Environment name | `"dev"` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `default_region` | Default GCP region | `"us-central1"` |
| `organization_name` | Organization name | `"netskope"` |
| `enable_audit_logs` | Enable audit logging | `true` |
| `budget_alert_threshold` | Budget alert percentage | `80` |

See `variables.tf` for complete list of configurable options.

## Module Features

### Organization Module
- Folder hierarchy creation
- Organization policies
- Audit logging configuration

### Project Factory
- Standardized project creation
- API enablement
- Service account creation
- Budget alerts

### IAM Foundation
- Custom role definitions
- Group-based access control
- Service account management
- Workload Identity setup

### Networking
- Shared VPC implementation
- Subnet management
- Firewall rules
- Cloud NAT configuration

### Security
- Security Command Center setup
- Data protection policies
- Compliance controls

### Observability
- Centralized logging
- Monitoring dashboards
- Alerting policies

## Environment Strategy

The landing zone supports three environments with different security postures:

- **Development**: Relaxed policies for experimentation
- **Staging**: Production-like with moderate security
- **Production**: Strict security and compliance controls

## Security Features

- Zero-trust network architecture
- Least privilege IAM
- Customer-managed encryption keys
- VPC Service Controls
- Organization policies
- Audit logging
- Security Command Center integration

## Cost Management

- Billing export to BigQuery
- Budget alerts per project
- Resource labeling strategy
- Quota monitoring
- Cost allocation tracking

## Compliance

Built-in controls for common frameworks:
- SOC2
- ISO27001
- PCI-DSS
- GDPR data residency

## Monitoring and Alerting

- Organization-level log sinks
- Custom dashboards
- SLO monitoring
- Budget alerts
- Security notifications

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure service account has required organization-level permissions
2. **State Lock**: Use `terraform force-unlock` if state is locked
3. **API Enablement**: Some APIs may take time to propagate
4. **Quota Limits**: Check project quotas for resource limits

### Validation

```bash
# Validate configuration
terraform validate

# Check formatting
terraform fmt -check

# Security scanning (if tfsec installed)
tfsec .

# Cost estimation (if infracost installed)
infracost breakdown --path .
```

## Contributing

1. Follow Terraform best practices
2. Update documentation for any changes
3. Test in development environment first
4. Use conventional commit messages

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review Terraform and GCP documentation
3. Contact the platform team

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Note**: This is the foundation structure. Individual modules will be implemented in subsequent phases as outlined in the tasks.md file.

Last updated: 2025-07-28 06:26:38
