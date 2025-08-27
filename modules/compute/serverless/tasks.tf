resource "google_cloud_tasks_queue" "default" {
  count    = var.enable_tasks ? 1 : 0
  name     = "default-queue"
  project  = var.project_id
  location = var.region
  
  rate_limits {
    max_concurrent_dispatches = 100
    max_dispatches_per_second = 10
  }
  
  retry_config {
    max_attempts       = 5
    max_retry_duration = "300s"
    max_backoff        = "60s"
    min_backoff        = "1s"
    max_doublings      = 3
  }
}

resource "google_cloud_tasks_queue" "high_priority" {
  count    = var.enable_tasks ? 1 : 0
  name     = "high-priority-queue"
  project  = var.project_id
  location = var.region
  
  rate_limits {
    max_concurrent_dispatches = 200
    max_dispatches_per_second = 50
  }
  
  retry_config {
    max_attempts       = 3
    max_retry_duration = "60s"
    max_backoff        = "30s"
    min_backoff        = "1s"
    max_doublings      = 2
  }
}

resource "google_project_iam_member" "tasks_enqueuer" {
  count   = var.enable_tasks ? 1 : 0
  project = var.project_id
  role    = "roles/cloudtasks.enqueuer"
  member  = "serviceAccount:${google_service_account.serverless.email}"
}