terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "bigquery.googleapis.com",
    "cloudbilling.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "cloudfunctions.googleapis.com",
    "storage.googleapis.com",
    "recommender.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  disable_on_destroy = false
}

# Service account for cost management
resource "google_service_account" "cost_management" {
  project      = var.project_id
  account_id   = "cost-management-sa"
  display_name = "Cost Management Service Account"
  description  = "Service account for cost management, optimization, and FinOps operations"
}

# IAM roles for cost management service account
resource "google_project_iam_member" "cost_management_roles" {
  for_each = toset([
    "roles/bigquery.dataEditor",
    "roles/billing.viewer",
    "roles/monitoring.editor",
    "roles/pubsub.editor",
    "roles/storage.admin",
    "roles/recommender.viewer",
    "roles/cloudfunctions.developer"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cost_management.email}"
}

# Organization-level billing viewer role
resource "google_organization_iam_member" "billing_viewer" {
  count  = var.enable_cost_optimization ? 1 : 0
  org_id = split("/", var.billing_account)[1]
  role   = "roles/billing.viewer"
  member = "serviceAccount:${google_service_account.cost_management.email}"
}

# Notification channel for cost alerts
resource "google_monitoring_notification_channel" "email" {
  count        = length(var.cost_alert_emails) > 0 ? length(var.cost_alert_emails) : 0
  display_name = "Cost Alert Email - ${var.cost_alert_emails[count.index]}"
  type         = "email"
  project      = var.project_id
  
  labels = {
    email_address = var.cost_alert_emails[count.index]
  }
}