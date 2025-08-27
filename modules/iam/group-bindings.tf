# Group-to-Role Mappings
# Maps groups to appropriate IAM roles across the organization

# Organization-level bindings
resource "google_organization_iam_binding" "org_admin_bindings" {
  org_id = var.organization_id
  role   = "roles/resourcemanager.organizationAdmin"
  
  members = [
    "group:${google_cloud_identity_group.org_admins.group_key[0].id}"
  ]
  
  condition {
    title       = "Time-based access"
    description = "Only allow access during business hours"
    expression  = "request.time.getHours() >= 8 && request.time.getHours() <= 18"
  }
}

resource "google_organization_iam_binding" "billing_admin_bindings" {
  org_id = var.organization_id
  role   = "roles/billing.admin"
  
  members = [
    "group:${google_cloud_identity_group.billing_admins.group_key[0].id}"
  ]
}

resource "google_organization_iam_binding" "security_admin_bindings" {
  org_id = var.organization_id
  role   = "roles/securitycenter.admin"
  
  members = [
    "group:${google_cloud_identity_group.security_admins.group_key[0].id}",
    "group:${google_cloud_identity_group.security_team.group_key[0].id}"
  ]
}

# Custom role bindings
resource "google_organization_iam_binding" "custom_role_bindings" {
  for_each = {
    network_operator = {
      role = "organizations/${var.organization_id}/roles/${google_organization_iam_custom_role.network_operator.role_id}"
      members = [
        "group:${google_cloud_identity_group.network_team.group_key[0].id}"
      ]
    }
    security_analyst = {
      role = "organizations/${var.organization_id}/roles/${google_organization_iam_custom_role.security_analyst.role_id}"
      members = [
        "group:${google_cloud_identity_group.security_team.group_key[0].id}"
      ]
    }
    data_engineer = {
      role = "organizations/${var.organization_id}/roles/${google_organization_iam_custom_role.data_engineer.role_id}"
      members = [
        "group:${google_cloud_identity_group.data_team.group_key[0].id}"
      ]
    }
  }
  
  org_id = var.organization_id
  role   = each.value.role
  members = each.value.members
}

# Folder-level bindings
resource "google_folder_iam_binding" "env_admin_bindings" {
  for_each = var.folders
  
  folder = each.value.id
  role   = "roles/resourcemanager.folderAdmin"
  
  members = [
    "group:${google_cloud_identity_group.env_admins[each.key].group_key[0].id}"
  ]
}

resource "google_folder_iam_binding" "env_developer_bindings" {
  for_each = var.folders
  
  folder = each.value.id
  role   = "roles/editor"
  
  members = [
    "group:${google_cloud_identity_group.developers[each.key].group_key[0].id}"
  ]
  
  condition {
    title       = "Development hours only"
    description = "Developers can only access during development hours"
    expression  = each.key == "prod" ? "request.time.getHours() >= 9 && request.time.getHours() <= 17" : "true"
  }
}

resource "google_folder_iam_binding" "env_viewer_bindings" {
  for_each = var.folders
  
  folder = each.value.id
  role   = "roles/viewer"
  
  members = [
    "group:${google_cloud_identity_group.viewers[each.key].group_key[0].id}"
  ]
}

# Project-level bindings
resource "google_project_iam_binding" "project_specific_bindings" {
  for_each = var.projects
  
  project = each.value.project_id
  role    = "roles/editor"
  
  members = [
    "group:${google_cloud_identity_group.developers[var.environment].group_key[0].id}"
  ]
  
  # Conditional bindings based on project attributes
  dynamic "condition" {
    for_each = each.value.labels.criticality == "critical" ? [1] : []
    content {
      title       = "Critical project access"
      description = "Enhanced conditions for critical projects"
      expression  = "request.time.getHours() >= 9 && request.time.getHours() <= 17 && request.auth.access_levels.contains('accessPolicies/${var.access_policy_id}/accessLevels/trusted_users')"
    }
  }
}

# Emergency access bindings
resource "google_organization_iam_binding" "emergency_access_binding" {
  org_id = var.organization_id
  role   = "organizations/${var.organization_id}/roles/${google_organization_iam_custom_role.emergency_access.role_id}"
  
  members = [
    "group:${google_cloud_identity_group.emergency_access.group_key[0].id}"
  ]
  
  condition {
    title       = "Emergency access only"
    description = "Only allow emergency access during incidents"
    expression  = "has(request.auth.claims.emergency_ticket)"
  }
}

# Service account impersonation bindings
resource "google_service_account_iam_binding" "sa_impersonation" {
  for_each = var.service_accounts
  
  service_account_id = each.value.id
  role              = "roles/iam.serviceAccountTokenCreator"
  
  members = [
    "group:${google_cloud_identity_group.developers[var.environment].group_key[0].id}"
  ]
  
  condition {
    title       = "Workload identity only"
    description = "Only allow impersonation from workload identity"
    expression  = "request.auth.claims.sub.startsWith('system:serviceaccount:')"
  }
}

# Binding audit and change notifications
resource "google_pubsub_topic" "iam_changes" {
  project = var.project_id
  name    = "iam-binding-changes"
  
  labels = var.labels
}

resource "google_logging_organization_sink" "iam_audit_sink" {
  name        = "iam-audit-sink"
  org_id      = var.organization_id
  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.iam_changes.name}"
  
  filter = "protoPayload.serviceName=\"cloudresourcemanager.googleapis.com\" AND protoPayload.methodName=\"SetIamPolicy\""
  
  unique_writer_identity = true
}

# Grant the sink writer identity permission to publish to the topic
resource "google_pubsub_topic_iam_member" "iam_sink_writer" {
  project = var.project_id
  topic   = google_pubsub_topic.iam_changes.name
  role    = "roles/pubsub.publisher"
  member  = google_logging_organization_sink.iam_audit_sink.writer_identity
}

# Binding change notification function
resource "google_storage_bucket_object" "iam_function_zip" {
  count  = var.enable_iam_notifications ? 1 : 0
  name   = "iam-change-notifier.zip"
  bucket = var.functions_bucket
  source = "${path.module}/functions/iam-change-notifier.zip"
}

resource "google_cloudfunctions_function" "iam_change_notifier" {
  count   = var.enable_iam_notifications ? 1 : 0
  project = var.project_id
  region  = var.default_region
  name    = "iam-change-notifier"
  
  source_archive_bucket = var.functions_bucket
  source_archive_object = google_storage_bucket_object.iam_function_zip[0].name
  
  entry_point = "notifyIamChange"
  runtime     = "python39"
  
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.iam_changes.id
  }
  
  environment_variables = {
    PROJECT_ID = var.project_id
    SLACK_WEBHOOK_URL = var.slack_webhook_url
  }
  
  labels = var.labels
}

# Binding usage analytics
resource "google_monitoring_dashboard" "iam_bindings_dashboard" {
  project        = var.project_id
  dashboard_json = jsonencode({
    displayName = "IAM Bindings Dashboard"
    mosaicLayout = {
      tiles = [
        {
          width = 6
          height = 4
          widget = {
            title = "IAM Policy Changes"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"organization\" AND log_name=\"organizations/${var.organization_id}/logs/cloudaudit.googleapis.com%2Factivity\""
                    aggregation = {
                      alignmentPeriod = "3600s"
                      perSeriesAligner = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        }
      ]
    }
  })
}