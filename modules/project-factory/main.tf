# Random suffix for unique project IDs
resource "random_id" "project_suffix" {
  for_each = var.projects
  
  byte_length = 2
  keepers = {
    project_name = each.key
  }
}

# Project creation with standardized naming
resource "google_project" "projects" {
  for_each = var.projects

  name            = "${var.name_prefix}-${each.key}"
  project_id      = "${var.name_prefix}-${each.key}-${random_id.project_suffix[each.key].hex}"
  billing_account = var.billing_account
  folder_id       = try(var.folders.departments["${var.environment}-${each.value.department}"].id, null)
  
  labels = merge(var.labels, {
    department   = each.value.department
    project_type = each.key
  })
  
  auto_create_network = false
}

# Enable required APIs for each project
resource "google_project_service" "project_apis" {
  for_each = {
    for combo in flatten([
      for proj_key, proj_config in var.projects : [
        for api in proj_config.apis : {
          project = proj_key
          api     = api
          key     = "${proj_key}-${api}"
        }
      ]
    ]) : combo.key => combo
  }

  project = google_project.projects[each.value.project].project_id
  service = each.value.api

  disable_on_destroy = false
  depends_on         = [google_project.projects]
}

# Create service accounts for each project
resource "google_service_account" "project_sa" {
  for_each = var.projects

  account_id   = "${each.key}-sa"
  display_name = "Service Account for ${each.key} project"
  description  = "Default service account for ${each.key} project"
  project      = google_project.projects[each.key].project_id

  depends_on = [google_project_service.project_apis]
}

# Budget configuration moved to budgets.tf