# Disaster Recovery Failback Runbook

## Overview
This runbook provides step-by-step procedures for failing back from the disaster recovery region (${dr_region}) to the primary region (${primary_region}) for project ${project_id}.

## Prerequisites
- Primary region infrastructure fully restored
- Data synchronization completed
- Stakeholder approval for failback
- Low-traffic period scheduled
- Rollback plan prepared

## Pre-Failback Checklist
- [ ] Primary region infrastructure validated
- [ ] Data replication caught up
- [ ] Performance testing completed in primary region
- [ ] Stakeholders notified of failback window
- [ ] Monitoring alerts configured

## Failback Procedure

### Step 1: Validate Primary Region
```bash
# Check primary region infrastructure
gcloud compute instances list --project=${project_id} --filter="zone:(${primary_region})" --format="table(name,status,zone)"

# Verify database instances
gcloud sql instances list --project=${project_id} --filter="region:(${primary_region})"

# Test connectivity
gcloud compute ssh [INSTANCE_NAME] --zone=${primary_region}-a --project=${project_id} --command="echo 'Primary region accessible'"
```

### Step 2: Data Synchronization
```bash
# Verify data replication status
for bucket in $(gsutil ls -p ${project_id} | grep "dr-data"); do
  echo "Checking replication for: $bucket"
  gsutil rsync -r -d $bucket gs://$(echo $bucket | sed 's/dr-data/primary-data/')
done

# Check SQL replication lag
for instance in $(gcloud sql instances list --project=${project_id} --filter="name:*replica*" --format="value(name)"); do
  gcloud sql instances describe $instance --project=${project_id} --format="value(replicaConfiguration.replicaLag)"
done
```

### Step 3: Gradual Traffic Shift
```bash
# Start with 10% traffic to primary
for backend in $(gcloud compute backend-services list --global --project=${project_id} --filter="name:*primary*" --format="value(name)"); do
  echo "Gradually shifting traffic for: $backend"
  
  # Set primary backend capacity to 0.1 (10%)
  gcloud compute backend-services update $backend \
    --global \
    --project=${project_id} \
    --update-backend-capacity-scaler=0.1
  
  # Reduce DR backend capacity to 0.9 (90%)
  dr_backend=$(echo $backend | sed 's/primary/dr/')
  gcloud compute backend-services update $dr_backend \
    --global \
    --project=${project_id} \
    --update-backend-capacity-scaler=0.9
done

# Wait and monitor
sleep 300

# Increase to 50% if no issues
for backend in $(gcloud compute backend-services list --global --project=${project_id} --filter="name:*primary*" --format="value(name)"); do
  gcloud compute backend-services update $backend \
    --global \
    --project=${project_id} \
    --update-backend-capacity-scaler=0.5
  
  dr_backend=$(echo $backend | sed 's/primary/dr/')
  gcloud compute backend-services update $dr_backend \
    --global \
    --project=${project_id} \
    --update-backend-capacity-scaler=0.5
done

# Wait and monitor
sleep 300

# Complete failback to 100% primary
for backend in $(gcloud compute backend-services list --global --project=${project_id} --filter="name:*primary*" --format="value(name)"); do
  gcloud compute backend-services update $backend \
    --global \
    --project=${project_id} \
    --update-backend-capacity-scaler=1.0
  
  dr_backend=$(echo $backend | sed 's/primary/dr/')
  gcloud compute backend-services update $dr_backend \
    --global \
    --project=${project_id} \
    --update-backend-capacity-scaler=0.0
done
```

### Step 4: Database Failback
```bash
# Promote primary database instances
for instance in $(gcloud sql instances list --project=${project_id} --filter="region:(${primary_region})" --format="value(name)"); do
  echo "Configuring primary database: $instance"
  
  # Ensure primary is ready
  gcloud sql instances patch $instance \
    --project=${project_id} \
    --availability-type=REGIONAL
done

# Reconfigure replicas to point to primary region
for replica in $(gcloud sql instances list --project=${project_id} --filter="name:*replica*" --format="value(name)"); do
  echo "Reconfiguring replica: $replica"
  
  # This may require recreating replicas - plan accordingly
  # gcloud sql instances delete $replica --project=${project_id}
  # gcloud sql instances create $replica --master-instance-name=[PRIMARY_INSTANCE] --project=${project_id}
done
```

### Step 5: Update DNS Records
```bash
# Update DNS to point back to primary region with normal TTL
gcloud dns record-sets transaction start \
  --zone=${dns_zone_name} \
  --project=${project_id}

# Remove current record
gcloud dns record-sets transaction remove \
  $(gcloud compute addresses describe dr-lb-ip --global --project=${project_id} --format="value(address)") \
  --name=${domain_name}. \
  --ttl=60 \
  --type=A \
  --zone=${dns_zone_name} \
  --project=${project_id}

# Add record with normal TTL
gcloud dns record-sets transaction add \
  $(gcloud compute addresses describe dr-lb-ip --global --project=${project_id} --format="value(address)") \
  --name=${domain_name}. \
  --ttl=300 \
  --type=A \
  --zone=${dns_zone_name} \
  --project=${project_id}

# Execute DNS changes
gcloud dns record-sets transaction execute \
  --zone=${dns_zone_name} \
  --project=${project_id}
```

### Step 6: Application Configuration
- [ ] Update application configs for primary region
- [ ] Restart services if configuration changes require it
- [ ] Verify all integrations working
- [ ] Update monitoring dashboards

### Step 7: Validation
```bash
# Test application functionality
curl -f http://${domain_name}/health

# Verify database connectivity
gcloud sql instances describe [PRIMARY_INSTANCE] --project=${project_id}

# Check storage access
gsutil ls gs://[PRIMARY_BUCKET]

# Validate DNS resolution
dig ${domain_name} @8.8.8.8
```

## Post-Failback Tasks

### Infrastructure Cleanup
```bash
# Scale down DR region resources to save costs
for instance in $(gcloud compute instances list --project=${project_id} --filter="zone:(${dr_region})" --format="value(name,zone)"); do
  name=$(echo $instance | cut -d' ' -f1)
  zone=$(echo $instance | cut -d' ' -f2)
  
  echo "Stopping DR instance: $name in $zone"
  gcloud compute instances stop $name --zone=$zone --project=${project_id}
done

# Keep minimal DR infrastructure for future failovers
```

### Monitoring Updates
- [ ] Update monitoring dashboards for primary region
- [ ] Reconfigure alerts for primary region metrics
- [ ] Verify all monitoring is functional
- [ ] Update runbooks with lessons learned

### Documentation
- [ ] Document failback process and timing
- [ ] Note any issues encountered
- [ ] Update incident timeline
- [ ] Record performance metrics

## Validation Checklist
- [ ] Application responding normally
- [ ] Database queries performing well
- [ ] All integrations functional
- [ ] Monitoring alerts cleared
- [ ] DNS propagation complete
- [ ] User experience metrics normal

## Communication
- [ ] Notify stakeholders of successful failback
- [ ] Update status page
- [ ] Send completion notification
- [ ] Schedule post-incident review

## Post-Incident Activities
- [ ] Conduct post-incident review
- [ ] Update DR procedures based on learnings
- [ ] Test DR infrastructure after failback
- [ ] Review and update RTO/RPO targets
- [ ] Update training materials

## Emergency Rollback
If issues occur during failback:

```bash
# Immediately revert to DR region
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  https://cloudbuild.googleapis.com/v1/projects/${project_id}/triggers/dr-failover-trigger:run \
  -d '{"branchName": "main"}'
```

## Success Criteria
- [ ] RTO met during failback process
- [ ] No data loss occurred
- [ ] All services functional in primary region
- [ ] Performance metrics within normal ranges
- [ ] DR infrastructure ready for future use

## Emergency Contacts
- Platform Team: [CONTACT_INFO]
- Database Team: [CONTACT_INFO]
- Network Team: [CONTACT_INFO]
- Management: [CONTACT_INFO]

---
**Last Updated**: $(date)
**Next Review**: After each DR event
**Owner**: Platform Team