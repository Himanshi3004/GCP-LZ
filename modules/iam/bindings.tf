# Organization-level IAM bindings
resource "google_organization_iam_binding" "group_bindings" {
  for_each = merge([
    for group_key, group in var.groups : {
      for role in group.roles : "${group_key}-${role}" => {
        group_key = group_key
        role      = role
      }
    }
  ]...)

  org_id = var.organization_id
  role   = each.value.role
  
  members = [
    "group:${each.value.group_key}@${var.domain_name}"
  ]
  
  condition {
    title       = "Environment Access"
    description = "Access limited to ${var.environment} environment"
    expression  = "resource.name.startsWith('projects/${var.environment}')"
  }
}

# Custom role bindings
resource "google_organization_iam_binding" "custom_role_bindings" {
  for_each = {
    network_admin     = google_organization_iam_custom_role.network_admin.name
    security_reviewer = google_organization_iam_custom_role.security_reviewer.name
    project_creator   = google_organization_iam_custom_role.project_creator.name
  }

  org_id = var.organization_id
  role   = each.value
  
  members = [
    "group:platform-admins@${var.domain_name}"
  ]
}

# Project-level IAM bindings
resource "google_project_iam_binding" "project_bindings" {
  for_each = var.projects

  project = each.value.project_id
  role    = "roles/viewer"
  
  members = [
    "group:developers@${var.domain_name}",
    "serviceAccount:${each.key}-sa@${each.value.project_id}.iam.gserviceaccount.com"
  ]
}