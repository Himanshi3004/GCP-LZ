# Pub/Sub topics for data ingestion and processing
resource "google_pubsub_topic" "data_topics" {
  for_each = var.pubsub_topics
  
  name    = each.key
  project = var.project_id
  
  message_retention_duration = each.value.message_retention_duration
  
  # Schema configuration
  dynamic "schema_settings" {
    for_each = each.value.schema != null ? [each.value.schema] : []
    content {
      schema   = google_pubsub_schema.schemas[schema_settings.value.name].name
      encoding = schema_settings.value.encoding
    }
  }
  
  # Message storage policy
  dynamic "message_storage_policy" {
    for_each = each.value.allowed_persistence_regions != null ? [1] : []
    content {
      allowed_persistence_regions = each.value.allowed_persistence_regions
    }
  }
  
  labels = merge(var.labels, {
    topic_type  = each.value.topic_type
    data_source = each.value.data_source
    environment = var.environment
  })
}

# Dead letter topics for failed message handling
resource "google_pubsub_topic" "dead_letter_topics" {
  for_each = var.dead_letter_topics
  
  name    = "${each.key}-dlq"
  project = var.project_id
  
  message_retention_duration = each.value.message_retention_duration
  
  labels = merge(var.labels, {
    topic_type  = "dead-letter"
    parent_topic = each.key
    environment = var.environment
  })
}

# Pub/Sub schemas for message validation
resource "google_pubsub_schema" "schemas" {
  for_each = var.pubsub_schemas
  
  name       = each.key
  project    = var.project_id
  type       = each.value.type
  definition = each.value.definition
}

# Pub/Sub subscriptions with comprehensive configuration
resource "google_pubsub_subscription" "data_subscriptions" {
  for_each = var.pubsub_subscriptions
  
  name    = each.key
  topic   = google_pubsub_topic.data_topics[each.value.topic].name
  project = var.project_id
  
  message_retention_duration = each.value.message_retention_duration
  retain_acked_messages      = each.value.retain_acked_messages
  ack_deadline_seconds       = each.value.ack_deadline_seconds
  
  # Expiration policy
  dynamic "expiration_policy" {
    for_each = each.value.expiration_ttl != null ? [1] : []
    content {
      ttl = each.value.expiration_ttl
    }
  }
  
  # Retry policy
  dynamic "retry_policy" {
    for_each = each.value.retry_policy != null ? [each.value.retry_policy] : []
    content {
      minimum_backoff = retry_policy.value.minimum_backoff
      maximum_backoff = retry_policy.value.maximum_backoff
    }
  }
  
  # Dead letter policy
  dynamic "dead_letter_policy" {
    for_each = each.value.dead_letter_topic != null ? [1] : []
    content {
      dead_letter_topic     = google_pubsub_topic.dead_letter_topics[each.value.dead_letter_topic].id
      max_delivery_attempts = each.value.max_delivery_attempts
    }
  }
  
  # Push configuration for HTTP endpoints
  dynamic "push_config" {
    for_each = each.value.push_config != null ? [each.value.push_config] : []
    content {
      push_endpoint = push_config.value.push_endpoint
      attributes    = push_config.value.attributes
      
      dynamic "oidc_token" {
        for_each = push_config.value.oidc_token != null ? [push_config.value.oidc_token] : []
        content {
          service_account_email = oidc_token.value.service_account_email
          audience             = oidc_token.value.audience
        }
      }
    }
  }
  
  # BigQuery configuration for direct export
  dynamic "bigquery_config" {
    for_each = each.value.bigquery_config != null ? [each.value.bigquery_config] : []
    content {
      table               = bigquery_config.value.table
      use_topic_schema    = bigquery_config.value.use_topic_schema
      write_metadata      = bigquery_config.value.write_metadata
      drop_unknown_fields = bigquery_config.value.drop_unknown_fields
    }
  }
  
  # Cloud Storage configuration for direct export
  dynamic "cloud_storage_config" {
    for_each = each.value.cloud_storage_config != null ? [each.value.cloud_storage_config] : []
    content {
      bucket          = cloud_storage_config.value.bucket
      filename_prefix = cloud_storage_config.value.filename_prefix
      filename_suffix = cloud_storage_config.value.filename_suffix
      max_duration    = cloud_storage_config.value.max_duration
      max_bytes       = cloud_storage_config.value.max_bytes
      
      dynamic "avro_config" {
        for_each = cloud_storage_config.value.avro_config != null ? [cloud_storage_config.value.avro_config] : []
        content {
          write_metadata = avro_config.value.write_metadata
        }
      }
    }
  }
  
  # Filter for message filtering
  filter = each.value.filter
  
  # Enable message ordering
  enable_message_ordering = each.value.enable_message_ordering
  
  labels = merge(var.labels, {
    subscription_type = each.value.subscription_type
    topic_name       = each.value.topic
    environment      = var.environment
  })
}

# Pub/Sub snapshots for backup and replay
resource "google_pubsub_snapshot" "data_snapshots" {
  for_each = var.pubsub_snapshots
  
  name         = each.key
  project      = var.project_id
  subscription = google_pubsub_subscription.data_subscriptions[each.value.subscription].name
  
  labels = merge(var.labels, {
    snapshot_type = each.value.snapshot_type
    subscription  = each.value.subscription
    environment   = var.environment
  })
}

# IAM bindings for topics
resource "google_pubsub_topic_iam_binding" "topic_bindings" {
  for_each = local.topic_iam_bindings
  
  project = var.project_id
  topic   = google_pubsub_topic.data_topics[each.value.topic].name
  role    = each.value.role
  members = each.value.members
  
  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# IAM bindings for subscriptions
resource "google_pubsub_subscription_iam_binding" "subscription_bindings" {
  for_each = local.subscription_iam_bindings
  
  project      = var.project_id
  subscription = google_pubsub_subscription.data_subscriptions[each.value.subscription].name
  role         = each.value.role
  members      = each.value.members
  
  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Local values for IAM binding management
locals {
  topic_iam_bindings = merge([
    for topic_key, topic_config in var.topic_iam_bindings : {
      for binding in topic_config.bindings :
      "${topic_key}-${binding.role}" => {
        topic     = topic_key
        role      = binding.role
        members   = binding.members
        condition = binding.condition
      }
    }
  ]...)
  
  subscription_iam_bindings = merge([
    for sub_key, sub_config in var.subscription_iam_bindings : {
      for binding in sub_config.bindings :
      "${sub_key}-${binding.role}" => {
        subscription = sub_key
        role         = binding.role
        members      = binding.members
        condition    = binding.condition
      }
    }
  ]...)
}