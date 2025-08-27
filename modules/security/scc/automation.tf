# Cloud Scheduler job for compliance reports
resource "google_cloud_scheduler_job" "compliance_report" {
  name     = "scc-compliance-report"
  project  = var.project_id
  region   = "us-central1"
  schedule = "0 9 * * 1"  # Every Monday at 9 AM
  
  http_target {
    uri         = "https://securitycenter.googleapis.com/v1/organizations/${var.organization_id}/sources"
    http_method = "GET"
  }
}

# Cloud Function for finding processing (if auto-remediation enabled)
resource "google_cloudfunctions2_function" "finding_processor" {
  count    = var.auto_remediation_enabled ? 1 : 0
  name     = "scc-finding-processor"
  project  = var.project_id
  location = "us-central1"
  
  build_config {
    runtime     = "python39"
    entry_point = "process_finding"
    source {
      storage_source {
        bucket = google_storage_bucket.function_source[0].name
        object = google_storage_bucket_object.function_source[0].name
      }
    }
  }
  
  service_config {
    max_instance_count = 10
    available_memory   = "256M"
    timeout_seconds    = 60
  }
}

resource "google_storage_bucket" "function_source" {
  count    = var.auto_remediation_enabled ? 1 : 0
  name     = "${var.project_id}-scc-function-source"
  project  = var.project_id
  location = "US"
}

resource "google_storage_bucket_object" "function_source" {
  count  = var.auto_remediation_enabled ? 1 : 0
  name   = "function-source.zip"
  bucket = google_storage_bucket.function_source[0].name
  source = "${path.module}/templates/finding_processor.py"
}