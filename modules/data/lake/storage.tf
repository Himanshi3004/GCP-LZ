# Data Lake Storage Buckets with comprehensive lifecycle management
resource "google_storage_bucket" "data_lake_buckets" {
  for_each = var.storage_classes
  
  name          = "${var.project_id}-data-lake-${each.key}"
  location      = var.region
  project       = var.project_id
  storage_class = each.value
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = var.enable_versioning
  }
  
  # Comprehensive lifecycle rules
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules[each.key]
    content {
      condition {
        age                        = lifecycle_rule.value.age
        created_before            = lifecycle_rule.value.created_before
        with_state               = lifecycle_rule.value.with_state
        matches_storage_class    = lifecycle_rule.value.matches_storage_class
        num_newer_versions       = lifecycle_rule.value.num_newer_versions
        custom_time_before       = lifecycle_rule.value.custom_time_before
        days_since_custom_time   = lifecycle_rule.value.days_since_custom_time
        days_since_noncurrent_time = lifecycle_rule.value.days_since_noncurrent_time
        noncurrent_time_before   = lifecycle_rule.value.noncurrent_time_before
      }
      action {
        type          = lifecycle_rule.value.action_type
        storage_class = lifecycle_rule.value.action_storage_class
      }
    }
  }
  
  # Data classification labels
  labels = merge(var.labels, {
    data_tier           = each.key
    data_classification = var.data_classification[each.key]
    retention_policy    = var.retention_days[each.key]
    environment         = var.environment
    cost_center         = var.cost_center
    data_owner          = var.data_owner
  })
  
  # Logging configuration
  logging {
    log_bucket        = google_storage_bucket.access_logs.name
    log_object_prefix = "${each.key}/"
  }
  
  # Encryption with customer-managed keys
  dynamic "encryption" {
    for_each = var.kms_key_name != null ? [1] : []
    content {
      default_kms_key_name = var.kms_key_name
    }
  }
  
  # CORS configuration for web access
  dynamic "cors" {
    for_each = var.enable_cors ? [1] : []
    content {
      origin          = var.cors_origins
      method          = var.cors_methods
      response_header = var.cors_headers
      max_age_seconds = var.cors_max_age
    }
  }
  
  # Website configuration for static hosting
  dynamic "website" {
    for_each = var.enable_website[each.key] ? [1] : []
    content {
      main_page_suffix = var.website_main_page
      not_found_page   = var.website_not_found_page
    }
  }
  
  # Notification configuration
  dynamic "notification" {
    for_each = var.notification_configs
    content {
      topic                 = notification.value.topic
      payload_format       = notification.value.payload_format
      event_types          = notification.value.event_types
      custom_attributes    = notification.value.custom_attributes
      object_name_prefix   = notification.value.object_name_prefix
    }
  }
}

# Access logs bucket
resource "google_storage_bucket" "access_logs" {
  name          = "${var.project_id}-data-lake-access-logs"
  location      = var.region
  project       = var.project_id
  storage_class = "NEARLINE"
  
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = var.access_logs_retention_days
    }
    action {
      type = "Delete"
    }
  }
  
  labels = merge(var.labels, {
    purpose = "access-logs"
    environment = var.environment
  })
}

# IAM bindings with granular access patterns
resource "google_storage_bucket_iam_member" "data_lake_access" {
  for_each = local.bucket_iam_bindings
  
  bucket = google_storage_bucket.data_lake_buckets[each.value.bucket].name
  role   = each.value.role
  member = each.value.member
  
  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Data processing service accounts with specific bucket access
resource "google_storage_bucket_iam_member" "processing_access" {
  for_each = var.processing_service_accounts
  
  bucket = google_storage_bucket.data_lake_buckets[each.value.bucket_tier].name
  role   = each.value.role
  member = "serviceAccount:${each.value.service_account}"
}

# Bucket notifications for data processing triggers
resource "google_storage_notification" "data_processing_triggers" {
  for_each = var.processing_triggers
  
  bucket         = google_storage_bucket.data_lake_buckets[each.value.bucket_tier].name
  topic          = each.value.pubsub_topic
  payload_format = "JSON_API_V1"
  
  event_types = each.value.event_types
  
  dynamic "custom_attributes" {
    for_each = each.value.custom_attributes
    content {
      key   = custom_attributes.key
      value = custom_attributes.value
    }
  }
  
  object_name_prefix = each.value.object_prefix
}

# Local values for IAM binding management
locals {
  bucket_iam_bindings = merge([
    for bucket_key, bucket_config in var.bucket_access_patterns : {
      for binding in bucket_config.iam_bindings : 
      "${bucket_key}-${binding.role}-${replace(binding.member, "/[^a-zA-Z0-9]/", "-")}" => {
        bucket    = bucket_key
        role      = binding.role
        member    = binding.member
        condition = binding.condition
      }
    }
  ]...)
}