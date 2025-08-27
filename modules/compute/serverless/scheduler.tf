resource "google_cloud_scheduler_job" "default" {
  count       = var.enable_scheduler ? 1 : 0
  name        = "default-scheduler-job"
  project     = var.project_id
  region      = var.region
  description = "Default scheduler job"
  schedule    = "0 9 * * 1" # Every Monday at 9 AM
  time_zone   = "America/New_York"
  
  http_target {
    http_method = "POST"
    uri         = var.enable_cloud_run ? google_cloud_run_service.default[0].status[0].url : "https://httpbin.org/post"
    
    headers = {
      "Content-Type" = "application/json"
    }
    
    body = base64encode(jsonencode({
      message = "Scheduled job execution"
    }))
    
    oidc_token {
      service_account_email = google_service_account.serverless.email
    }
  }
}

resource "google_cloud_scheduler_job" "function_trigger" {
  count       = var.enable_scheduler && var.enable_cloud_functions ? 1 : 0
  name        = "function-trigger-job"
  project     = var.project_id
  region      = var.region
  description = "Trigger Cloud Function"
  schedule    = "*/15 * * * *" # Every 15 minutes
  
  http_target {
    http_method = "GET"
    uri         = google_cloudfunctions_function.default[0].https_trigger_url
    
    oidc_token {
      service_account_email = google_service_account.serverless.email
    }
  }
}