# Comprehensive Log Sinks
# Creates organization-level and project-level log sinks for centralized logging

# Organization-level aggregated log sink
resource "google_logging_organization_sink" "org_audit_sink" {
  name        = "org-audit-logs"
  org_id      = var.organization_id
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.audit_logs.dataset_id}"
  
  filter = <<-EOT
    logName:"cloudaudit.googleapis.com" OR
    logName:"access_transparency" OR
    logName:"data_access" OR
    protoPayload.serviceName="cloudresourcemanager.googleapis.com" OR
    protoPayload.serviceName="iam.googleapis.com" OR
    protoPayload.serviceName="compute.googleapis.com"
  EOT
  
  unique_writer_identity = true
  
  bigquery_options {
    use_partitioned_tables = true
  }
}

resource "google_logging_organization_sink" "org_security_sink" {
  name        = "org-security-logs"
  org_id      = var.organization_id
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.security_logs.dataset_id}"
  
  filter = <<-EOT
    logName:"securitycenter.googleapis.com" OR
    logName:"cloudkms.googleapis.com" OR
    logName:"dlp.googleapis.com" OR
    logName:"binaryauthorization.googleapis.com" OR
    severity>=ERROR
  EOT
  
  unique_writer_identity = true
  
  bigquery_options {
    use_partitioned_tables = true
  }
}

resource "google_logging_organization_sink" "org_network_sink" {
  name        = "org-network-logs"
  org_id      = var.organization_id
  destination = "storage.googleapis.com/${google_storage_bucket.network_logs.name}"
  
  filter = <<-EOT
    resource.type="gce_subnetwork" OR
    resource.type="vpc_flow" OR
    resource.type="firewall_rule" OR
    logName:"compute.googleapis.com/firewall" OR
    logName:"dns.googleapis.com"
  EOT
  
  unique_writer_identity = true
}

# Folder-level log sinks
resource "google_logging_folder_sink" "folder_sinks" {
  for_each = var.folders
  
  name        = "${each.key}-folder-logs"
  folder      = each.value.id
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.folder_logs[each.key].dataset_id}"
  
  filter = <<-EOT
    NOT logName:"cloudaudit.googleapis.com/data_access" AND
    NOT logName:"compute.googleapis.com/vpc_flows" AND
    severity>=INFO
  EOT
  
  unique_writer_identity = true
  
  bigquery_options {
    use_partitioned_tables = true
  }
}

# Project-level sinks for application logs
resource "google_logging_project_sink" "project_app_sinks" {
  for_each = var.projects
  
  name        = "${each.key}-app-logs"
  project     = each.value.project_id
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.application_logs.dataset_id}"
  
  filter = <<-EOT
    NOT logName:"cloudaudit.googleapis.com" AND
    NOT resource.type="vpc_flow" AND
    (
      resource.type="gce_instance" OR
      resource.type="k8s_container" OR
      resource.type="cloud_run_revision" OR
      resource.type="cloud_function"
    )
  EOT
  
  unique_writer_identity = true
  
  bigquery_options {
    use_partitioned_tables = true
  }
}

# BigQuery datasets for log storage
resource "google_bigquery_dataset" "audit_logs" {
  project    = var.project_id
  dataset_id = "audit_logs"
  location   = var.default_region
  
  description = "Organization audit logs"
  
  default_table_expiration_ms = 31536000000  # 1 year
  
  labels = merge(var.labels, {
    log_type = "audit"
  })
}

resource "google_bigquery_dataset" "security_logs" {
  project    = var.project_id
  dataset_id = "security_logs"
  location   = var.default_region
  
  description = "Security-related logs"
  
  default_table_expiration_ms = 94608000000  # 3 years
  
  labels = merge(var.labels, {
    log_type = "security"
  })
}

resource "google_bigquery_dataset" "folder_logs" {
  for_each = var.folders
  
  project    = var.project_id
  dataset_id = "${each.key}_folder_logs"
  location   = var.default_region
  
  description = "Logs for ${each.key} folder"
  
  default_table_expiration_ms = 7776000000  # 90 days
  
  labels = merge(var.labels, {
    log_type = "folder"
    folder   = each.key
  })
}

resource "google_bigquery_dataset" "application_logs" {
  project    = var.project_id
  dataset_id = "application_logs"
  location   = var.default_region
  
  description = "Application logs from all projects"
  
  default_table_expiration_ms = 2592000000  # 30 days
  
  labels = merge(var.labels, {
    log_type = "application"
  })
}

# Cloud Storage bucket for network logs
resource "google_storage_bucket" "network_logs" {
  project  = var.project_id
  name     = "${var.project_id}-network-logs"
  location = var.default_region
  
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
  
  labels = merge(var.labels, {
    log_type = "network"
  })
}

# IAM permissions for log sinks
resource "google_bigquery_dataset_iam_member" "audit_sink_writer" {
  dataset_id = google_bigquery_dataset.audit_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_organization_sink.org_audit_sink.writer_identity
}

resource "google_bigquery_dataset_iam_member" "security_sink_writer" {
  dataset_id = google_bigquery_dataset.security_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_organization_sink.org_security_sink.writer_identity
}

resource "google_storage_bucket_iam_member" "network_sink_writer" {
  bucket = google_storage_bucket.network_logs.name
  role   = "roles/storage.objectCreator"
  member = google_logging_organization_sink.org_network_sink.writer_identity
}

resource "google_bigquery_dataset_iam_member" "folder_sink_writers" {
  for_each = var.folders
  
  dataset_id = google_bigquery_dataset.folder_logs[each.key].dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_folder_sink.folder_sinks[each.key].writer_identity
}

resource "google_bigquery_dataset_iam_member" "app_sink_writers" {
  for_each = var.projects
  
  dataset_id = google_bigquery_dataset.application_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.project_app_sinks[each.key].writer_identity
}

# Log sampling for cost control
resource "google_logging_organization_sink" "sampled_logs" {
  name        = "sampled-logs"
  org_id      = var.organization_id
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.sampled_logs.dataset_id}"
  
  filter = <<-EOT
    sample(insertId, 0.1) AND
    NOT logName:"cloudaudit.googleapis.com" AND
    severity>=INFO
  EOT
  
  unique_writer_identity = true
  
  bigquery_options {
    use_partitioned_tables = true
  }
}

resource "google_bigquery_dataset" "sampled_logs" {
  project    = var.project_id
  dataset_id = "sampled_logs"
  location   = var.default_region
  
  description = "Sampled logs for cost optimization"
  
  default_table_expiration_ms = 604800000  # 7 days
  
  labels = merge(var.labels, {
    log_type = "sampled"
  })
}

resource "google_bigquery_dataset_iam_member" "sampled_sink_writer" {
  dataset_id = google_bigquery_dataset.sampled_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_organization_sink.sampled_logs.writer_identity
}

# Log-based metrics
resource "google_logging_metric" "error_rate" {
  name   = "error_rate"
  filter = "severity>=ERROR"
  
  metric_descriptor {
    metric_kind = "GAUGE"
    value_type  = "DOUBLE"
    unit        = "1"
    labels {
      key         = "service"
      value_type  = "STRING"
      description = "Service name"
    }
  }
  
  label_extractors = {
    "service" = "EXTRACT(protoPayload.serviceName)"
  }
  
  value_extractor = "EXTRACT(protoPayload.status.code)"
}

resource "google_logging_metric" "security_events" {
  name   = "security_events"
  filter = "logName:\"securitycenter.googleapis.com\" OR logName:\"cloudkms.googleapis.com\""
  
  metric_descriptor {
    metric_kind = "COUNTER"
    value_type  = "INT64"
    unit        = "1"
    labels {
      key         = "finding_type"
      value_type  = "STRING"
      description = "Type of security finding"
    }
  }
  
  label_extractors = {
    "finding_type" = "EXTRACT(jsonPayload.finding.category)"
  }
}

# Real-time log analysis with Pub/Sub
resource "google_pubsub_topic" "log_analysis" {
  project = var.project_id
  name    = "log-analysis"
  
  labels = var.labels
}

resource "google_logging_organization_sink" "realtime_analysis" {
  name        = "realtime-log-analysis"
  org_id      = var.organization_id
  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.log_analysis.name}"
  
  filter = <<-EOT
    severity>=WARNING OR
    logName:"securitycenter.googleapis.com" OR
    protoPayload.authenticationInfo.principalEmail!=""
  EOT
  
  unique_writer_identity = true
}

resource "google_pubsub_topic_iam_member" "realtime_sink_writer" {
  project = var.project_id
  topic   = google_pubsub_topic.log_analysis.name
  role    = "roles/pubsub.publisher"
  member  = google_logging_organization_sink.realtime_analysis.writer_identity
}

# Log retention policies
resource "google_logging_organization_settings" "org_log_settings" {
  org_id           = var.organization_id
  retention_days   = 400  # Maximum retention
  storage_location = var.default_region
}