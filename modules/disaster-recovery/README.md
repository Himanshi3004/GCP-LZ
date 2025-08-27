# Disaster Recovery Module

This module provides comprehensive disaster recovery capabilities for GCP workloads including automated failover, data replication, backup integration, and regular testing procedures.

## Features

### Multi-Region Architecture
- **Active-Passive Setup**: Primary region with standby DR region
- **Active-Active Setup**: Optional multi-region active setup with traffic splitting
- **Global Load Balancing**: Intelligent traffic routing with health-based failover
- **DNS Failover**: Automated DNS updates during failover events

### Data Replication
- **Storage Replication**: Cross-region data replication with Storage Transfer Service
- **SQL Replicas**: Read replicas in DR region with automatic promotion capability
- **GKE Backup Replication**: Cross-region backup replication for Kubernetes workloads
- **Real-time Monitoring**: Replication lag monitoring and alerting

### Automated Failover
- **Health-Based Failover**: Automatic failover based on health check failures
- **Manual Failover**: Controlled failover procedures with approval workflows
- **Gradual Failback**: Staged traffic shifting during failback operations
- **Rollback Capabilities**: Quick rollback procedures if issues occur

### Testing and Validation
- **Scheduled Testing**: Regular automated DR testing procedures
- **Chaos Engineering**: Controlled failure injection for resilience testing
- **Backup Validation**: Integration with backup module for restore testing
- **Performance Validation**: RTO/RPO measurement and reporting

## Architecture

```
Primary Region (us-central1)          DR Region (us-east1)
┌─────────────────────────┐          ┌─────────────────────────┐
│  Application Instances  │          │   Standby Instances     │
│  ┌─────┐ ┌─────┐ ┌─────┐│          │  ┌─────┐ ┌─────┐ ┌─────┐│
│  │App1 │ │App2 │ │App3 ││ ◄──────► │  │App1 │ │App2 │ │App3 ││
│  └─────┘ └─────┘ └─────┘│          │  └─────┘ └─────┘ └─────┘│
│                         │          │                         │
│  Primary SQL Database   │          │   Read Replica          │
│  ┌─────────────────────┐│          │  ┌─────────────────────┐│
│  │     PostgreSQL      ││ ◄──────► │  │     PostgreSQL      ││
│  └─────────────────────┘│          │  └─────────────────────┘│
│                         │          │                         │
│  Primary Data Storage   │          │   Replicated Storage    │
│  ┌─────────────────────┐│          │  ┌─────────────────────┐│
│  │   Cloud Storage     ││ ◄──────► │  │   Cloud Storage     ││
│  └─────────────────────┘│          │  └─────────────────────┘│
└─────────────────────────┘          └─────────────────────────┘
            │                                      │
            └──────────────────┬───────────────────┘
                               │
                    ┌─────────────────────┐
                    │  Global Load        │
                    │  Balancer           │
                    │  ┌─────────────────┐│
                    │  │   Cloud DNS     ││
                    │  └─────────────────┘│
                    └─────────────────────┘
```

## Usage

### Basic Configuration
```hcl
module "disaster_recovery" {
  source = "./modules/disaster-recovery"
  
  project_id     = var.project_id
  primary_region = "us-central1"
  dr_region      = "us-east1"
  
  dns_zone_name = "example-com"
  domain_name   = "example.com"
  
  # RTO/RPO objectives
  rto_minutes = 60   # 1 hour recovery time
  rpo_minutes = 15   # 15 minutes data loss tolerance
  
  # Instance groups for load balancing
  primary_instance_groups = {
    "web" = {
      instance_group = "projects/my-project/zones/us-central1-a/instanceGroups/web-primary"
      port          = 80
      protocol      = "HTTP"
    }
  }
  
  dr_instance_groups = {
    "web" = {
      instance_group = "projects/my-project/zones/us-east1-a/instanceGroups/web-dr"
      port          = 80
      protocol      = "HTTP"
    }
  }
  
  # Data replication
  primary_data_buckets = {
    "app-data" = {
      bucket_name = "my-app-data-primary"
      sync_path   = "data/"
    }
  }
  
  # SQL replication
  enable_sql_replica = true
  sql_instances = {
    "main-db" = {
      instance_name    = "production-db"
      database_version = "POSTGRES_14"
      tier            = "db-n1-standard-2"
    }
  }
  
  # Testing configuration
  enable_dr_testing       = true
  enable_chaos_engineering = true
  
  notification_channels = [
    "projects/my-project/notificationChannels/email-alerts"
  ]
  
  labels = {
    environment = "production"
    team        = "platform"
  }
}
```

### Active-Active Configuration
```hcl
module "disaster_recovery" {
  source = "./modules/disaster-recovery"
  
  # ... basic configuration ...
  
  # Multi-region active setup
  enable_multi_region_setup = true
  traffic_split_primary     = 70  # 70% primary, 30% DR
  
  # Automated failover
  enable_automated_failover = true
}
```

## Failover Procedures

### Automated Failover
When enabled, automated failover triggers when:
- Primary region health checks fail consistently
- RTO thresholds are exceeded
- Manual trigger via webhook

```bash
# Trigger manual failover
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  https://cloudbuild.googleapis.com/v1/projects/PROJECT_ID/triggers/dr-failover-trigger:run \
  -d '{"branchName": "main"}'
```

### Manual Failover Steps
1. **Assessment**: Verify primary region is truly unavailable
2. **Notification**: Alert stakeholders of impending failover
3. **Data Sync**: Ensure data replication is current
4. **Traffic Shift**: Update load balancer to route to DR region
5. **DNS Update**: Update DNS records with lower TTL
6. **Validation**: Verify application functionality in DR region
7. **Monitoring**: Monitor performance and user experience

### Failback Procedures
1. **Primary Recovery**: Ensure primary region is fully operational
2. **Data Sync**: Synchronize any changes made during DR operation
3. **Gradual Shift**: Gradually shift traffic back to primary (10% → 50% → 100%)
4. **DNS Restore**: Update DNS records back to normal TTL
5. **Validation**: Verify full functionality in primary region
6. **Cleanup**: Scale down DR resources to save costs

## Testing Framework

### Automated Testing Types
- **Daily**: Backup validation and data integrity checks
- **Weekly**: Data replication validation and partial failover tests
- **Monthly**: Full failover simulation and database replica testing
- **Quarterly**: Chaos engineering and comprehensive DR validation

### Test Execution
```bash
# Run comprehensive DR test
gcloud builds triggers run dr-test-trigger --project=PROJECT_ID

# Run chaos engineering test
gcloud builds triggers run chaos-engineering-trigger --project=PROJECT_ID

# Check test results
gcloud pubsub subscriptions pull dr-test-results-sub --project=PROJECT_ID
```

### Test Metrics
- **RTO Achievement**: Actual vs target recovery time
- **RPO Achievement**: Actual vs target data loss
- **Success Rate**: Percentage of successful tests
- **Issue Resolution**: Time to resolve identified issues

## Monitoring and Alerting

### Key Metrics
- **Replication Lag**: Data replication delay between regions
- **Health Check Status**: Application and infrastructure health
- **Failover Time**: Time taken for failover operations
- **Data Consistency**: Validation of replicated data integrity

### Alert Policies
- **Replication Failure**: Storage transfer job failures
- **SQL Replica Lag**: Database replication lag exceeding RPO
- **Health Check Failures**: Application unavailability
- **Test Failures**: DR test execution failures

### Notification Channels
Configure multiple notification channels for different alert types:
```hcl
notification_channels = [
  "projects/PROJECT_ID/notificationChannels/email-platform-team",
  "projects/PROJECT_ID/notificationChannels/slack-alerts",
  "projects/PROJECT_ID/notificationChannels/pagerduty-critical"
]
```

## Security Considerations

### Access Control
- **Service Accounts**: Dedicated service accounts with minimal permissions
- **IAM Roles**: Least-privilege access for DR operations
- **Audit Logging**: All DR operations logged for security review

### Data Protection
- **Encryption**: All replicated data encrypted in transit and at rest
- **Network Security**: Private connectivity between regions
- **Access Justification**: Controlled access to DR resources

### Compliance
- **Audit Trail**: Complete audit trail of all DR activities
- **Data Residency**: Compliance with data residency requirements
- **Retention Policies**: Appropriate data retention in DR region

## Cost Optimization

### Resource Management
- **Standby Resources**: Minimal resources in DR region during normal operation
- **Auto-scaling**: Automatic scaling during failover events
- **Scheduled Scaling**: Predictive scaling based on usage patterns

### Storage Optimization
- **Lifecycle Policies**: Automatic transition to cheaper storage classes
- **Compression**: Data compression for replication
- **Deduplication**: Eliminate duplicate data in backups

### Monitoring Costs
- **Cost Alerts**: Notifications when DR costs exceed thresholds
- **Usage Reports**: Regular reports on DR resource utilization
- **Optimization Recommendations**: Automated cost optimization suggestions

## Integration with Backup Module

The DR module integrates seamlessly with the backup module:
- **Backup Replication**: Cross-region backup replication
- **Restore Testing**: Regular restore validation
- **Recovery Procedures**: Coordinated backup and DR procedures

```hcl
# Example integration
module "backup" {
  source = "./modules/backup"
  # ... backup configuration ...
  enable_cross_region_backup = true
  backup_regions            = [module.disaster_recovery.primary_region, module.disaster_recovery.dr_region]
}

module "disaster_recovery" {
  source = "./modules/disaster-recovery"
  # ... DR configuration ...
  depends_on = [module.backup]
}
```

## Runbooks

The module includes comprehensive runbooks for:
- **Failover Procedures**: Step-by-step failover instructions
- **Failback Procedures**: Detailed failback process
- **Testing Procedures**: Regular testing guidelines
- **Troubleshooting**: Common issues and solutions

Runbooks are stored in Cloud Storage and automatically updated with current configuration.

## Variables

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `project_id` | The GCP project ID | `string` | - |
| `primary_region` | Primary region | `string` | `"us-central1"` |
| `dr_region` | Disaster recovery region | `string` | `"us-east1"` |
| `rto_minutes` | Recovery Time Objective in minutes | `number` | `60` |
| `rpo_minutes` | Recovery Point Objective in minutes | `number` | `15` |
| `enable_automated_failover` | Enable automated failover | `bool` | `false` |
| `enable_multi_region_setup` | Enable multi-region active-active setup | `bool` | `false` |
| `traffic_split_primary` | Traffic percentage for primary region | `number` | `100` |
| `enable_dr_testing` | Enable automated DR testing | `bool` | `true` |
| `enable_chaos_engineering` | Enable chaos engineering tests | `bool` | `false` |

## Outputs

| Output | Description |
|--------|-------------|
| `global_load_balancer_ip` | Global load balancer IP address |
| `dns_zone_name` | DNS managed zone name |
| `primary_backend_services` | Primary region backend service names |
| `dr_backend_services` | DR region backend service names |
| `sql_replicas` | SQL replica instance names |
| `dr_clusters` | DR GKE cluster names |
| `failover_triggers` | Failover automation trigger names |
| `dr_test_triggers` | DR testing trigger names |

## Best Practices

1. **Regular Testing**: Test DR procedures regularly to ensure they work
2. **Documentation**: Keep runbooks updated with current procedures
3. **Monitoring**: Implement comprehensive monitoring and alerting
4. **Automation**: Automate as much as possible while maintaining control
5. **Communication**: Establish clear communication procedures for DR events
6. **Training**: Regular training for team members on DR procedures
7. **Review**: Regular review and update of RTO/RPO objectives

## Troubleshooting

### Common Issues
1. **Replication Lag**: Check network connectivity and quotas
2. **Failover Delays**: Review health check configurations
3. **DNS Propagation**: Consider TTL settings and caching
4. **Cost Overruns**: Monitor and optimize DR resource usage

### Support Resources
- Runbooks in Cloud Storage bucket
- Monitoring dashboards for DR metrics
- PubSub topics for real-time notifications
- Cloud Build logs for automation troubleshooting