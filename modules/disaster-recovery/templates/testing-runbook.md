# Disaster Recovery Testing Runbook

## Overview
This runbook provides procedures for regular testing of disaster recovery capabilities for project ${project_id}. Regular testing ensures DR procedures work when needed and helps meet RTO (${rto_minutes} minutes) and RPO (${rpo_minutes} minutes) objectives.

## Testing Schedule
- **Full DR Test**: Monthly
- **Partial DR Test**: Weekly
- **Backup Validation**: Daily
- **Chaos Engineering**: Quarterly

## Prerequisites
- Testing environment isolated from production
- Stakeholder notification of testing window
- Rollback procedures ready
- Monitoring configured for test validation

## Test Types

### 1. Backup Validation Test (Daily)
Validates that backups are being created and are recoverable.

```bash
# Test compute snapshots
echo "Testing compute snapshots..."
SNAPSHOTS=$(gcloud compute snapshots list --project=${project_id} --format="value(name)" --filter="creationTimestamp>-P1D")

if [ -z "$SNAPSHOTS" ]; then
  echo "❌ No recent snapshots found"
  exit 1
fi

for snapshot in $SNAPSHOTS; do
  echo "Validating snapshot: $snapshot"
  gcloud compute snapshots describe $snapshot --project=${project_id} > /dev/null
  if [ $? -eq 0 ]; then
    echo "✅ Snapshot $snapshot is valid"
  else
    echo "❌ Snapshot $snapshot validation failed"
    exit 1
  fi
done

# Test SQL backups
echo "Testing SQL backups..."
SQL_INSTANCES=$(gcloud sql instances list --project=${project_id} --format="value(name)")

for instance in $SQL_INSTANCES; do
  echo "Testing SQL instance: $instance"
  RECENT_BACKUP=$(gcloud sql backups list --instance=$instance --project=${project_id} --limit=1 --format="value(id)")
  
  if [ -n "$RECENT_BACKUP" ]; then
    echo "✅ Recent backup found for $instance: $RECENT_BACKUP"
  else
    echo "❌ No recent backup found for $instance"
    exit 1
  fi
done
```

### 2. Data Replication Test (Weekly)
Validates data replication between regions.

```bash
# Test data replication
echo "Testing data replication..."

# Create test file in primary region
TEST_FILE="dr-test-$(date +%s).txt"
echo "Test data created at $(date)" > /tmp/$TEST_FILE

# Upload to primary bucket
gsutil cp /tmp/$TEST_FILE gs://${project_id}-primary-data/

# Wait for replication
sleep 300

# Check if replicated to DR region
if gsutil ls gs://${project_id}-dr-data-*/$TEST_FILE > /dev/null 2>&1; then
  echo "✅ Data replication working"
  
  # Verify content integrity
  gsutil cp gs://${project_id}-dr-data-*/$TEST_FILE /tmp/replicated-$TEST_FILE
  if diff /tmp/$TEST_FILE /tmp/replicated-$TEST_FILE > /dev/null; then
    echo "✅ Data integrity verified"
  else
    echo "❌ Data integrity check failed"
  fi
else
  echo "❌ Data replication failed"
fi

# Cleanup
gsutil rm gs://${project_id}-primary-data/$TEST_FILE
gsutil rm gs://${project_id}-dr-data-*/$TEST_FILE 2>/dev/null || true
rm -f /tmp/$TEST_FILE /tmp/replicated-$TEST_FILE
```

### 3. Failover Simulation Test (Monthly)
Simulates complete failover to DR region.

```bash
# Record start time for RTO measurement
START_TIME=$(date +%s)

echo "Starting failover simulation test..."

# Step 1: Simulate primary region failure
echo "Simulating primary region failure..."
for backend in $(gcloud compute backend-services list --global --project=${project_id} --filter="name:*primary*" --format="value(name)"); do
  # Store original capacity
  ORIGINAL_CAPACITY=$(gcloud compute backend-services describe $backend --global --project=${project_id} --format="value(backends[0].capacityScaler)")
  echo "Original capacity for $backend: $ORIGINAL_CAPACITY"
  
  # Reduce primary capacity to simulate failure
  gcloud compute backend-services update $backend \
    --global \
    --project=${project_id} \
    --update-backend-capacity-scaler=0.0
  
  # Increase DR capacity
  dr_backend=$(echo $backend | sed 's/primary/dr/')
  gcloud compute backend-services update $dr_backend \
    --global \
    --project=${project_id} \
    --update-backend-capacity-scaler=1.0
done

# Step 2: Test application availability
echo "Testing application availability after failover..."
sleep 30

HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://${domain_name}/health || echo "000")

if [ "$HEALTH_CHECK" = "200" ]; then
  echo "✅ Application available after failover"
else
  echo "❌ Application unavailable after failover (HTTP $HEALTH_CHECK)"
fi

# Step 3: Measure RTO
END_TIME=$(date +%s)
ACTUAL_RTO=$((END_TIME - START_TIME))
TARGET_RTO=$((${rto_minutes} * 60))

if [ $ACTUAL_RTO -le $TARGET_RTO ]; then
  echo "✅ RTO met: ${ACTUAL_RTO}s (target: ${TARGET_RTO}s)"
else
  echo "WARNING:RTO exceeded: ${ACTUAL_RTO}s (target: ${TARGET_RTO}s)"
fi

# Step 4: Restore original configuration
echo "Restoring original configuration..."
for backend in $(gcloud compute backend-services list --global --project=${project_id} --filter="name:*primary*" --format="value(name)"); do
  # Restore primary capacity
  gcloud compute backend-services update $backend \
    --global \
    --project=${project_id} \
    --update-backend-capacity-scaler=1.0
  
  # Reduce DR capacity
  dr_backend=$(echo $backend | sed 's/primary/dr/')
  gcloud compute backend-services update $dr_backend \
    --global \
    --project=${project_id} \
    --update-backend-capacity-scaler=0.0
done

echo "Failover simulation test completed"
```

### 4. Database Failover Test (Monthly)
Tests database replica promotion and failback.

```bash
echo "Testing database failover..."

# Test SQL replica promotion (non-destructive)
for replica in $(gcloud sql instances list --project=${project_id} --filter="name:*replica*" --format="value(name)"); do
  echo "Testing replica: $replica"
  
  # Check replica status
  REPLICA_STATUS=$(gcloud sql instances describe $replica --project=${project_id} --format="value(state)")
  
  if [ "$REPLICA_STATUS" = "RUNNABLE" ]; then
    echo "✅ Replica $replica is healthy"
    
    # Check replication lag
    LAG=$(gcloud sql instances describe $replica --project=${project_id} --format="value(replicaConfiguration.replicaLag)" 2>/dev/null || echo "0")
    RPO_SECONDS=$((${rpo_minutes} * 60))
    
    if [ "$LAG" -lt "$RPO_SECONDS" ]; then
      echo "✅ Replica lag within RPO: ${LAG}s (target: ${RPO_SECONDS}s)"
    else
      echo "WARNING:Replica lag exceeds RPO: ${LAG}s (target: ${RPO_SECONDS}s)"
    fi
  else
    echo "❌ Replica $replica status: $REPLICA_STATUS"
  fi
done
```

### 5. Network Failover Test (Monthly)
Tests DNS failover and load balancer behavior.

```bash
echo "Testing network failover..."

# Test DNS resolution
DNS_IP=$(dig +short ${domain_name} @8.8.8.8)
EXPECTED_IP=$(gcloud compute addresses describe dr-lb-ip --global --project=${project_id} --format="value(address)")

if [ "$DNS_IP" = "$EXPECTED_IP" ]; then
  echo "✅ DNS resolution correct: $DNS_IP"
else
  echo "❌ DNS resolution incorrect. Expected: $EXPECTED_IP, Got: $DNS_IP"
fi

# Test load balancer health checks
echo "Testing load balancer health checks..."
for backend in $(gcloud compute backend-services list --global --project=${project_id} --format="value(name)"); do
  echo "Checking backend: $backend"
  
  HEALTH_STATUS=$(gcloud compute backend-services get-health $backend --global --project=${project_id} --format="value(status.healthStatus[0].healthState)")
  
  if [ "$HEALTH_STATUS" = "HEALTHY" ]; then
    echo "✅ Backend $backend is healthy"
  else
    echo "WARNING:Backend $backend status: $HEALTH_STATUS"
  fi
done
```

## Automated Testing

### Scheduled Tests
```bash
# Create Cloud Scheduler job for automated testing
gcloud scheduler jobs create http dr-automated-test \
  --schedule="0 2 * * 0" \
  --uri="https://cloudbuild.googleapis.com/v1/projects/${project_id}/triggers/dr-test-trigger:run" \
  --http-method=POST \
  --headers="Content-Type=application/json" \
  --message-body='{"branchName": "main"}' \
  --oauth-service-account-email="disaster-recovery-sa@${project_id}.iam.gserviceaccount.com" \
  --project=${project_id} \
  --location=${primary_region}
```

### Test Result Validation
```bash
# Check test results from PubSub
gcloud pubsub subscriptions pull dr-test-results-sub \
  --project=${project_id} \
  --limit=10 \
  --format="value(message.data)" | base64 -d
```

## Test Documentation

### Test Report Template
```
DR Test Report - $(date)
================================

Test Type: [BACKUP/REPLICATION/FAILOVER/DATABASE/NETWORK]
Test Duration: [START_TIME] to [END_TIME]
RTO Target: ${rto_minutes} minutes
RPO Target: ${rpo_minutes} minutes

Results:
- RTO Achieved: [ACTUAL_RTO] minutes
- RPO Achieved: [ACTUAL_RPO] minutes
- Success Rate: [PERCENTAGE]%

Issues Encountered:
- [LIST_ISSUES]

Recommendations:
- [LIST_RECOMMENDATIONS]

Next Test Date: [DATE]
```

## Troubleshooting

### Common Issues
1. **Backup Validation Failures**
   - Check backup schedules and policies
   - Verify storage permissions
   - Review backup retention settings

2. **Replication Lag**
   - Check network connectivity between regions
   - Review replication job configurations
   - Monitor resource quotas

3. **Failover Delays**
   - Optimize health check intervals
   - Review DNS TTL settings
   - Check load balancer configuration

### Emergency Procedures
If testing reveals critical issues:
1. Stop the test immediately
2. Restore production configuration
3. Notify stakeholders
4. Create incident ticket
5. Schedule emergency fix

## Success Criteria
- ✅ All backups validated successfully
- ✅ Data replication working within RPO
- ✅ Failover completed within RTO
- ✅ Application fully functional in DR region
- ✅ Database replicas healthy and current
- ✅ Network failover working correctly

## Post-Test Activities
- [ ] Document test results
- [ ] Update runbooks based on findings
- [ ] Address any identified issues
- [ ] Schedule next test
- [ ] Report results to stakeholders

## Metrics to Track
- Backup success rate
- Replication lag times
- Failover duration (RTO)
- Data loss amount (RPO)
- Test execution time
- Issue resolution time

---
**Last Updated**: $(date)
**Next Review**: After each test cycle
**Owner**: Platform Team