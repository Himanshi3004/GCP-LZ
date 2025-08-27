# IAM Foundation Module

## Overview

The IAM Foundation Module provides comprehensive identity and access management for the GCP Landing Zone, implementing least-privilege access controls, group-based RBAC, and advanced service account lifecycle management.

## Features

### Custom Roles (Task 3.1.1)
- **Viewer Plus Roles**: Enhanced viewer roles with specific additional permissions
- **Deployment Roles**: Specialized roles for CI/CD and Terraform deployments  
- **Break-glass Roles**: Emergency access roles for incident response
- **Role Versioning**: Automated versioning and lifecycle management

### Group-Based Access Control (Task 3.2)
- **Hierarchical Groups**: Platform, organization, and environment-specific groups
- **Specialized Groups**: Security, network, data, billing, and emergency response teams
- **Nested Memberships**: Automatic group hierarchy management
- **Environment Isolation**: Separate access controls per environment

### Service Account Management (Task 3.3)
- **Naming Standards**: Consistent naming conventions across all service accounts
- **Key Rotation**: Automated key rotation policies and scheduling
- **Impersonation Chains**: Secure service account impersonation for CI/CD
- **Usage Tracking**: Comprehensive audit logging and analytics
- **Workload Identity**: Full GKE and external workload identity configuration

### Role Testing Framework (Task 3.1.2)
- **Permission Validation**: Automated validation against least-privilege principles
- **Usage Analytics**: BigQuery-based role and permission usage analysis
- **Least-Privilege Analysis**: Identification of unused and overly broad permissions
- **Automated Reporting**: Weekly analysis reports and dashboards

## Architecture

```
IAM Module
├── Custom Roles
│   ├── Administrative (network_admin, project_creator)
│   ├── Viewer Plus (monitoring_viewer_plus, compute_viewer_plus)
│   ├── Deployment (ci_cd_deployer, terraform_deployer)
│   ├── Emergency (emergency_responder, emergency_network_admin)
│   └── Specialized (data_analyst, security_reviewer)
├── Groups
│   ├── Administrative (platform-admins, org-admins, env-admins)
│   ├── Development (env-developers, env-viewers)
│   ├── Specialized (security-team, network-admins, data-engineers)
│   └── Emergency (emergency-responders)
├── Service Accounts
│   ├── Workload Identity (per project)
│   ├── Application Specific (configurable)
│   ├── CI/CD (per environment)
│   └── System (monitoring, security)
└── Testing Framework
    ├── Role Validator (Cloud Function)
    ├── Usage Analytics (BigQuery)
    └── Monitoring (Alerts & Dashboards)
```

## Usage

### Basic Configuration

```hcl
module "iam" {
  source = "./modules/iam"
  
  organization_id   = var.organization_id
  organization_name = var.organization_name
  domain_name      = var.domain_name
  environment      = var.environment
  projects         = module.project_factory.projects
  
  # Enable advanced features
  enable_workload_identity = true
  enable_key_rotation     = true
  enable_role_testing     = true
}
```

### Advanced Configuration

```hcl
module "iam" {
  source = "./modules/iam"
  
  # ... basic configuration ...
  
  # Custom groups configuration
  groups = {
    "platform-admins" = {
      display_name = "Platform Administrators"
      description  = "Full platform access"
      members      = ["admin1@company.com", "admin2@company.com"]
      roles        = ["roles/owner"]
    }
    "security-team" = {
      display_name = "Security Team"
      description  = "Security and compliance"
      members      = ["security@company.com"]
      roles        = ["roles/securitycenter.admin"]
    }
  }
  
  # Application service accounts
  application_service_accounts = {
    "web-app" = {
      project      = "app"
      display_name = "Web Application SA"
      description  = "Service account for web application"
      roles        = ["roles/cloudsql.client"]
    }
  }
  
  # Role testing configuration
  custom_roles_config = {
    enable_versioning = true
    role_prefix      = "custom"
    default_stage    = "GA"
  }
}
```

## Variables

### Required Variables
- `organization_id` - GCP Organization ID
- `domain_name` - Organization domain name for groups
- `environment` - Environment name (dev/staging/prod)

### Optional Variables
- `organization_name` - Organization name for resource naming (default: "company")
- `customer_id` - Google Cloud Identity customer ID
- `projects` - Projects from project factory module
- `folder_ids` - Folder IDs for environment-specific bindings
- `enable_workload_identity` - Enable workload identity (default: true)
- `enable_key_rotation` - Enable service account key rotation (default: true)
- `enable_role_testing` - Enable role testing framework (default: true)

### Advanced Configuration Variables
- `groups` - Custom groups configuration
- `application_service_accounts` - Application-specific service accounts
- `custom_roles_config` - Custom role settings
- `service_account_settings` - Service account lifecycle settings
- `conditional_access_settings` - Time-based and conditional access
- `audit_settings` - Audit and monitoring configuration

## Outputs

### Custom Roles
- `custom_roles` - All custom IAM roles created
- `role_versions` - Role version tracking information

### Groups
- `admin_groups` - Administrative groups (platform, org admins)
- `environment_groups` - Environment-specific groups (dev, staging, prod)
- `specialized_groups` - Specialized groups (security, network, data, billing)

### Service Accounts
- `workload_identity_service_accounts` - Workload identity service accounts
- `application_service_accounts` - Application-specific service accounts
- `cicd_service_accounts` - CI/CD service accounts
- `monitoring_service_account` - Monitoring service account
- `security_service_account` - Security service account

### Configuration
- `workload_identity_pool` - Workload identity pool configuration
- `organization_bindings_summary` - Summary of IAM bindings
- `service_account_inventory` - Service account inventory location

### Audit & Monitoring
- `iam_audit_sink` - IAM audit log sink
- `iam_binding_audit_sink` - IAM binding changes audit sink

## Security Features

### Least Privilege Access
- Custom roles with minimal required permissions
- Regular permission usage analysis
- Automated unused permission detection

### Conditional Access
- Time-based access restrictions
- Environment-specific access controls
- Emergency access procedures

### Audit & Compliance
- Comprehensive audit logging
- Real-time monitoring and alerting
- Compliance reporting and dashboards

### Service Account Security
- Automatic key rotation
- Usage tracking and analytics
- Impersonation chain controls
- Deny policies for critical accounts

## Monitoring & Alerting

### Built-in Alerts
- Suspicious service account activity
- Unused role permissions
- Emergency access usage
- IAM binding changes

### Analytics Dashboards
- Role usage patterns
- Permission utilization
- Security compliance metrics
- Cost optimization insights

## Best Practices

### Group Management
1. Use nested groups for hierarchical access
2. Follow naming conventions: `{env}-{role}@domain.com`
3. Regular group membership reviews
4. Automated group provisioning

### Custom Roles
1. Start with minimal permissions
2. Regular permission audits
3. Version control for role changes
4. Document role purposes and usage

### Service Accounts
1. One service account per application/service
2. Regular key rotation
3. Avoid service account keys when possible
4. Use workload identity for GKE workloads

## Troubleshooting

### Common Issues
1. **Group Creation Failures**: Verify customer_id and domain_name
2. **Permission Denied**: Check organization-level IAM permissions
3. **Workload Identity Issues**: Verify GKE cluster configuration
4. **Role Testing Failures**: Check BigQuery dataset permissions

### Validation Commands
```bash
# Validate custom roles
gcloud iam roles list --organization=ORGANIZATION_ID --filter="name:custom"

# Check group memberships
gcloud identity groups memberships list --group-email=GROUP_EMAIL

# Verify service account keys
gcloud iam service-accounts keys list --iam-account=SA_EMAIL
```

## Migration Guide

### From Basic IAM
1. Update module configuration with new variables
2. Run `terraform plan` to review changes
3. Apply changes in non-production first
4. Migrate groups and service accounts gradually

### Role Migration
1. Audit existing roles and permissions
2. Map to new custom roles
3. Test in development environment
4. Gradual rollout with monitoring

## Contributing

1. Follow Terraform best practices
2. Update documentation for changes
3. Add tests for new features
4. Validate security implications

---

**Last Updated**: 2025-01-28  
**Module Version**: 2.0.0  
**Terraform Version**: >= 1.5  
**Provider Version**: google >= 4.84.0