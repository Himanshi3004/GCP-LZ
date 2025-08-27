# Create a management project for organization-level resources
resource "google_project" "management" {
  name            = "${var.organization_name}-management-${var.environment}"
  project_id      = "${var.organization_name}-mgmt-${var.environment}-${random_id.project_suffix.hex}"
  billing_account = var.billing_account
  org_id          = var.organization_id
  
  labels = var.labels
  
  auto_create_network = false
}

resource "random_id" "project_suffix" {
  byte_length = 2
}

# Enable required APIs in management project
resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ])
  
  project = google_project.management.project_id
  service = each.value
  
  disable_on_destroy = false
}

# Organization-level audit logging
resource "google_logging_organization_sink" "audit_logs" {
  count           = var.enable_audit_logs ? 1 : 0
  name            = "${var.organization_name}-audit-logs"
  org_id          = var.organization_id
  destination     = "logging.googleapis.com/projects/${google_project.management.project_id}/logs/audit"
  include_children = true
  
  filter = <<-EOT
    logName:"cloudaudit.googleapis.com" OR
    logName:"data_access" OR
    logName:"activity"
  EOT
  
  depends_on = [google_project_service.required_apis]
}