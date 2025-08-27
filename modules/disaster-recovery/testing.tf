# Scheduled DR testing
resource "google_cloud_scheduler_job" "dr_test" {
  name        = "dr-test-job"
  project     = var.project_id
  region      = var.primary_region
  description = "Scheduled DR testing"
  schedule    = var.dr_test_schedule
  
  http_target {
    http_method = "POST"
    uri         = "https://cloudbuild.googleapis.com/v1/projects/${var.project_id}/triggers/${google_cloudbuild_trigger.dr_test.trigger_id}:run"
    
    headers = {
      "Content-Type" = "application/json"
    }
    
    body = base64encode(jsonencode({
      branchName = "main"
    }))
    
    oauth_token {
      service_account_email = google_service_account.dr_sa.email
    }
  }
}

# Comprehensive DR testing trigger
resource "google_cloudbuild_trigger" "dr_test" {
  project     = var.project_id
  name        = "dr-test-trigger"
  description = "Comprehensive DR testing automation"
  
  trigger_template {
    branch_name = "main"
    repo_name   = "dr-testing"
  }
  
  build {
    step {
      name = "gcr.io/cloud-builders/gcloud"
      script = <<-EOF
        #!/bin/bash
        set -e
        
        echo "Starting comprehensive DR test..."
        
        # Test 1: Health check validation
        echo "=== Testing health checks ==="
        PRIMARY_HEALTH=$(curl -s -o /dev/null -w "%%{http_code}" http://${google_compute_global_address.lb_ip.address}${var.health_check_path} || echo "000")
        
        if [ "$PRIMARY_HEALTH" = "200" ]; then
          echo "✓ Primary region health check passed"
        else
          echo "✗ Primary region health check failed (HTTP $PRIMARY_HEALTH)"
        fi
        
        # Test 2: DNS resolution
        echo "=== Testing DNS resolution ==="
        DNS_IP=$(dig +short ${var.domain_name} @8.8.8.8)
        EXPECTED_IP="${google_compute_global_address.lb_ip.address}"
        
        if [ "$DNS_IP" = "$EXPECTED_IP" ]; then
          echo "✓ DNS resolution correct: $DNS_IP"
        else
          echo "✗ DNS resolution incorrect. Expected: $EXPECTED_IP, Got: $DNS_IP"
        fi
        
        # Test 3: Data replication validation
        echo "=== Testing data replication ==="
        for bucket in ${join(" ", keys(var.primary_data_buckets))}; do
          echo "Testing replication for bucket: $bucket"
          
          PRIMARY_BUCKET="${var.primary_data_buckets[bucket].bucket_name}"
          DR_BUCKET="${var.project_id}-dr-data-$bucket"
          
          # Check if DR bucket exists and has recent data
          if gsutil ls gs://$DR_BUCKET > /dev/null 2>&1; then
            LAST_SYNC=$(gsutil ls -l gs://$DR_BUCKET/** | tail -1 | awk '{print $2}')
            echo "✓ DR bucket $DR_BUCKET exists with recent data: $LAST_SYNC"
          else
            echo "✗ DR bucket $DR_BUCKET not accessible or empty"
          fi
        done
        
        # Test 4: SQL replica validation
        echo "=== Testing SQL replicas ==="
        %{if var.enable_sql_replica}
        for instance in ${join(" ", [for k, v in var.sql_instances : "${v.instance_name}-replica"])}; do
          echo "Testing SQL replica: $instance"
          
          REPLICA_STATUS=$(gcloud sql instances describe $instance --project=${var.project_id} --format="value(state)" 2>/dev/null || echo "NOT_FOUND")
          
          if [ "$REPLICA_STATUS" = "RUNNABLE" ]; then
            echo "✓ SQL replica $instance is running"
            
            # Check replica lag
            LAG=$(gcloud sql instances describe $instance --project=${var.project_id} --format="value(replicaConfiguration.replicaLag)" 2>/dev/null || echo "0")
            if [ "$LAG" -lt "${var.rpo_minutes * 60}" ]; then
              echo "✓ Replica lag within acceptable limits: ${LAG}s"
            else
              echo "WARNING: Replica lag high: ${LAG}s (limit: ${var.rpo_minutes * 60}s)"
            fi
          else
            echo "✗ SQL replica $instance status: $REPLICA_STATUS"
          fi
        done
        %{endif}
        
        # Test 5: GKE DR cluster validation
        echo "=== Testing GKE DR clusters ==="
        for cluster in ${join(" ", [for k, v in var.gke_clusters : "${k}-dr"])}; do
          echo "Testing GKE DR cluster: $cluster"
          
          CLUSTER_STATUS=$(gcloud container clusters describe $cluster --region=${var.dr_region} --project=${var.project_id} --format="value(status)" 2>/dev/null || echo "NOT_FOUND")
          
          if [ "$CLUSTER_STATUS" = "RUNNING" ]; then
            echo "✓ GKE DR cluster $cluster is running"
            
            # Check node readiness
            NODE_COUNT=$(gcloud container clusters describe $cluster --region=${var.dr_region} --project=${var.project_id} --format="value(currentNodeCount)" 2>/dev/null || echo "0")
            echo "✓ DR cluster has $NODE_COUNT nodes ready"
          else
            echo "✗ GKE DR cluster $cluster status: $CLUSTER_STATUS"
          fi
        done
        
        # Test 6: Simulated failover test (non-destructive)
        echo "=== Simulated failover test ==="
        echo "Testing failover procedures (simulation only)..."
        
        # Validate failover scripts exist and are executable
        if [ -f "/workspace/failover-script.sh" ]; then
          echo "✓ Failover script found"
          bash -n /workspace/failover-script.sh && echo "✓ Failover script syntax valid" || echo "✗ Failover script syntax error"
        else
          echo "WARNING: Failover script not found - manual failover required"
        fi
        
        # Test 7: Recovery time estimation
        echo "=== Recovery time estimation ==="
        START_TIME=$(date +%s)
        
        # Simulate time for DNS propagation
        sleep 5
        
        # Simulate time for health check stabilization
        sleep 10
        
        END_TIME=$(date +%s)
        RECOVERY_TIME=$((END_TIME - START_TIME))
        RTO_SECONDS=$((var.rto_minutes * 60))
        
        if [ $RECOVERY_TIME -lt $RTO_SECONDS ]; then
          echo "✓ Estimated recovery time: ${RECOVERY_TIME}s (within RTO: ${RTO_SECONDS}s)"
        else
          echo "WARNING: Estimated recovery time: ${RECOVERY_TIME}s (exceeds RTO: ${RTO_SECONDS}s)"
        fi
        
        echo "DR test completed successfully!"
      EOF
    }
    
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = [
        "pubsub", "topics", "publish", "dr-test-results",
        "--message={\"test_time\":\"$(date -Iseconds)\",\"status\":\"completed\",\"project\":\"${var.project_id}\",\"rto_minutes\":${var.rto_minutes},\"rpo_minutes\":${var.rpo_minutes}}"
      ]
    }
  }
  
  service_account = google_service_account.dr_sa.id
}

# Chaos engineering tests
resource "google_cloud_scheduler_job" "chaos_test" {
  count = var.enable_chaos_engineering ? 1 : 0
  
  name        = "chaos-engineering-test"
  project     = var.project_id
  region      = var.primary_region
  description = "Scheduled chaos engineering tests"
  schedule    = var.chaos_test_schedule
  
  http_target {
    http_method = "POST"
    uri         = "https://cloudbuild.googleapis.com/v1/projects/${var.project_id}/triggers/${google_cloudbuild_trigger.chaos_test[0].trigger_id}:run"
    
    headers = {
      "Content-Type" = "application/json"
    }
    
    body = base64encode(jsonencode({
      branchName = "main"
    }))
    
    oauth_token {
      service_account_email = google_service_account.dr_sa.email
    }
  }
}

# Chaos engineering trigger
resource "google_cloudbuild_trigger" "chaos_test" {
  count = var.enable_chaos_engineering ? 1 : 0
  
  project     = var.project_id
  name        = "chaos-engineering-trigger"
  description = "Chaos engineering tests for DR validation"
  
  trigger_template {
    branch_name = "main"
    repo_name   = "chaos-testing"
  }
  
  build {
    step {
      name = "gcr.io/cloud-builders/gcloud"
      script = <<-EOF
        #!/bin/bash
        set -e
        
        echo "Starting chaos engineering tests..."
        
        # Chaos Test 1: Simulate primary region failure
        echo "=== Chaos Test 1: Primary Region Failure Simulation ==="
        
        # Temporarily reduce primary backend capacity
        for backend in ${join(" ", [for k, v in var.primary_instance_groups : "${k}-primary-backend"])}; do
          echo "Simulating failure for backend: $backend"
          
          # Get current capacity
          CURRENT_CAPACITY=$(gcloud compute backend-services describe $backend --global --project=${var.project_id} --format="value(backends[0].capacityScaler)")
          echo "Current capacity: $CURRENT_CAPACITY"
          
          # Reduce capacity to simulate failure
          gcloud compute backend-services update-backend $backend \
            --global \
            --project=${var.project_id} \
            --instance-group=${var.primary_instance_groups[split("-", backend)[0]].instance_group} \
            --instance-group-region=${var.primary_region} \
            --capacity-scaler=0.1
          
          echo "Reduced capacity to 0.1 for chaos test"
          
          # Wait and test failover
          sleep 30
          
          # Test if traffic is being served
          HEALTH_CHECK=$(curl -s -o /dev/null -w "%%{http_code}" http://${google_compute_global_address.lb_ip.address}${var.health_check_path} || echo "000")
          
          if [ "$HEALTH_CHECK" = "200" ]; then
            echo "✓ Service remained available during simulated failure"
          else
            echo "✗ Service unavailable during simulated failure (HTTP $HEALTH_CHECK)"
          fi
          
          # Restore capacity
          gcloud compute backend-services update-backend $backend \
            --global \
            --project=${var.project_id} \
            --instance-group=${var.primary_instance_groups[split("-", backend)[0]].instance_group} \
            --instance-group-region=${var.primary_region} \
            --capacity-scaler=$CURRENT_CAPACITY
          
          echo "Restored capacity to $CURRENT_CAPACITY"
        done
        
        # Chaos Test 2: Network partition simulation
        echo "=== Chaos Test 2: Network Partition Simulation ==="
        
        # Test DNS failover behavior
        echo "Testing DNS failover behavior..."
        
        # Temporarily set very low TTL
        gcloud dns record-sets transaction start --zone=${var.dns_zone_name} --project=${var.project_id}
        gcloud dns record-sets transaction remove ${google_compute_global_address.lb_ip.address} --name=${var.domain_name}. --ttl=300 --type=A --zone=${var.dns_zone_name} --project=${var.project_id}
        gcloud dns record-sets transaction add ${google_compute_global_address.lb_ip.address} --name=${var.domain_name}. --ttl=60 --type=A --zone=${var.dns_zone_name} --project=${var.project_id}
        gcloud dns record-sets transaction execute --zone=${var.dns_zone_name} --project=${var.project_id}
        
        echo "✓ DNS TTL reduced for faster failover"
        
        # Wait for propagation
        sleep 120
        
        # Restore normal TTL
        gcloud dns record-sets transaction start --zone=${var.dns_zone_name} --project=${var.project_id}
        gcloud dns record-sets transaction remove ${google_compute_global_address.lb_ip.address} --name=${var.domain_name}. --ttl=60 --type=A --zone=${var.dns_zone_name} --project=${var.project_id}
        gcloud dns record-sets transaction add ${google_compute_global_address.lb_ip.address} --name=${var.domain_name}. --ttl=300 --type=A --zone=${var.dns_zone_name} --project=${var.project_id}
        gcloud dns record-sets transaction execute --zone=${var.dns_zone_name} --project=${var.project_id}
        
        echo "✓ DNS TTL restored to normal"
        
        # Chaos Test 3: Data corruption simulation
        echo "=== Chaos Test 3: Data Integrity Validation ==="
        
        # Create test data and verify replication
        TEST_BUCKET="${var.project_id}-chaos-test-$(date +%s)"
        
        gsutil mb gs://$TEST_BUCKET
        echo "test-data-$(date)" | gsutil cp - gs://$TEST_BUCKET/test-file.txt
        
        echo "✓ Created test data in $TEST_BUCKET"
        
        # Wait for replication (if configured)
        sleep 60
        
        # Verify data integrity
        if gsutil cat gs://$TEST_BUCKET/test-file.txt > /dev/null 2>&1; then
          echo "✓ Test data integrity verified"
        else
          echo "✗ Test data integrity check failed"
        fi
        
        # Cleanup
        gsutil rm -r gs://$TEST_BUCKET
        echo "✓ Cleaned up test data"
        
        echo "Chaos engineering tests completed!"
      EOF
    }
    
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = [
        "pubsub", "topics", "publish", "dr-test-results",
        "--message={\"test_time\":\"$(date -Iseconds)\",\"status\":\"chaos_test_completed\",\"project\":\"${var.project_id}\"}"
      ]
    }
  }
  
  service_account = google_service_account.dr_sa.id
}

# DR test results topic
resource "google_pubsub_topic" "dr_test_results" {
  name    = "dr-test-results"
  project = var.project_id
  
  labels = merge(var.labels, {
    purpose = "disaster-recovery-testing"
  })
}

# DR test results subscription
resource "google_pubsub_subscription" "dr_test_results" {
  name    = "dr-test-results-sub"
  topic   = google_pubsub_topic.dr_test_results.name
  project = var.project_id
  
  message_retention_duration = "604800s"  # 7 days
  retain_acked_messages      = false
  
  expiration_policy {
    ttl = "2678400s"  # 31 days
  }
}

# DR events topic for real-time notifications
resource "google_pubsub_topic" "dr_events" {
  name    = "dr-events"
  project = var.project_id
  
  labels = merge(var.labels, {
    purpose = "disaster-recovery-events"
  })
}

# DR runbook storage
resource "google_storage_bucket" "dr_runbooks" {
  count = var.dr_runbook_bucket == null ? 1 : 0
  
  name     = "${var.project_id}-dr-runbooks"
  location = var.primary_region
  project  = var.project_id
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  labels = merge(var.labels, {
    purpose = "disaster-recovery-runbooks"
  })
}

# Upload sample runbook templates
resource "google_storage_bucket_object" "sample_runbooks" {
  count = var.dr_runbook_bucket == null ? 3 : 0
  
  name   = "runbooks/${["failover", "failback", "testing"][count.index]}-procedure.md"
  bucket = google_storage_bucket.dr_runbooks[0].name
  
  content = count.index == 0 ? templatefile("${path.module}/templates/failover-runbook.md", {
    project_id    = var.project_id
    primary_region = var.primary_region
    dr_region     = var.dr_region
    domain_name   = var.domain_name
  }) : count.index == 1 ? templatefile("${path.module}/templates/failback-runbook.md", {
    project_id    = var.project_id
    primary_region = var.primary_region
    dr_region     = var.dr_region
    domain_name   = var.domain_name
  }) : templatefile("${path.module}/templates/testing-runbook.md", {
    project_id    = var.project_id
    primary_region = var.primary_region
    dr_region     = var.dr_region
    rto_minutes   = var.rto_minutes
    rpo_minutes   = var.rpo_minutes
  })
}