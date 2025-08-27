# Backup Module

This module provides comprehensive backup and recovery capabilities for GCP resources including compute disks, SQL databases, GKE clusters, and application data.

## Features

### Automated Backups
- **Compute Snapshots**: Daily and weekly snapshot policies with cross-region replication
- **SQL Database Backups**: Automated backups with point-in-time recovery and cross-region replicas
- **GKE Cluster Backups**: Complete cluster and application backup with restore plans
- **Application Data Backups**: Custom application data backup with validation

### Backup Management
- **Retention Policies**: Configurable retention for daily and long-term backups
- **Cross-Region Replication**: Automatic backup replication to secondary regions
- **Encryption**: KMS encryption support for all backup types
- **Lifecycle Management**: Automatic storage class transitions for cost optimization

### Monitoring and Alerting
- **Backup Failure Alerts**: Notifications for failed backup operations
- **SLA Monitoring**: Alerts when backups exceed defined SLA thresholds
- **Age Monitoring**: Alerts for stale or missing backups
- **Success Tracking**: Monitoring of backup completion and validation

### Testing and Validation
- **Automated Testing**: Scheduled backup integrity testing
- **Restore Testing**: Periodic restore validation to ensure backup viability
- **Validation Functions**: Cloud Functions for backup content validation
- **Reporting**: PubSub notifications for test results and status

## Usage

```hcl
module "backup" {
  source = "./modules/backup"
  
  project_id = var.project_id
  region     = var.region
  
  # Retention configuration
  backup_retention_days      = 30
  long_term_retention_days   = 365
  
  # Cross-region backup
  enable_cross_region_backup = true
  backup_regions            = ["us-central1", "us-east1"]
  
  # Resources to backup
  disk_names = [
    "web-server-disk",
    "database-disk"
  ]
  
  sql_instances = {
    "production-db" = {
      database_version = "POSTGRES_14"
      tier            = "db-n1-standard-2"
      region          = "us-central1"
    }
  }
  
  gke_clusters = {
    "production-cluster" = {
      cluster_id = "projects/my-project/locations/us-central1/clusters/prod"
      location   = "us-central1"
    }
  }
  
  # Application backups
  application_backup_paths = {
    "web-app" = {
      source_bucket = "my-app-data"
      backup_path   = "backups/"
      schedule      = "0 3 * * *"
    }
  }
  
  # Monitoring and testing
  enable_backup_monitoring = true
  enable_backup_testing   = true
  backup_sla_hours        = 24
  
  backup_notification_channels = [
    "projects/my-project/notificationChannels/123456"
  ]
  
  # Encryption
  kms_key_id = "projects/my-project/locations/us-central1/keyRings/backup/cryptoKeys/backup-key"
  
  labels = {
    environment = "production"
    team        = "platform"
  }
}
```

## Backup Types

### 1. Compute Snapshots
- **Daily Snapshots**: Automated daily snapshots with configurable retention
- **Weekly Snapshots**: Long-term weekly snapshots for extended retention
- **Cross-Region Storage**: Snapshots stored in multiple regions for disaster recovery
- **Guest Flush**: Ensures filesystem consistency during snapshot creation

### 2. SQL Database Backups
- **Automated Backups**: Daily automated backups with point-in-time recovery
- **Cross-Region Replicas**: Read replicas in secondary regions for disaster recovery
- **Transaction Log Retention**: Configurable transaction log retention for PITR
- **Manual Backup Triggers**: On-demand backup capability via Cloud Scheduler

### 3. GKE Cluster Backups
- **Complete Cluster Backup**: Full cluster state including configurations and data
- **Application-Aware Backups**: Namespace and application-specific backup selection
- **Volume Data Backup**: Persistent volume data included in backups
- **Restore Plans**: Pre-configured restore plans for rapid recovery

### 4. Application Data Backups
- **Custom Application Backups**: Flexible backup configuration for application data
- **Storage Transfer Jobs**: Automated data transfer to backup locations
- **Validation Functions**: Cloud Functions for backup integrity validation
- **Flexible Scheduling**: Configurable backup schedules per application

## Monitoring and Alerting

### Alert Policies
- **Snapshot Failure**: Alerts when compute snapshot creation fails
- **SQL Backup Failure**: Notifications for failed database backups
- **SQL Backup Age**: Alerts when database backups become stale
- **GKE Backup Failure**: Notifications for failed cluster backups
- **Application Backup Failure**: Alerts for failed application data transfers
- **Backup SLA Violation**: Alerts when backups exceed defined SLA thresholds

### Notification Channels
Configure notification channels for backup alerts:
```hcl
backup_notification_channels = [
  "projects/my-project/notificationChannels/email-alerts",
  "projects/my-project/notificationChannels/slack-alerts"
]
```

## Testing and Validation

### Automated Testing
- **Backup Integrity Testing**: Scheduled validation of backup completeness
- **Restore Testing**: Periodic restore operations to test backup viability
- **Cross-Region Testing**: Validation of cross-region backup accessibility
- **Application Validation**: Custom validation for application-specific backups

### Test Scheduling
```hcl
enable_backup_testing = true
backup_test_schedule  = "0 6 * * 0"  # Weekly on Sunday at 6 AM
```

### Test Results
Test results are published to PubSub topics for integration with monitoring systems:
- `backup-test-results`: General backup test results
- `backup-validation-results`: Backup validation function results
- `gke-backup-notifications`: GKE-specific backup notifications

## Security

### Encryption
- **KMS Integration**: Support for customer-managed encryption keys
- **Encryption at Rest**: All backups encrypted using specified KMS keys
- **Key Rotation**: Automatic support for key rotation policies

### Access Control
- **Service Accounts**: Dedicated service accounts with minimal required permissions
- **IAM Roles**: Least-privilege access for backup operations
- **Audit Logging**: All backup operations logged for security auditing

## Cost Optimization

### Storage Classes
- **Lifecycle Policies**: Automatic transition to cheaper storage classes
- **Nearline Storage**: 30-day transition to nearline storage
- **Coldline Storage**: 90-day transition to coldline storage
- **Retention Management**: Automatic deletion based on retention policies

### Cross-Region Considerations
- **Regional Backup**: Primary backups stored in the same region as resources
- **Cross-Region Replication**: Secondary backups in different regions for DR
- **Transfer Costs**: Consider data transfer costs for cross-region backups

## Disaster Recovery Integration

This backup module integrates with the disaster recovery module to provide:
- **Cross-Region Replicas**: SQL replicas in DR regions
- **Backup Accessibility**: Backups available in multiple regions
- **Restore Procedures**: Automated restore capabilities for DR scenarios
- **Testing Integration**: Regular DR testing using backup restore procedures

## Variables

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `project_id` | The GCP project ID | `string` | - |
| `region` | The GCP region | `string` | `"us-central1"` |
| `backup_retention_days` | Number of days to retain backups | `number` | `30` |
| `long_term_retention_days` | Number of days to retain long-term backups | `number` | `365` |
| `enable_cross_region_backup` | Enable cross-region backup replication | `bool` | `true` |
| `backup_regions` | List of regions for backup replication | `list(string)` | `["us-central1", "us-east1"]` |
| `enable_backup_monitoring` | Enable backup monitoring and alerting | `bool` | `true` |
| `enable_backup_testing` | Enable automated backup testing | `bool` | `true` |
| `backup_sla_hours` | Backup SLA in hours for alerting | `number` | `24` |
| `kms_key_id` | KMS key ID for encryption | `string` | `null` |

## Outputs

| Output | Description |
|--------|-------------|
| `backup_service_account_email` | Email of the backup service account |
| `snapshot_policies` | Compute snapshot policy names |
| `gke_backup_plans` | GKE backup plan names |
| `gke_restore_plans` | GKE restore plan names |
| `backup_buckets` | Backup storage bucket names |
| `backup_monitoring_policies` | Backup monitoring alert policy names |

## Best Practices

1. **Regular Testing**: Enable automated backup testing to ensure backup viability
2. **Cross-Region Replication**: Use cross-region backups for disaster recovery
3. **Encryption**: Always use KMS encryption for sensitive data backups
4. **Monitoring**: Configure appropriate notification channels for backup alerts
5. **Retention Policies**: Set appropriate retention periods based on compliance requirements
6. **Cost Management**: Use lifecycle policies to optimize storage costs
7. **Documentation**: Maintain documentation of backup and restore procedures

## Troubleshooting

### Common Issues

1. **Snapshot Creation Failures**
   - Check disk permissions and availability
   - Verify snapshot policy attachment
   - Review compute engine quotas

2. **SQL Backup Failures**
   - Verify SQL instance configuration
   - Check backup configuration settings
   - Review SQL admin API permissions

3. **GKE Backup Failures**
   - Verify GKE backup API enablement
   - Check cluster permissions
   - Review backup plan configuration

4. **Cross-Region Replication Issues**
   - Verify regional quotas and limits
   - Check network connectivity between regions
   - Review storage transfer job configuration

### Monitoring and Debugging

Use the provided monitoring alerts and PubSub topics to track backup status and troubleshoot issues. All backup operations are logged and can be reviewed in Cloud Logging for detailed troubleshooting.