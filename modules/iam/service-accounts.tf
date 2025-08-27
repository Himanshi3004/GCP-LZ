# Enhanced Service Account Management with Lifecycle Controls

# Workload Identity service accounts with naming standards
resource "google_service_account" "workload_identity_sa" {
  for_each = var.projects

  project      = each.value.project_id
  account_id   = "${var.organization_name}-${each.key}-wi-sa"
  display_name = "Workload Identity SA for ${each.key}"
  description  = "Service account for workload identity in ${each.key} project - Created: ${timestamp()}"
  
  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}

# Application-specific service accounts
resource "google_service_account" "app_service_accounts" {
  for_each = var.application_service_accounts

  project      = var.projects[each.value.project].project_id
  account_id   = "${var.organization_name}-${each.key}-app-sa"
  display_name = each.value.display_name
  description  = "${each.value.description} - Created: ${timestamp()}"
}

# CI/CD service accounts
resource "google_service_account" "cicd_service_accounts" {
  for_each = toset(["dev", "staging", "prod"])

  project      = var.projects["cicd"].project_id
  account_id   = "${var.organization_name}-${each.key}-cicd-sa"
  display_name = "CI/CD Service Account for ${each.key}"
  description  = "Service account for CI/CD deployments to ${each.key} environment"
}

# Monitoring service accounts
resource "google_service_account" "monitoring_sa" {
  count = contains(keys(var.projects), "monitoring") ? 1 : 0

  project      = var.projects["monitoring"].project_id
  account_id   = "${var.organization_name}-monitoring-sa"
  display_name = "Monitoring Service Account"
  description  = "Service account for monitoring and alerting services"
}

# Security service accounts
resource "google_service_account" "security_sa" {
  count = contains(keys(var.projects), "security") ? 1 : 0

  project      = var.projects["security"].project_id
  account_id   = "${var.organization_name}-security-sa"
  display_name = "Security Service Account"
  description  = "Service account for security scanning and compliance"
}

# Service account IAM policies with impersonation chains
resource "google_service_account_iam_policy" "workload_sa_policy" {
  for_each = var.enable_workload_identity ? google_service_account.workload_identity_sa : {}

  service_account_id = each.value.name
  policy_data        = data.google_iam_policy.workload_sa_policy[each.key].policy_data
}

data "google_iam_policy" "workload_sa_policy" {
  for_each = var.enable_workload_identity ? var.projects : {}

  # Workload Identity binding
  binding {
    role = "roles/iam.workloadIdentityUser"
    members = [
      "serviceAccount:${each.value.project_id}.svc.id.goog[default/workload-identity-sa]",
      "serviceAccount:${each.value.project_id}.svc.id.goog[kube-system/workload-identity-sa]"
    ]
  }

  # Service account impersonation for CI/CD
  binding {
    role = "roles/iam.serviceAccountTokenCreator"
    members = [
      "serviceAccount:${google_service_account.cicd_service_accounts[each.key].email}"
    ]
    
    condition {
      title       = "CI/CD Impersonation"
      description = "Allow CI/CD to impersonate workload identity SA"
      expression  = "request.time.getHours() >= 0 && request.time.getHours() <= 23"
    }
  }
}

# Service account key rotation policy (using Cloud Scheduler)
resource "google_cloud_scheduler_job" "sa_key_rotation" {
  for_each = var.enable_key_rotation ? google_service_account.workload_identity_sa : {}

  project   = each.value.project
  region    = var.default_region
  name      = "${each.key}-sa-key-rotation"
  
  schedule  = "0 2 1 * *" # Monthly at 2 AM
  time_zone = "UTC"
  
  http_target {
    uri         = "https://cloudresourcemanager.googleapis.com/v1/projects/${each.value.project}/serviceAccounts/${each.value.email}:generateAccessToken"
    http_method = "POST"
    
    oauth_token {
      service_account_email = each.value.email
    }
  }
}

# Service account usage tracking
resource "google_logging_project_sink" "sa_usage_tracking" {
  for_each = google_service_account.workload_identity_sa

  project     = each.value.project
  name        = "${each.key}-sa-usage-sink"
  destination = "logging.googleapis.com/projects/${var.projects["logging"].project_id}/logs/sa-usage-${each.key}"
  
  filter = <<-EOT
    protoPayload.authenticationInfo.principalEmail="${each.value.email}" OR
    protoPayload.serviceAccountDelegationInfo.firstPartyPrincipal.principalEmail="${each.value.email}"
  EOT
  
  unique_writer_identity = true
}

# Service account inventory
resource "google_storage_bucket_object" "sa_inventory" {
  bucket  = var.inventory_bucket
  name    = "service-accounts/inventory-${formatdate("YYYY-MM-DD", timestamp())}.json"
  content = jsonencode({
    timestamp = timestamp()
    service_accounts = {
      for sa_key, sa in google_service_account.workload_identity_sa : sa_key => {
        email       = sa.email
        project     = sa.project
        unique_id   = sa.unique_id
        created     = timestamp()
        description = sa.description
      }
    }
  })
  
  lifecycle {
    ignore_changes = [content]
  }
}

# Deny policies for critical service accounts
resource "google_iam_deny_policy" "critical_sa_deny" {
  count = contains(keys(var.projects), "security") ? 1 : 0

  parent   = "projects/${var.projects["security"].project_id}"
  name     = "critical-sa-deny-policy"
  
  rules {
    deny_rule {
      denied_principals = ["principalSet://goog/public:all"]
      denied_permissions = [
        "iam.serviceAccounts.actAs",
        "iam.serviceAccounts.getAccessToken",
        "iam.serviceAccounts.implicitDelegation"
      ]
      
      exception_principals = [
        "group:platform-admins@${var.domain_name}",
        "group:security-team@${var.domain_name}"
      ]
    }
  }
}

# Service account alerts for suspicious activity
resource "google_monitoring_alert_policy" "sa_suspicious_activity" {
  count = contains(keys(var.projects), "monitoring") ? 1 : 0

  project      = var.projects["monitoring"].project_id
  display_name = "Service Account Suspicious Activity"
  
  conditions {
    display_name = "Unusual service account usage"
    
    condition_threshold {
      filter          = "resource.type=\"service_account\" AND protoPayload.methodName=\"google.iam.admin.v1.CreateServiceAccountKey\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 5
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# Local variables for service account management
locals {
  # Service account naming convention
  sa_naming_pattern = "${var.organization_name}-{project}-{type}-sa"
  
  # Service account lifecycle stages
  sa_lifecycle_stages = ["active", "deprecated", "disabled", "deleted"]
  
  # Service account types
  sa_types = ["workload-identity", "application", "cicd", "monitoring", "security"]
  
  # All service accounts for inventory
  all_service_accounts = merge(
    google_service_account.workload_identity_sa,
    google_service_account.app_service_accounts,
    google_service_account.cicd_service_accounts,
    contains(keys(var.projects), "monitoring") ? { monitoring = google_service_account.monitoring_sa[0] } : {},
    contains(keys(var.projects), "security") ? { security = google_service_account.security_sa[0] } : {}
  )
}