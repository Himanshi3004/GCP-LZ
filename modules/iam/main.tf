# IAM Foundation Module - Main Configuration

# Enable required APIs
resource "google_project_service" "iam_apis" {
  for_each = length(var.projects) > 0 && contains(keys(var.projects), "security") ? toset([
    "iam.googleapis.com",
    "cloudidentity.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com"
  ]) : []
  
  project = var.projects["security"].project_id
  service = each.value
  
  disable_on_destroy = false
}

# Organization-level IAM audit configuration
resource "google_logging_organization_sink" "iam_audit" {
  count            = length(var.projects) > 0 && contains(keys(var.projects), "logging") ? 1 : 0
  name             = "${var.environment}-iam-audit"
  org_id           = var.organization_id
  destination      = "logging.googleapis.com/projects/${var.projects["logging"].project_id}/logs/iam-audit"
  include_children = true
  
  filter = <<-EOT
    protoPayload.serviceName="iam.googleapis.com" OR
    protoPayload.serviceName="cloudidentity.googleapis.com" OR
    protoPayload.methodName:"iam"
  EOT
}