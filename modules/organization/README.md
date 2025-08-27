# Organization Module

This module creates the foundational organization structure including folders, policies, management project, and naming standards for the GCP Landing Zone.

## Features

### Folder Hierarchy
- **Environment Folders**: dev, staging, prod
- **Department Folders**: security, networking, data, compute, shared-services
- **Team Folders**: platform, application, infrastructure, analytics (under compute and data departments)
- **IAM Bindings**: Environment and department-specific access controls

### Organization Policies
- **Core Security Policies**: VM external IP restrictions, OS Login requirements, Shielded VM enforcement
- **Compliance Policies**: Resource location restrictions, storage policies, service account controls
- **Folder-Level Policies**: Environment-specific and department-specific policy overrides

### Naming Standards
- **Consistent Naming**: Enforced naming conventions across all resources
- **Validation Rules**: Automated validation of resource names
- **Standard Labels**: Consistent labeling for cost allocation and governance

### Management Project
- **Centralized Management**: Single project for organization-level resources
- **API Enablement**: Required APIs for organization management
- **Audit Logging**: Organization-wide audit log collection

## Usage

```hcl
module "organization" {
  source = "./modules/organization"

  organization_id   = "123456789012"
  billing_account   = "ABCDEF-123456-GHIJKL"
  organization_name = "netskope"
  domain_name       = "netskope.com"
  environment       = "prod"
  
  enable_audit_logs            = true
  enable_organization_policies = true
  
  allowed_regions = ["us-central1", "us-east1"]
  prod_allowed_regions = ["us-central1"]
  
  labels = {
    managed_by = "terraform"
    project    = "gcp-landing-zone"
  }
}
```

## Folder Structure

```
Organization (netskope)
├── netskope-dev/
│   ├── security/
│   ├── networking/
│   ├── data/
│   │   ├── platform/
│   │   ├── application/
│   │   ├── infrastructure/
│   │   └── analytics/
│   ├── compute/
│   │   ├── platform/
│   │   ├── application/
│   │   ├── infrastructure/
│   │   └── analytics/
│   └── shared-services/
├── netskope-staging/
│   └── [same structure as dev]
└── netskope-prod/
    └── [same structure as dev]
```

## IAM Structure

### Environment-Level Access
- `netskope-{env}-viewers@netskope.com`: Read-only access to environment folder
- `netskope-{env}-developers@netskope.com`: Billing user access
- `netskope-{env}-admins@netskope.com`: Administrative access

### Department-Level Access
- `netskope-{dept}-admins@netskope.com`: Folder admin access
- `netskope-{dept}-editors@netskope.com`: Folder editor access

### Special Access
- `netskope-security-team@netskope.com`: Security Center admin for security folders
- `netskope-networking-team@netskope.com`: Network admin for networking folders

## Organization Policies

### Core Policies (Organization Level)
- `compute.vmExternalIpAccess`: Deny all external IPs
- `compute.requireOsLogin`: Enforce OS Login
- `compute.requireShieldedVm`: Require Shielded VM
- `iam.disableServiceAccountKeyCreation`: Disable SA key creation
- `storage.uniformBucketLevelAccess`: Enforce uniform bucket access

### Environment-Specific Policies
- **Development**: Relaxed external IP policy for testing
- **Production**: Strict resource location restrictions

### Department-Specific Policies
- **Security Folders**: Enhanced Shielded VM requirements
- **Data Folders**: Strict storage access controls

## Naming Standards

### Patterns
- **Folders**: `{organization}-{environment}`, `{department}`, `{team}`
- **Projects**: `{organization}-{department}-{environment}-{suffix}`
- **Shared Projects**: `{organization}-shared-{environment}-{suffix}`

### Validation Rules
- Maximum length: 30 characters
- Allowed characters: lowercase letters, numbers, hyphens
- Pattern: Must start with letter, end with letter or number

### Standard Labels
- `managed_by`: terraform
- `module`: organization
- `environment`: dev/staging/prod
- `cost_center`: {organization}-{environment}
- `backup_policy`: critical/standard

## Variables

### Required
- `organization_id`: GCP Organization ID
- `billing_account`: Billing Account ID
- `organization_name`: Organization name for resource naming
- `domain_name`: Organization domain name
- `environment`: Environment name (dev/staging/prod)

### Optional
- `enable_audit_logs`: Enable audit logging (default: true)
- `enable_organization_policies`: Enable organization policies (default: true)
- `allowed_regions`: List of allowed GCP regions
- `prod_allowed_regions`: Production-specific allowed regions
- `allowed_vpn_peer_ips`: Allowed VPN peer IP addresses
- `folder_policies`: Folder-specific organization policies
- `labels`: Labels to apply to resources

## Outputs

- `folders`: Complete folder hierarchy with IDs and metadata
- `organization_policies`: Applied organization policies
- `audit_log_sink`: Audit logging configuration
- `management_project`: Management project details
- `naming_standards`: Naming patterns and validation rules

## Requirements

- GCP Organization Admin permissions
- Billing Account Admin permissions
- Terraform >= 1.5
- Google Provider >= 5.0

Generated: 2025-07-28 06:26:38