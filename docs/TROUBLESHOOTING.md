# Troubleshooting Guide

## Common Issues

### Terraform Errors

#### State Lock Issues
```bash
# Error: Error acquiring the state lock
terraform force-unlock LOCK_ID

# Prevention: Always use proper workspace
terraform workspace select dev
```

#### Permission Denied
```bash
# Check current authentication
gcloud auth list

# Re-authenticate if needed
gcloud auth application-default login

# Verify project access
gcloud projects get-iam-policy PROJECT_ID
```

#### Resource Already Exists
```bash
# Import existing resource
terraform import google_compute_network.main projects/PROJECT_ID/global/networks/NETWORK_NAME

# Or remove from state
terraform state rm google_compute_network.main
```

### Networking Issues

#### VPC Connectivity Problems
```bash
# Check VPC configuration
gcloud compute networks describe NETWORK_NAME

# Verify subnet configuration
gcloud compute networks subnets list --network=NETWORK_NAME

# Test connectivity
gcloud compute ssh INSTANCE_NAME --zone=ZONE
```

#### Firewall Rule Issues
```bash
# List all firewall rules
gcloud compute firewall-rules list

# Check specific rule
gcloud compute firewall-rules describe RULE_NAME

# Test connectivity
telnet TARGET_IP PORT
```

### Security Issues

#### IAM Permission Problems
```bash
# Check current permissions
gcloud projects get-iam-policy PROJECT_ID --flatten="bindings[].members" --filter="bindings.members:user:EMAIL"

# Test specific permission
gcloud auth application-default print-access-token | gcloud auth activate-service-account --key-file=-
```

#### KMS Key Access Issues
```bash
# List KMS keys
gcloud kms keys list --location=LOCATION --keyring=KEYRING

# Check key permissions
gcloud kms keys get-iam-policy KEY_NAME --location=LOCATION --keyring=KEYRING
```

### Monitoring Issues

#### Missing Metrics
```bash
# Check monitoring agent status
sudo systemctl status google-cloud-ops-agent

# Restart agent
sudo systemctl restart google-cloud-ops-agent

# Check logs
sudo journalctl -u google-cloud-ops-agent
```

#### Alert Policy Not Firing
```bash
# Test alert policy
gcloud alpha monitoring policies list

# Check notification channels
gcloud alpha monitoring channels list
```

## Performance Issues

### Slow Terraform Operations
1. **Large State Files**: Consider state splitting
2. **Many Resources**: Use parallelism flag: `terraform apply -parallelism=20`
3. **Network Latency**: Use regional backends

### High Costs
1. **Check unused resources**: Use Cloud Asset Inventory
2. **Review instance sizes**: Right-size compute instances
3. **Optimize storage**: Implement lifecycle policies

## Emergency Procedures

### Security Incident
1. **Isolate affected resources**
2. **Review audit logs**
3. **Contact security team**
4. **Document incident**

### Service Outage
1. **Check monitoring dashboards**
2. **Verify health checks**
3. **Initiate failover if needed**
4. **Communicate status**

### Data Loss
1. **Stop all operations**
2. **Assess scope of loss**
3. **Initiate backup recovery**
4. **Validate data integrity**