# Security Command Center (SCC) Module

This module configures Google Cloud Security Command Center for centralized security monitoring, compliance tracking, and automated remediation.

## Features

- **Security Command Center Premium**: Enables advanced security monitoring
- **Custom Security Sources**: Configurable security data sources
- **Automated Findings Processing**: Cloud Function for finding remediation
- **Compliance Monitoring**: Built-in support for SOC2, ISO27001, PCI-DSS, NIST
- **Real-time Notifications**: Pub/Sub, email, and Slack notifications
- **Compliance Dashboard**: Monitoring dashboard for security metrics
- **Organization Policies**: Automated policy enforcement
- **BigQuery Integration**: Security data warehouse for analytics

## Usage

```hcl
module "security_command_center" {
  source = "./modules/security/scc"

  project_id      = "my-security-project"
  organization_id = "123456789012"
  
  enable_premium_tier = true
  
  notification_config = {
    email_addresses = ["security-team@company.com"]
    slack_webhook   = "https://hooks.slack.com/services/..."
  }
  
  compliance_standards = ["CIS", "PCI-DSS", "SOC2"]
  severity_threshold   = "MEDIUM"
  auto_remediation_enabled = true
  
  custom_modules = [
    {
      name           = "custom-security-module"
      display_name   = "Custom Security Module"
      enablement_state = "ENABLED"
    }
  ]
  
  finding_filters = [
    {
      name        = "ignore-test-resources"
      description = "Ignore findings from test resources"
      filter      = "resource.name:\"test-*\""
    }
  ]
  
  tags = {
    Environment = "production"
    Team        = "security"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| google | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| google | >= 4.0 |
| archive | n/a |

## Resources Created

- Security Command Center organization settings
- Custom security sources and modules
- Notification configurations (Pub/Sub, email, Slack)
- Compliance monitoring dashboard
- BigQuery dataset for security data
- Organization policies for compliance
- Cloud Function for automated remediation
- Alert policies for critical findings
- Service accounts with appropriate permissions

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | The GCP project ID where SCC will be configured | `string` | n/a | yes |
| organization_id | The GCP organization ID | `string` | n/a | yes |
| enable_premium_tier | Enable Security Command Center Premium tier | `bool` | `true` | no |
| notification_config | Configuration for security notifications | `object` | `{}` | no |
| custom_modules | Custom Security Command Center modules to enable | `list(object)` | `[]` | no |
| finding_filters | Filters for security findings | `list(object)` | `[]` | no |
| compliance_standards | Compliance standards to monitor | `list(string)` | `["CIS", "PCI-DSS", "NIST", "ISO27001"]` | no |
| auto_remediation_enabled | Enable automated remediation for security findings | `bool` | `false` | no |
| severity_threshold | Minimum severity level for notifications | `string` | `"MEDIUM"` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| scc_organization_settings | Security Command Center organization settings |
| notification_config_id | Security Command Center notification configuration ID |
| pubsub_topic_name | Pub/Sub topic name for SCC findings |
| custom_sources | Custom SCC sources created |
| custom_modules | Custom SCC modules created |
| compliance_dashboard_url | URL to the compliance monitoring dashboard |
| bigquery_dataset | BigQuery dataset for compliance data |
| service_account_email | Service account email for SCC operations |

## Security Features

### Organization Policies
- Require Shielded VMs
- Require OS Login
- Uniform bucket-level access
- Restrict public IP for Cloud SQL

### Compliance Standards
- **CIS**: Center for Internet Security benchmarks
- **PCI-DSS**: Payment Card Industry Data Security Standard
- **SOC2**: Service Organization Control 2
- **ISO27001**: International Organization for Standardization
- **NIST**: National Institute of Standards and Technology

### Automated Remediation
When enabled, the module deploys a Cloud Function that can automatically remediate common security findings:
- Disable public access on storage buckets
- Enable audit logging
- Apply security patches
- Update firewall rules

## Monitoring and Alerting

### Dashboards
- Security findings by severity
- Compliance status by standard
- Resource security posture
- Remediation metrics

### Alerts
- Critical security findings
- Compliance violations
- Failed remediation attempts
- Unusual security activity

## Best Practices

1. **Enable Premium Tier**: Use SCC Premium for advanced threat detection
2. **Configure Notifications**: Set up multiple notification channels
3. **Regular Reviews**: Schedule weekly security reviews
4. **Automated Remediation**: Enable for non-critical findings
5. **Compliance Monitoring**: Track compliance metrics continuously
6. **Custom Modules**: Create organization-specific security rules

## Troubleshooting

### Common Issues

1. **API Not Enabled**: Ensure Security Command Center API is enabled
2. **Permissions**: Verify service account has required roles
3. **Organization Access**: Confirm organization-level permissions
4. **Notification Failures**: Check Pub/Sub topic permissions

### Validation Commands

```bash
# Check SCC status
gcloud scc sources list --organization=ORGANIZATION_ID

# Validate findings
gcloud scc findings list --organization=ORGANIZATION_ID

# Test notifications
gcloud pubsub topics publish TOPIC_NAME --message="test"
```

## Cost Considerations

- Security Command Center Premium has usage-based pricing
- BigQuery storage costs for security data
- Cloud Function execution costs for remediation
- Pub/Sub message costs for notifications

## Compliance Mapping

| Control | Implementation |
|---------|----------------|
| Access Control | IAM policies and OS Login |
| Data Protection | Encryption and DLP policies |
| Network Security | VPC controls and firewall rules |
| Monitoring | Continuous security monitoring |
| Incident Response | Automated finding processing |

## Support

For issues with this module:
1. Check the troubleshooting section
2. Review GCP Security Command Center documentation
3. Contact the security team