# Operations Runbook

## Daily Operations

### 1. Health Checks
```bash
# Check Terraform state
terraform plan

# Verify monitoring dashboards
gcloud monitoring dashboards list

# Check security findings
gcloud scc findings list --organization=123456789012
```

### 2. Backup Verification
```bash
# Check snapshot status
gcloud compute snapshots list --filter="creationTimestamp>-P1D"

# Verify database backups
gcloud sql backups list --instance=main-db

# Check GKE backups
gcloud container backup-restore backup-plans list
```

## Incident Response

### Security Incident
1. **Immediate Actions**:
   - Check Security Command Center
   - Review audit logs
   - Isolate affected resources

2. **Investigation**:
   ```bash
   # Check recent changes
   gcloud logging read "protoPayload.methodName=SetIamPolicy" --limit=50
   
   # Review firewall changes
   gcloud compute firewall-rules list --filter="creationTimestamp>-P1D"
   ```

### Network Issues
1. **Connectivity Problems**:
   ```bash
   # Check VPC status
   gcloud compute networks list
   
   # Verify firewall rules
   gcloud compute firewall-rules list
   
   # Check Cloud NAT
   gcloud compute routers nats list --router=main-router
   ```

### Performance Issues
1. **Resource Monitoring**:
   ```bash
   # Check compute utilization
   gcloud compute instances list --format="table(name,status,machineType)"
   
   # Monitor database performance
   gcloud sql instances describe main-db
   ```

## Maintenance Procedures

### Monthly Tasks
- Review and rotate service account keys
- Update Terraform modules to latest versions
- Conduct disaster recovery tests
- Review cost optimization opportunities

### Quarterly Tasks
- Security audit and compliance review
- Capacity planning and scaling assessment
- Documentation updates
- Team training and knowledge transfer