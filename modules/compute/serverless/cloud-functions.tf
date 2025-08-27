resource "google_storage_bucket" "function_source" {
  count    = var.enable_cloud_functions ? 1 : 0
  name     = "${var.project_id}-function-source"
  location = var.region
  project  = var.project_id
  
  uniform_bucket_level_access = true
  labels = var.labels
}

resource "google_storage_bucket_object" "function_zip" {
  count  = var.enable_cloud_functions ? 1 : 0
  name   = "function-source.zip"
  bucket = google_storage_bucket.function_source[0].name
  source = "${path.module}/function-source.zip"
}

resource "google_cloudfunctions_function" "functions" {
  for_each = var.cloud_functions
  
  name        = each.key
  project     = var.project_id
  region      = var.region
  runtime     = lookup(each.value, "runtime", "python39")
  
  available_memory_mb   = lookup(each.value, "memory", 256)
  timeout              = lookup(each.value, "timeout", 60)
  max_instances        = lookup(each.value, "max_instances", 10)
  
  source_archive_bucket = google_storage_bucket.function_source[0].name
  source_archive_object = lookup(each.value, "source_object", google_storage_bucket_object.function_zip[0].name)
  
  https_trigger_security_level = "SECURE_ALWAYS"
  
  entry_point = each.value.entry_point
  
  vpc_connector                 = var.enable_vpc_connector ? google_vpc_access_connector.connector[0].name : null
  vpc_connector_egress_settings = lookup(each.value, "egress_settings", "PRIVATE_RANGES_ONLY")
  
  service_account_email = google_service_account.serverless.email
  
  dynamic "environment_variables" {
    for_each = lookup(each.value, "env_vars", {})
    content {
      key   = environment_variables.key
      value = environment_variables.value
    }
  }
  
  dynamic "event_trigger" {
    for_each = lookup(each.value, "event_trigger", null) != null ? [each.value.event_trigger] : []
    content {
      event_type = event_trigger.value.event_type
      resource   = event_trigger.value.resource
      
      dynamic "failure_policy" {
        for_each = lookup(event_trigger.value, "retry", false) ? [1] : []
        content {
          retry = true
        }
      }
    }
  }
  
  labels = merge(var.labels, lookup(each.value, "labels", {}))
}

resource "google_cloudfunctions_function_iam_member" "invokers" {
  for_each = {
    for k, v in var.cloud_functions : k => v
    if lookup(v, "allow_public_access", false)
  }
  
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.functions[each.key].name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}