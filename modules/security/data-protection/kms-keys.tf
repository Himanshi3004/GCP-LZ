# KMS Key Management
# Creates and manages encryption keys for different services and environments

# Key rings per environment
resource "google_kms_key_ring" "env_key_rings" {
  for_each = toset(["dev", "staging", "prod"])
  
  project  = var.project_id
  name     = "${var.organization_name}-${each.key}-keyring"
  location = var.default_region
}

# Application-layer encryption keys
resource "google_kms_crypto_key" "application_keys" {
  for_each = {
    for combo in local.app_key_combinations : "${combo.env}-${combo.purpose}" => combo
  }
  
  name            = "${each.value.purpose}-key"
  key_ring        = google_kms_key_ring.env_key_rings[each.value.env].id
  rotation_period = each.value.rotation_period
  purpose         = "ENCRYPT_DECRYPT"
  
  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = each.value.env == "prod" ? "HSM" : "SOFTWARE"
  }
  
  labels = merge(var.labels, {
    environment = each.value.env
    purpose     = each.value.purpose
  })
}

locals {
  app_key_combinations = flatten([
    for env in ["dev", "staging", "prod"] : [
      for purpose in ["database", "storage", "secrets", "logs"] : {
        env             = env
        purpose         = purpose
        rotation_period = purpose == "secrets" ? "2592000s" : "7776000s"  # 30 days for secrets, 90 days for others
      }
    ]
  ])
  
  service_key_combinations = flatten([
    for env in ["dev", "staging", "prod"] : [
      for service in ["bigquery", "storage", "compute", "pubsub", "dataflow"] : {
        env     = env
        service = service
      }
    ]
  ])
}

# Service-specific CMEK keys
resource "google_kms_crypto_key" "service_keys" {
  for_each = {
    for combo in local.service_key_combinations : "${combo.env}-${combo.service}" => combo
  }
  
  name            = "${each.value.service}-cmek-key"
  key_ring        = google_kms_key_ring.env_key_rings[each.value.env].id
  rotation_period = "7776000s"  # 90 days
  purpose         = "ENCRYPT_DECRYPT"
  
  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = each.value.env == "prod" ? "HSM" : "SOFTWARE"
  }
  
  labels = merge(var.labels, {
    environment = each.value.env
    service     = each.value.service
    cmek        = "true"
  })
}



# HSM-backed keys for critical data
resource "google_kms_crypto_key" "critical_keys" {
  for_each = toset(["prod"])
  
  name            = "critical-data-key"
  key_ring        = google_kms_key_ring.env_key_rings[each.key].id
  rotation_period = "2592000s"  # 30 days for critical data
  purpose         = "ENCRYPT_DECRYPT"
  
  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "HSM"
  }
  
  labels = merge(var.labels, {
    environment = each.key
    criticality = "critical"
    hsm         = "true"
  })
}

# Key access policies
resource "google_kms_crypto_key_iam_binding" "key_access_policies" {
  for_each = local.key_access_bindings
  
  crypto_key_id = each.value.key_id
  role          = each.value.role
  members       = each.value.members
  
  condition {
    title       = "Time-based access"
    description = "Restrict key access to business hours for production"
    expression  = each.value.env == "prod" ? "request.time.getHours() >= 8 && request.time.getHours() <= 18" : "true"
  }
}

locals {
  key_access_bindings = merge([
    # Application key bindings
    for key_name, key in google_kms_crypto_key.application_keys : {
      "${key_name}-encrypter" = {
        key_id = key.id
        role   = "roles/cloudkms.cryptoKeyEncrypter"
        members = [
          "serviceAccount:${var.application_service_accounts[split("-", key_name)[1]].email}"
        ]
        env = split("-", key_name)[0]
      }
      "${key_name}-decrypter" = {
        key_id = key.id
        role   = "roles/cloudkms.cryptoKeyDecrypter"
        members = [
          "serviceAccount:${var.application_service_accounts[split("-", key_name)[1]].email}"
        ]
        env = split("-", key_name)[0]
      }
    }
  ]...)
}

# Key usage policies
resource "google_kms_crypto_key_iam_policy" "key_usage_policies" {
  for_each = google_kms_crypto_key.critical_keys
  
  crypto_key_id = each.value.id
  policy_data   = data.google_iam_policy.critical_key_policy.policy_data
}

data "google_iam_policy" "critical_key_policy" {
  binding {
    role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    members = [
      "group:security-admins@${var.domain_name}"
    ]
    
    condition {
      title       = "Critical key access with justification"
      description = "Requires access justification for critical keys"
      expression  = "has(request.auth.access_levels) && 'accessPolicies/${var.access_policy_id}/accessLevels/high_trust' in request.auth.access_levels"
    }
  }
  
  binding {
    role = "roles/cloudkms.admin"
    members = [
      "group:security-admins@${var.domain_name}"
    ]
  }
}

# Key access justifications
resource "google_access_context_manager_access_level" "key_access_justification" {
  parent = "accessPolicies/${var.access_policy_id}"
  name   = "accessPolicies/${var.access_policy_id}/accessLevels/key_access_justification"
  title  = "Key Access Justification"
  
  basic {
    conditions {
      required_access_levels = [
        "accessPolicies/${var.access_policy_id}/accessLevels/high_trust"
      ]
    }
  }
}

# Key inventory and tracking
resource "google_storage_bucket_object" "key_inventory" {
  bucket  = var.security_bucket
  name    = "kms/key-inventory-${formatdate("YYYY-MM-DD", timestamp())}.json"
  content = jsonencode({
    timestamp = timestamp()
    key_rings = {
      for env, ring in google_kms_key_ring.env_key_rings : env => {
        id       = ring.id
        location = ring.location
        keys = {
          application = {
            for key_name, key in google_kms_crypto_key.application_keys : 
            key_name => {
              id              = key.id
              rotation_period = key.rotation_period
              protection_level = key.version_template[0].protection_level
            } if startswith(key_name, env)
          }
          service = {
            for key_name, key in google_kms_crypto_key.service_keys : 
            key_name => {
              id              = key.id
              rotation_period = key.rotation_period
              protection_level = key.version_template[0].protection_level
            } if startswith(key_name, env)
          }
        }
      }
    }
    critical_keys = {
      for key_name, key in google_kms_crypto_key.critical_keys : key_name => {
        id              = key.id
        rotation_period = key.rotation_period
        protection_level = key.version_template[0].protection_level
      }
    }
  })
}

# Key usage monitoring
resource "google_monitoring_alert_policy" "key_usage_alerts" {
  project      = var.project_id
  display_name = "KMS Key Usage Alert"
  combiner     = "OR"
  
  conditions {
    display_name = "High key usage"
    
    condition_threshold {
      filter          = "resource.type=\"kms_key\" AND metric.type=\"cloudkms.googleapis.com/api/request_count\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 1000
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields = ["resource.labels.key_id"]
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# Key rotation automation
resource "google_cloud_scheduler_job" "key_rotation_check" {
  project  = var.project_id
  region   = var.default_region
  name     = "kms-key-rotation-check"
  
  description = "Check for keys that need rotation"
  schedule    = "0 9 * * 1"  # Weekly on Monday at 9 AM
  time_zone   = "UTC"
  
  pubsub_target {
    topic_name = google_pubsub_topic.key_rotation.id
    data       = base64encode(jsonencode({
      action = "check_rotation"
    }))
  }
}

resource "google_pubsub_topic" "key_rotation" {
  project = var.project_id
  name    = "kms-key-rotation"
  
  labels = var.labels
}