# Disaster Recovery Failover Runbook

## Overview
This runbook provides step-by-step procedures for failing over from the primary region (${primary_region}) to the disaster recovery region (${dr_region}) for project ${project_id}.

## Prerequisites
- Access to GCP Console and gcloud CLI
- Appropriate IAM permissions for DR operations
- Notification channels configured and tested
- DR infrastructure validated and ready

## Failover Triggers
Execute this runbook when:
- Primary region is completely unavailable
- RTO/RPO thresholds are exceeded
- Critical infrastructure failure in primary region
- Planned maintenance requiring extended downtime

## Pre-Failover Checklist
- [ ] Confirm primary region is truly unavailable
- [ ] Notify stakeholders of impending failover
- [ ] Verify DR region infrastructure is healthy
- [ ] Confirm data replication is up to date
- [ ] Prepare rollback plan

## Failover Procedure

### Step 1: Assess Situation
```bash
# Check primary region health
gcloud compute instances list --project=${project_id} --filter="zone:(${primary_region})"

# Check load balancer health
gcloud compute backend-services get-health --global --project=${project_id}

# Verify DNS resolution
nslookup ${domain_name}
```

### Step 2: Initiate Automated Failover
```bash
# Trigger automated failover
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  https://cloudbuild.googleapis.com/v1/projects/${project_id}/triggers/dr-failover-trigger:run \
  -d '{"branchName": "main"}'
```

### Step 3: Manual Failover (if automated fails)
```bash
# Update backend service weights
for backend in $(gcloud compute backend-services list --global --project=${project_id} --filter="name:*primary*" --format="value(name)"); do
  echo "Failing over backend: $backend"
  
  # Set primary backend capacity to 0
  gcloud compute backend-services update $backend \
    --global \
    --project=${project_id} \
    --update-backend-capacity-scaler=0.0
  
  # Set DR backend capacity to 1.0
  dr_backend=$(echo $backend | sed 's/primary/dr/')
  gcloud compute backend-services update $dr_backend \
    --global \
    --project=${project_id} \
    --update-backend-capacity-scaler=1.0
done
```

### Step 4: Update DNS Records
```bash
# Start DNS transaction
gcloud dns record-sets transaction start \
  --zone=${dns_zone_name} \
  --project=${project_id}

# Update A record with lower TTL for faster propagation
gcloud dns record-sets transaction add \
  $(gcloud compute addresses describe dr-lb-ip --global --project=${project_id} --format="value(address)") \
  --name=${domain_name}. \
  --ttl=60 \
  --type=A \
  --zone=${dns_zone_name} \
  --project=${project_id}

# Execute DNS changes
gcloud dns record-sets transaction execute \
  --zone=${dns_zone_name} \
  --project=${project_id}
```

### Step 5: Verify Failover
```bash
# Test application availability
curl -I http://${domain_name}/health

# Check backend health
gcloud compute backend-services get-health --global --project=${project_id}

# Verify DNS propagation
dig ${domain_name} @8.8.8.8
```

### Step 6: Database Failover (if applicable)
```bash
# Promote SQL replicas to primary
for replica in $(gcloud sql instances list --project=${project_id} --filter="name:*replica*" --format="value(name)"); do
  echo "Promoting replica: $replica"
  gcloud sql instances promote-replica $replica --project=${project_id}
done
```

### Step 7: Application-Specific Steps
- [ ] Update application configuration for DR region
- [ ] Restart application services if needed
- [ ] Verify data consistency
- [ ] Update monitoring dashboards

## Post-Failover Validation

### Health Checks
```bash
# Application health
curl -f http://${domain_name}/health

# Database connectivity
gcloud sql instances describe [INSTANCE_NAME] --project=${project_id}

# Storage accessibility
gsutil ls gs://[BUCKET_NAME]
```

### Performance Validation
- [ ] Response time within acceptable limits
- [ ] Database queries performing normally
- [ ] All critical features functional
- [ ] Monitoring alerts cleared

## Communication
- [ ] Notify stakeholders of successful failover
- [ ] Update status page
- [ ] Document any issues encountered
- [ ] Schedule post-incident review

## Monitoring
- Monitor application performance in DR region
- Watch for any data consistency issues
- Track user experience metrics
- Monitor costs in DR region

## Rollback Preparation
- Keep primary region infrastructure ready for failback
- Monitor primary region recovery status
- Plan failback timing during low-traffic period

## Emergency Contacts
- Platform Team: [CONTACT_INFO]
- Database Team: [CONTACT_INFO]
- Network Team: [CONTACT_INFO]
- Management: [CONTACT_INFO]

## Notes
- Record all actions taken during failover
- Document any deviations from this runbook
- Note performance differences in DR region
- Track failover completion time for RTO analysis

---
**Last Updated**: $(date)
**Next Review**: Monthly
**Owner**: Platform Team