resource "google_app_engine_application" "app" {
  count         = var.enable_app_engine ? 1 : 0
  project       = var.project_id
  location_id   = var.region
  database_type = "CLOUD_DATASTORE_COMPATIBILITY"
}

resource "google_app_engine_standard_app_version" "default" {
  count      = var.enable_app_engine ? 1 : 0
  version_id = "v1"
  service    = "default"
  project    = var.project_id
  runtime    = "python39"
  
  entrypoint {
    shell = "gunicorn -b :$PORT main:app"
  }
  
  deployment {
    files {
      name       = "main.py"
      source_url = "https://storage.googleapis.com/${google_storage_bucket.function_source[0].name}/main.py"
    }
    
    files {
      name       = "requirements.txt"
      source_url = "https://storage.googleapis.com/${google_storage_bucket.function_source[0].name}/requirements.txt"
    }
  }
  
  automatic_scaling {
    max_concurrent_requests = 10
    min_idle_instances      = 1
    max_idle_instances      = 3
    min_pending_latency     = "1s"
    max_pending_latency     = "5s"
  }
  
  vpc_access_connector {
    name = var.enable_cloud_run ? google_vpc_access_connector.connector[0].name : null
  }
  
  service_account = google_service_account.serverless.email
  
  depends_on = [google_app_engine_application.app]
}