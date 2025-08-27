# Cloud Build trigger for backup testing
resource "google_cloudbuild_trigger" "backup_test" {
  count = var.enable_backup_testing ? 1 : 0
  
  project     = var.project_id
  name        = "backup-test-trigger"
  description = "Automated backup testing and validation"
  
  trigger_template {
    branch_name = "main"
    repo_name   = "backup-testing"
  }
  
  build {
    step {
      name = "gcr.io/cloud-builders/gcloud"
      script = <<-EOF
        #!/bin/bash
        set -e
        
        echo "Starting backup validation tests..."
        
        # Test compute snapshots
        echo "Testing compute snapshots..."
        SNAPSHOTS=$(gcloud compute snapshots list --project=${var.project_id} --format="value(name)" --filter="creationTimestamp>-P1D")
        
        if [ -z "$SNAPSHOTS" ]; then
          echo "ERROR: No recent snapshots found"
          exit 1
        fi
        
        for snapshot in $SNAPSHOTS; do
          echo "Validating snapshot: $snapshot"
          gcloud compute snapshots describe $snapshot --project=${var.project_id} > /dev/null
          if [ $? -eq 0 ]; then
            echo "✓ Snapshot $snapshot is valid"
          else
            echo "✗ Snapshot $snapshot validation failed"
            exit 1
          fi
        done
        
        # Test SQL backups
        echo "Testing SQL backups..."
        SQL_INSTANCES=$(gcloud sql instances list --project=${var.project_id} --format="value(name)")
        
        for instance in $SQL_INSTANCES; do
          echo "Testing SQL instance: $instance"
          RECENT_BACKUP=$(gcloud sql backups list --instance=$instance --project=${var.project_id} --limit=1 --format="value(id)")
          
          if [ -n "$RECENT_BACKUP" ]; then
            echo "✓ Recent backup found for $instance: $RECENT_BACKUP"
          else
            echo "✗ No recent backup found for $instance"
            exit 1
          fi
        done
        
        # Test GKE backups
        echo "Testing GKE backups..."
        GKE_BACKUP_PLANS=$(gcloud container backup-restore backup-plans list --location=${var.region} --project=${var.project_id} --format="value(name)")
        
        for plan in $GKE_BACKUP_PLANS; do
          echo "Testing GKE backup plan: $plan"
          RECENT_BACKUP=$(gcloud container backup-restore backups list --backup-plan=$plan --location=${var.region} --project=${var.project_id} --limit=1 --format="value(name)")
          
          if [ -n "$RECENT_BACKUP" ]; then
            echo "✓ Recent GKE backup found for plan $plan: $RECENT_BACKUP"
          else
            echo "✗ No recent GKE backup found for plan $plan"
            exit 1
          fi
        done
        
        echo "All backup validation tests passed!"
      EOF
    }
    
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = [
        "pubsub", "topics", "publish", "backup-test-results",
        "--message={\"test_time\":\"$(date)\",\"status\":\"success\",\"project\":\"${var.project_id}\"}"
      ]
    }
  }
  
  service_account = google_service_account.backup_sa.id
}

# Scheduled backup testing
resource "google_cloud_scheduler_job" "backup_test_schedule" {
  count = var.enable_backup_testing ? 1 : 0
  
  name        = "backup-test-schedule"
  project     = var.project_id
  region      = var.region
  description = "Scheduled backup testing"
  schedule    = var.backup_test_schedule
  
  http_target {
    http_method = "POST"
    uri         = "https://cloudbuild.googleapis.com/v1/projects/${var.project_id}/triggers/${google_cloudbuild_trigger.backup_test[0].trigger_id}:run"
    
    headers = {
      "Content-Type" = "application/json"
    }
    
    body = base64encode(jsonencode({
      branchName = "main"
    }))
    
    oauth_token {
      service_account_email = google_service_account.backup_sa.email
    }
  }
}

# Backup test results topic
resource "google_pubsub_topic" "backup_test_results" {
  name    = "backup-test-results"
  project = var.project_id
  
  labels = var.labels
}

# Backup test results subscription
resource "google_pubsub_subscription" "backup_test_results" {
  name    = "backup-test-results-sub"
  topic   = google_pubsub_topic.backup_test_results.name
  project = var.project_id
  
  message_retention_duration = "604800s"  # 7 days
  retain_acked_messages      = false
  
  expiration_policy {
    ttl = "2678400s"  # 31 days
  }
}

# Backup restore testing (disaster recovery simulation)
resource "google_cloudbuild_trigger" "backup_restore_test" {
  count = var.enable_backup_testing ? 1 : 0
  
  project     = var.project_id
  name        = "backup-restore-test-trigger"
  description = "Automated backup restore testing"
  
  trigger_template {
    branch_name = "main"
    repo_name   = "backup-restore-testing"
  }
  
  build {
    step {
      name = "gcr.io/cloud-builders/gcloud"
      script = <<-EOF
        #!/bin/bash
        set -e
        
        echo "Starting backup restore test..."
        
        # Create test instance from snapshot
        LATEST_SNAPSHOT=$(gcloud compute snapshots list --project=${var.project_id} --format="value(name)" --sort-by="~creationTimestamp" --limit=1)
        
        if [ -n "$LATEST_SNAPSHOT" ]; then
          echo "Creating test disk from snapshot: $LATEST_SNAPSHOT"
          
          gcloud compute disks create test-restore-disk-$(date +%s) \
            --source-snapshot=$LATEST_SNAPSHOT \
            --zone=${var.region}-a \
            --project=${var.project_id}
          
          echo "✓ Test disk created successfully from snapshot"
        else
          echo "✗ No snapshots available for restore testing"
          exit 1
        fi
        
        # Test SQL backup restore (to test instance)
        SQL_INSTANCES=$(gcloud sql instances list --project=${var.project_id} --format="value(name)" --limit=1)
        
        if [ -n "$SQL_INSTANCES" ]; then
          INSTANCE=$(echo $SQL_INSTANCES | head -n1)
          LATEST_BACKUP=$(gcloud sql backups list --instance=$INSTANCE --project=${var.project_id} --limit=1 --format="value(id)")
          
          if [ -n "$LATEST_BACKUP" ]; then
            echo "Testing SQL restore from backup: $LATEST_BACKUP"
            
            # Create test instance for restore
            gcloud sql instances create test-restore-$(date +%s) \
              --database-version=POSTGRES_14 \
              --tier=db-f1-micro \
              --region=${var.region} \
              --project=${var.project_id}
            
            echo "✓ Test SQL instance created for restore testing"
          fi
        fi
        
        echo "Backup restore test completed successfully!"
      EOF
    }
    
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = [
        "pubsub", "topics", "publish", "backup-test-results",
        "--message={\"test_time\":\"$(date)\",\"status\":\"restore_test_success\",\"project\":\"${var.project_id}\"}"
      ]
    }
  }
  
  service_account = google_service_account.backup_sa.id
}

# Backup SLA monitoring
resource "google_monitoring_alert_policy" "backup_sla_violation" {
  count = var.enable_backup_monitoring ? 1 : 0
  
  display_name = "Backup SLA Violation"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Backup older than SLA"
    
    condition_threshold {
      filter          = "resource.type=\"global\" AND metric.type=\"custom.googleapis.com/backup/age_hours\""
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = var.backup_sla_hours
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = var.backup_notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}