# Enhanced Logging and Monitoring Module

This module provides comprehensive observability capabilities for the GCP Landing Zone, implementing enterprise-grade logging, monitoring, alerting, and SLO management.

## Features

### Comprehensive Log Aggregation
- **Multi-tier log sinks** with cost-optimized sampling
- **BigQuery integration** for log analysis and reporting
- **Cloud Storage archival** for long-term retention
- **Intelligent filtering** to reduce noise and costs
- **Compliance-focused** log collection for specific folders

### 🚨 Advanced Alerting
- **Security-focused alerts** for failed logins, privilege escalation, and policy violations
- **Infrastructure monitoring** with compute, network, and storage alerts
- **Application performance** monitoring with error rate and latency alerts
- **Cost optimization** alerts for expensive operations
- **Multi-channel notifications** (Email, Slack, PagerDuty)

### Rich Dashboards
- **Security Overview** - Failed logins, privilege escalation, security events
- **Infrastructure Overview** - Compute status, CPU/disk utilization, network traffic
- **Application Overview** - Error rates, latency, load balancer metrics
- **Cost Overview** - Expensive operations, resource usage by project
- **Executive Overview** - High-level KPIs and trends
- **SLO Overview** - Service level objectives and error budget tracking

### SLO Management
- **Availability SLO** - 99.9% uptime target
- **Latency SLO** - 95% of requests under 2 seconds
- **Error Rate SLO** - Less than 0.1% error rate
- **Security Response SLO** - Incident response time tracking
- **Data Processing SLO** - Pipeline success rate monitoring
- **Error Budget Alerts** - Burn rate and budget exhaustion notifications

### Log-Based Metrics
- **Security Metrics** - Failed logins, privilege escalation, firewall violations
- **Network Metrics** - VPC flow anomalies, data exfiltration indicators
- **Application Metrics** - Error rates, high latency requests
- **Cost Metrics** - Expensive operations tracking
- **Compliance Metrics** - Policy violations, encryption key usage

## Usage

```hcl
module "logging_monitoring" {
  source = "./modules/observability/logging-monitoring"
  
  project_id      = var.project_id
  organization_id = var.organization_id
  region          = var.region
  environment     = var.environment
  
  # Log configuration
  enable_log_sinks        = true
  enable_bigquery_export  = true
  enable_log_archival     = true
  enable_log_exclusions   = true
  
  # Retention settings
  log_retention_days              = 90
  application_log_retention_days  = 30
  archive_retention_days          = 2555  # 7 years
  
  # Sampling rates for cost control
  audit_log_sample_rate       = 0.1    # 10% sampling
  network_log_sample_rate     = 0.01   # 1% sampling
  application_log_sample_rate = 0.05   # 5% sampling
  archive_log_sample_rate     = 0.001  # 0.1% sampling
  
  # Notification configuration
  security_email     = "security-team@company.com"
  operations_email   = "ops-team@company.com"
  slack_webhook_url  = var.slack_webhook_url
  pagerduty_key      = var.pagerduty_key
  
  # Alert thresholds
  failed_login_threshold         = 10
  vpc_flow_anomaly_threshold     = 50
  data_exfiltration_threshold    = 5
  application_error_threshold    = 100
  high_latency_threshold         = 20
  expensive_operations_threshold = 5
  disk_utilization_threshold     = 0.85
  
  # SLO targets
  availability_slo_target        = 0.999  # 99.9%
  latency_slo_target            = 0.95   # 95%
  error_rate_slo_target         = 0.999  # 99.9%
  security_response_slo_target  = 0.95   # 95%
  data_processing_slo_target    = 0.98   # 98%
  
  # SLO thresholds
  latency_threshold_ms       = 2000
  security_incident_threshold = 5
  burn_rate_threshold        = 2.0
  error_budget_threshold     = 0.1
  
  # Uptime checks
  uptime_check_urls = {
    "main-app" = {
      host             = "app.company.com"
      path             = "/health"
      port             = 443
      use_ssl          = true
      validate_ssl     = true
      expected_content = "OK"
    }
  }
  
  # Compliance folders
  compliance_folders = {
    "prod" = {
      folder_id = "folders/123456789"
      name      = "Production"
    }
  }
  
  labels = {
    environment = var.environment
    team        = "platform"
    cost-center = "engineering"
  }
}
```

## Log Sampling Strategy

The module implements intelligent log sampling to balance observability with cost:

| Log Type | Default Sample Rate | Rationale |
|----------|-------------------|-----------|
| Critical Security Events | 100% (no sampling) | Zero tolerance for security blind spots |
| Audit Logs | 10% | Sufficient for compliance and investigation |
| Network Flows | 1% | High volume, patterns detectable at low rates |
| Application Logs | 5% | Balance between debugging capability and cost |
| Archive Logs | 0.1% | Long-term trends only |

## Alert Escalation

The module supports multi-tier alert escalation:

1. **INFO/WARNING** → Email notifications
2. **ERROR** → Email + Slack notifications  
3. **CRITICAL** → Email + Slack + PagerDuty

## SLO Implementation

Service Level Objectives are implemented with:

- **Error Budget Tracking** - Automatic calculation and alerting
- **Burn Rate Alerts** - Early warning when consuming budget too quickly
- **Multi-window SLIs** - Both short-term and long-term tracking
- **Compliance Reporting** - Automated SLO performance reports

## BigQuery Analysis

The module creates several BigQuery views for analysis:

- `security_events_view` - Filtered security events with user attribution
- `network_analysis_view` - Network flow analysis for security investigation
- `daily_security_summary` - Automated daily security reports

## Cost Optimization Features

- **Intelligent Sampling** - Reduces log volume while maintaining visibility
- **Log Exclusions** - Filters out noisy, low-value logs
- **Tiered Storage** - Automatic lifecycle management for archived logs
- **Retention Policies** - Configurable retention based on log type
- **Cost Alerts** - Notifications for expensive operations

## Security Features

- **Zero-trust Logging** - All security events captured without sampling
- **Anomaly Detection** - ML-based detection of unusual patterns
- **Compliance Tracking** - Automated compliance report generation
- **Incident Response** - Integrated alerting and escalation
- **Audit Trail** - Complete audit trail for all administrative actions

## Monitoring Best Practices

The module implements Google's SRE best practices:

- **Four Golden Signals** - Latency, traffic, errors, saturation
- **Error Budgets** - Balance reliability with feature velocity
- **Alerting Hierarchy** - Symptoms before causes
- **Runbook Integration** - Alerts include remediation guidance
- **Noise Reduction** - Intelligent filtering and grouping

## Outputs

The module provides comprehensive outputs for integration:

- Dashboard URLs for direct access
- BigQuery dataset IDs for custom queries
- Log sink names for reference
- SLO IDs for external monitoring
- Notification channel names for additional integrations

## Dependencies

- Google Cloud Logging API
- Google Cloud Monitoring API
- Google BigQuery API
- Google Cloud Storage API (for archival)

## Permissions Required

The module requires the following IAM roles:

- `roles/logging.admin` - For log sink management
- `roles/monitoring.editor` - For alerting and dashboards
- `roles/bigquery.dataEditor` - For log export
- `roles/storage.admin` - For log archival

## Compliance

This module supports compliance with:

- **SOC 2** - Comprehensive audit logging
- **ISO 27001** - Security event monitoring
- **PCI DSS** - Payment card industry requirements
- **GDPR** - Data protection and privacy controls
- **HIPAA** - Healthcare information protection

## Version History

- **v2.0** - Enhanced observability with SLO monitoring and advanced analytics
- **v1.0** - Basic logging and monitoring capabilities

Generated: $(date)