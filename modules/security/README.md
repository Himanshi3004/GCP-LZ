# Security Module

This module provides comprehensive security controls for the GCP Landing Zone, implementing enterprise-grade security features across multiple domains.

## Features

### Security Command Center (SCC)
- **Premium Features**: Vulnerability scanning, compliance scanning, Event Threat Detection
- **Automated Remediation**: Cloud Functions-based auto-remediation with playbooks
- **Custom Findings**: Custom sources, categories, severity mappings, and lifecycle management
- **Monitoring**: Dashboards, alerts, and BigQuery analytics

### Data Protection
- **Cloud KMS**: Environment-specific key rings with HSM support for production
- **Key Management**: Automated rotation, access justification, usage policies
- **Cloud DLP**: Inspection templates, job triggers, data profiles, automatic discovery
- **Encryption**: CMEK for all services, application-layer encryption

### VPC Service Controls
- **Service Perimeters**: Regular and bridge perimeters with ingress/egress policies
- **Access Context Manager**: Device trust, time-based access, IP restrictions
- **Access Levels**: Multi-layered access controls with conditional policies

## Architecture

```
Security Module
├── scc/                    # Security Command Center
│   ├── scc-config.tf      # Premium features configuration
│   ├── scc-remediation.tf # Automated remediation
│   ├── custom-findings.tf # Custom findings management
│   └── templates/         # Remediation playbooks
├── data-protection/       # Data protection controls
│   ├── kms-keys.tf       # Key management
│   ├── dlp-policies.tf   # DLP configuration
│   └── hsm.tf            # HSM-backed keys
└── vpc-service-controls/  # VPC Service Controls
    └── main.tf           # Perimeters and access levels
```

## Usage

```hcl
module "security" {
  source = "./modules/security"
  
  project_id         = var.project_id
  organization_id    = var.organization_id
  organization_name  = var.organization_name
  environment        = var.environment
  
  # SCC Configuration
  enable_scc_premium       = true
  enable_auto_remediation  = var.environment == "prod"
  monitored_projects       = var.monitored_projects
  compliance_standards     = ["CIS", "PCI-DSS", "NIST"]
  
  # Data Protection
  enable_kms                   = true
  enable_dlp                   = true
  enable_access_justification  = var.environment == "prod"
  
  # VPC Service Controls
  protected_projects           = var.protected_projects
  restricted_services          = var.restricted_services
  enable_time_based_access     = var.environment == "prod"
  
  labels = var.labels
}
```

## Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `enable_scc_premium` | Enable SCC Premium features | `true` |
| `enable_auto_remediation` | Enable automated remediation | `false` |
| `compliance_standards` | Standards to monitor | `["CIS", "PCI-DSS", "NIST", "ISO27001"]` |
| `enable_kms` | Enable Cloud KMS | `true` |
| `enable_dlp` | Enable Cloud DLP | `true` |
| `key_rotation_period` | Key rotation period | `"7776000s"` (90 days) |
| `protected_projects` | Projects in VPC-SC perimeter | `[]` |
| `restricted_services` | Services to restrict | See variables.tf |

## Outputs

| Output | Description |
|--------|-------------|
| `scc_notification_config_id` | SCC notification configuration |
| `kms_keys` | Created KMS encryption keys |
| `access_policy` | Access Context Manager policy |
| `security_summary` | Summary of security configurations |

## Security Features by Environment

### Development
- Software-based KMS keys
- Basic SCC monitoring
- Relaxed VPC-SC policies
- Manual remediation

### Staging
- Software-based KMS keys
- Enhanced SCC monitoring
- Moderate VPC-SC policies
- Semi-automated remediation

### Production
- HSM-backed KMS keys
- Full SCC Premium features
- Strict VPC-SC policies
- Automated remediation
- Access justification required
- Device trust enforcement

## Compliance

This module helps achieve compliance with:
- **CIS Google Cloud Platform Benchmark**
- **PCI-DSS** (Payment Card Industry)
- **NIST Cybersecurity Framework**
- **ISO 27001** Information Security
- **SOC 2** Security controls

## Monitoring and Alerting

- SCC findings dashboard
- Custom security metrics
- Automated alert policies
- BigQuery analytics
- Compliance reporting

## Automated Remediation

Supported remediation actions:
- Enable OS Login on VMs
- Enable Shielded VM features
- Remove public bucket access
- Configure lifecycle policies
- Disable unused service accounts
- Apply firewall rule fixes

Generated: 2025-01-27 (Task 5 Implementation)
