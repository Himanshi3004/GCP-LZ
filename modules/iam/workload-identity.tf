# Workload Identity Configuration
# Configures workload identity for GKE and external workloads

# Workload Identity Pool for GKE
resource "google_iam_workload_identity_pool" "gke_pool" {
  project                   = var.project_id
  workload_identity_pool_id = "gke-workload-pool"
  display_name             = "GKE Workload Identity Pool"
  description              = "Workload identity pool for GKE clusters"
  disabled                 = false
}

# Workload Identity Pool Provider for GKE
resource "google_iam_workload_identity_pool_provider" "gke_provider" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.gke_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "gke-provider"
  display_name                       = "GKE Provider"
  description                        = "Workload identity provider for GKE"
  disabled                           = false
  
  oidc {
    issuer_uri = "https://container.googleapis.com/v1/projects/${var.project_id}/locations/${var.default_region}/clusters/main-cluster"
  }
  
  attribute_mapping = {
    "google.subject"                = "assertion.sub"
    "attribute.namespace"           = "assertion['kubernetes.io']['namespace']"
    "attribute.service_account"     = "assertion['kubernetes.io']['serviceaccount']['name']"
    "attribute.pod"                = "assertion['kubernetes.io']['pod']['name']"
  }
  
  attribute_condition = "assertion.aud == 'https://container.googleapis.com/v1/projects/${var.project_id}/locations/${var.default_region}/clusters/main-cluster'"
}

# External Workload Identity Pool for CI/CD
resource "google_iam_workload_identity_pool" "cicd_pool" {
  project                   = var.project_id
  workload_identity_pool_id = "cicd-workload-pool"
  display_name             = "CI/CD Workload Identity Pool"
  description              = "Workload identity pool for CI/CD systems"
  disabled                 = false
}

# GitHub Actions Provider
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  count = var.enable_github_workload_identity ? 1 : 0
  
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.cicd_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"
  description                        = "Workload identity provider for GitHub Actions"
  disabled                           = false
  
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
  
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.actor"      = "assertion.actor"
    "attribute.ref"        = "assertion.ref"
  }
  
  attribute_condition = "assertion.repository_owner == '${var.github_organization}'"
}

# GitLab Provider
resource "google_iam_workload_identity_pool_provider" "gitlab_provider" {
  count = var.enable_gitlab_workload_identity ? 1 : 0
  
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.cicd_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "gitlab-provider"
  display_name                       = "GitLab Provider"
  description                        = "Workload identity provider for GitLab CI"
  disabled                           = false
  
  oidc {
    issuer_uri = var.gitlab_issuer_uri
  }
  
  attribute_mapping = {
    "google.subject"           = "assertion.sub"
    "attribute.project_path"   = "assertion.project_path"
    "attribute.ref"           = "assertion.ref"
    "attribute.ref_type"      = "assertion.ref_type"
  }
  
  attribute_condition = "assertion.namespace_path == '${var.gitlab_namespace}'"
}

# Service accounts for workload identity
resource "google_service_account" "workload_identity_sa" {
  for_each = var.workload_identity_service_accounts
  
  project      = var.project_id
  account_id   = each.key
  display_name = each.value.display_name
  description  = each.value.description
}

# IAM bindings for workload identity service accounts
resource "google_service_account_iam_binding" "workload_identity_binding" {
  for_each = var.workload_identity_service_accounts
  
  service_account_id = google_service_account.workload_identity_sa[each.key].name
  role              = "roles/iam.workloadIdentityUser"
  
  members = each.value.workload_identity_members
}

# Project-level IAM bindings for workload identity SAs
resource "google_project_iam_member" "workload_identity_project_roles" {
  for_each = {
    for binding in local.workload_identity_project_bindings : "${binding.sa_key}-${binding.role}" => binding
  }
  
  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.workload_identity_sa[each.value.sa_key].email}"
}

locals {
  workload_identity_project_bindings = flatten([
    for sa_key, sa_config in var.workload_identity_service_accounts : [
      for role in sa_config.project_roles : {
        sa_key = sa_key
        role   = role
      }
    ]
  ])
}

# Kubernetes service account annotations for GKE workload identity
resource "kubernetes_service_account" "workload_identity_ksa" {
  for_each = var.kubernetes_service_accounts
  
  metadata {
    name      = each.key
    namespace = each.value.namespace
    
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.workload_identity_sa[each.value.gsa_name].email
    }
  }
  
  depends_on = [var.gke_cluster]
}

# Workload identity federation for external identity providers
resource "google_iam_workload_identity_pool" "external_pool" {
  count = var.enable_external_workload_identity ? 1 : 0
  
  project                   = var.project_id
  workload_identity_pool_id = "external-workload-pool"
  display_name             = "External Workload Identity Pool"
  description              = "Workload identity pool for external identity providers"
  disabled                 = false
}

# AWS Provider for multi-cloud workloads
resource "google_iam_workload_identity_pool_provider" "aws_provider" {
  count = var.enable_aws_workload_identity ? 1 : 0
  
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.external_pool[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "aws-provider"
  display_name                       = "AWS Provider"
  description                        = "Workload identity provider for AWS workloads"
  disabled                           = false
  
  aws {
    account_id = var.aws_account_id
  }
  
  attribute_mapping = {
    "google.subject"        = "assertion.arn"
    "attribute.aws_role"    = "assertion.arn.extract('assumed-role/{role}/')"
    "attribute.aws_session" = "assertion.arn.extract('assumed-role/{role}/{session}')"
  }
  
  attribute_condition = "assertion.arn.startsWith('arn:aws:sts::${var.aws_account_id}:assumed-role/${var.aws_role_prefix}')"
}

# Azure Provider for multi-cloud workloads
resource "google_iam_workload_identity_pool_provider" "azure_provider" {
  count = var.enable_azure_workload_identity ? 1 : 0
  
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.external_pool[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "azure-provider"
  display_name                       = "Azure Provider"
  description                        = "Workload identity provider for Azure workloads"
  disabled                           = false
  
  oidc {
    issuer_uri = "https://login.microsoftonline.com/${var.azure_tenant_id}/v2.0"
  }
  
  attribute_mapping = {
    "google.subject"      = "assertion.sub"
    "attribute.tenant_id" = "assertion.tid"
    "attribute.app_id"    = "assertion.appid"
  }
  
  attribute_condition = "assertion.tid == '${var.azure_tenant_id}'"
}

# Identity mapping documentation
resource "google_storage_bucket_object" "identity_mapping_docs" {
  bucket  = var.documentation_bucket
  name    = "workload-identity/identity-mappings.md"
  content = templatefile("${path.module}/templates/identity-mappings.md.tpl", {
    gke_pool_id    = google_iam_workload_identity_pool.gke_pool.name
    cicd_pool_id   = google_iam_workload_identity_pool.cicd_pool.name
    service_accounts = var.workload_identity_service_accounts
    github_enabled = var.enable_github_workload_identity
    gitlab_enabled = var.enable_gitlab_workload_identity
    aws_enabled    = var.enable_aws_workload_identity
    azure_enabled  = var.enable_azure_workload_identity
  })
}

# Workload identity usage monitoring
resource "google_monitoring_alert_policy" "workload_identity_usage" {
  project      = var.project_id
  display_name = "Workload Identity Usage Alert"
  combiner     = "OR"
  
  conditions {
    display_name = "High workload identity token requests"
    
    condition_threshold {
      filter          = "resource.type=\"iam_service_account\" AND metric.type=\"iam.googleapis.com/service_account/key/authn_events_count\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 1000
      
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