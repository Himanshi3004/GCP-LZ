# Policy as Code Module

This module implements comprehensive policy as code capabilities for the GCP Landing Zone, providing automated policy enforcement, compliance monitoring, and remediation.

## Features

### Policy Enforcement
- **OPA (Open Policy Agent) Integration**: Comprehensive policy validation using Rego
- **Terraform Plan Validation**: Automatic validation of infrastructure changes
- **Deployment Blocking**: Prevent non-compliant deployments
- **Policy Testing**: Automated testing of policy rules

### Compliance Automation
- **Continuous Compliance**: Scheduled compliance scanning
- **Drift Detection**: Automated detection of configuration drift
- **Auto-Remediation**: Automatic fixing of common violations
- **Compliance Reporting**: Detailed compliance reports and dashboards

### 🔍 Monitoring & Alerting
- **Real-time Alerts**: Immediate notification of policy violations
- **BigQuery Integration**: Centralized compliance data storage
- **Security Command Center**: Integration with GCP SCC
- **Custom Dashboards**: Compliance and security dashboards

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │───▶│  Cloud Build    │───▶│ Policy Bundle   │
│   (Policies)    │    │  (CI/CD)        │    │ (Cloud Storage) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Terraform      │───▶│ Policy Enforcer │───▶│   BigQuery      │
│  Plan Events    │    │ (Cloud Function)│    │ (Violations)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Auto-Remediation│◀───│   Pub/Sub       │───▶│  Notifications  │
│ (Cloud Function)│    │   Topics        │    │   (Alerts)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Policy Categories

### Security Policies (`security_enhanced.rego`)
- **Resource Labeling**: Enforce security classification labels
- **Encryption**: Require CMEK for all storage resources
- **Network Security**: Private clusters, restricted firewall rules
- **Compute Security**: OS Login, Shielded VM requirements
- **IAM Security**: Conditional access for sensitive roles

### Cost Governance (`cost_governance.rego`)
- **Resource Sizing**: Prevent oversized resources in non-production
- **Budget Controls**: Require budget alerts for all projects
- **Lifecycle Management**: Enforce lifecycle policies for storage
- **Committed Use**: Require CUD for production workloads
- **Cost Allocation**: Enforce cost center labeling

### Compliance Policies (`compliance.rego`)
- **CIS GCP Benchmark**: Automated CIS controls enforcement
- **Corporate Standards**: Domain-specific compliance rules
- **Data Protection**: SQL encryption and access controls
- **Network Controls**: Default network restrictions

## Usage

### Basic Configuration

```hcl
module "policy" {
  source = "./modules/policy"

  project_id       = var.project_id
  region          = var.region
  source_repo_url = "https://source.developers.google.com/p/my-project/r/landing-zone"
  
  # Policy frameworks to enforce
  policy_frameworks = ["cis", "nist", "pci-dss"]
  
  # Enable features
  enable_drift_detection = true
  auto_remediation_enabled = true
  
  # Notification channels
  notification_channels = [
    "projects/my-project/notificationChannels/123456789"
  ]
  
  # Policy violation actions
  policy_violation_actions = {
    block_deployment   = true
    send_notification = true
    create_ticket     = false
    auto_remediate    = true
  }
}
```

### Advanced Configuration

```hcl
module "policy" {
  source = "./modules/policy"

  project_id       = var.project_id
  region          = var.region
  organization_id = var.organization_id
  
  # GitHub integration for policy CI/CD
  github_owner = "my-org"
  github_repo  = "gcp-policies"
  
  # Compliance frameworks with specific controls
  compliance_frameworks = {
    "cis-gcp" = {
      enabled  = true
      controls = ["1.1", "1.4", "2.2", "3.1", "3.6", "4.1", "4.2"]
      severity = "high"
    }
    "nist-800-53" = {
      enabled  = true
      controls = ["AC-2", "AC-3", "AU-2", "AU-3", "SC-7"]
      severity = "medium"
    }
  }
  
  # Policy exceptions for specific resources
  policy_exceptions = {
    "legacy-system" = {
      resource_pattern = "google_compute_instance.legacy-*"
      policy_names     = ["security.require_oslogin"]
      justification    = "Legacy system migration in progress"
      expiry_date      = "2024-12-31"
    }
  }
  
  # Schedules
  drift_detection_schedule = "0 2 * * *"  # Daily at 2 AM
  compliance_check_schedule = "0 */6 * * *"  # Every 6 hours
  
  # Enable SCC integration
  enable_scc_notifications = true
  
  labels = {
    environment = "prod"
    team        = "platform"
  }
}
```

## Policy Development

### Writing Policies

Policies are written in Rego (OPA's policy language):

```rego
package terraform.security.enhanced

import rego.v1

# Deny resources without proper security labels
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type in ["google_compute_instance", "google_storage_bucket"]
    not resource.change.after.labels.security_classification
    msg := sprintf("Resource %s must have security_classification label", [resource.address])
}
```

### Testing Policies

Write tests for your policies:

```rego
package terraform.security.enhanced

import rego.v1

test_security_classification_required if {
    deny[_] with input as {
        "resource_changes": [{
            "address": "google_compute_instance.test",
            "type": "google_compute_instance",
            "change": {
                "after": {
                    "labels": {}
                }
            }
        }]
    }
}
```

### Policy CI/CD Workflow

1. **Development**: Write policies in `modules/policy/policies/`
2. **Testing**: Add tests in `modules/policy/tests/`
3. **Pull Request**: Automated policy testing on PR
4. **Merge**: Automatic policy bundle deployment
5. **Enforcement**: Real-time policy enforcement on Terraform plans

## Auto-Remediation

The module supports automatic remediation of common violations:

### Supported Remediations
- **Missing Labels**: Add required security and cost labels
- **Public IPs**: Remove public IPs from production instances
- **Open Firewalls**: Restrict overly permissive firewall rules
- **Unencrypted Storage**: Enable CMEK encryption
- **SQL Public Access**: Disable public IP for Cloud SQL
- **Missing Backups**: Enable backup for Cloud SQL instances

### Custom Remediations

Add custom remediation functions in `functions/auto_remediation.py`:

```python
def remediate_custom_violation(resource_info, violation):
    """
    Custom remediation logic
    """
    # Implementation here
    return {
        'violation': violation,
        'status': 'remediated',
        'action': 'custom_action',
        'resource': resource_info['name']
    }
```

## Monitoring and Reporting

### BigQuery Tables
- `compliance_data.policy_violations`: All policy violations
- `compliance_data.remediation_history`: Remediation actions
- `compliance_data.compliance_reports`: Daily compliance reports

### Dashboards
Access pre-built dashboards for:
- Policy violation trends
- Compliance posture
- Remediation effectiveness
- Cost governance metrics

### Alerts
Configured alerts for:
- High-severity policy violations
- Failed remediations
- Compliance drift
- Policy deployment failures

## Compliance Frameworks

### CIS GCP Benchmark
Automated enforcement of CIS controls:
- 1.1: Corporate login credentials
- 1.4: Service account key management
- 2.2: Cloud SQL public IP restrictions
- 3.1: Default network deletion
- 3.6: SSH access restrictions
- 4.1: Default service account usage
- 4.2: Service account scope restrictions

### NIST 800-53
Selected controls implementation:
- AC-2: Account Management
- AC-3: Access Enforcement
- AU-2: Audit Events
- AU-3: Content of Audit Records
- SC-7: Boundary Protection

### Custom Frameworks
Add your own compliance frameworks by:
1. Creating policy files in `policies/`
2. Adding framework configuration in variables
3. Updating compliance reporting queries

## Troubleshooting

### Common Issues

1. **Policy Validation Failures**
   ```bash
   # Test policies locally
   opa test modules/policy/policies/ modules/policy/tests/
   ```

2. **Remediation Failures**
   ```bash
   # Check Cloud Function logs
   gcloud functions logs read auto-remediation --limit 50
   ```

3. **Missing Permissions**
   ```bash
   # Verify service account permissions
   gcloud projects get-iam-policy PROJECT_ID
   ```

### Debug Mode
Enable debug logging by setting environment variables:
```bash
export DEBUG_POLICY_ENFORCEMENT=true
export LOG_LEVEL=DEBUG
```

## Security Considerations

- **Least Privilege**: Service accounts use minimal required permissions
- **Encryption**: All data encrypted in transit and at rest
- **Audit Trail**: Complete audit trail in Cloud Logging
- **Access Control**: Policy modifications require approval
- **Secret Management**: No hardcoded secrets in policies

## Performance

- **Policy Evaluation**: < 30 seconds for typical Terraform plans
- **Remediation**: < 5 minutes for common violations
- **Compliance Scanning**: Scales with infrastructure size
- **Storage**: Efficient BigQuery partitioning for large datasets

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add policies and tests
4. Submit a pull request
5. Automated testing validates changes

## Support

For issues and questions:
- Check the troubleshooting section
- Review Cloud Function logs
- Contact the platform team
- Create GitHub issues for bugs

---

**Last Updated**: 2024-01-15
**Version**: 2.0.0
**Maintainer**: Platform Engineering Team