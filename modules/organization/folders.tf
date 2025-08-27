# Organization folder hierarchy: Organization → Environment → Department → Team → Project

# Environment folders (dev, staging, prod)
resource "google_folder" "environments" {
  for_each     = toset(["dev", "staging", "prod"])
  display_name = "${var.organization_name}-${each.key}"
  parent       = "organizations/${var.organization_id}"
}

# Department folders under each environment
locals {
  departments = ["security", "networking", "data", "compute", "shared-services"]
  teams = ["platform", "application", "infrastructure", "analytics"]
  
  env_dept_combinations = flatten([
    for env in ["dev", "staging", "prod"] : [
      for dept in local.departments : {
        env  = env
        dept = dept
        key  = "${env}-${dept}"
      }
    ]
  ])
  
  # Team folders under departments (only for specific departments)
  env_dept_team_combinations = flatten([
    for env in ["dev", "staging", "prod"] : [
      for dept in ["compute", "data"] : [  # Only create teams under compute and data
        for team in local.teams : {
          env  = env
          dept = dept
          team = team
          key  = "${env}-${dept}-${team}"
        }
      ]
    ]
  ])
}

resource "google_folder" "departments" {
  for_each     = { for combo in local.env_dept_combinations : combo.key => combo }
  display_name = each.value.dept
  parent       = google_folder.environments[each.value.env].name
}

resource "google_folder" "teams" {
  for_each     = { for combo in local.env_dept_team_combinations : combo.key => combo }
  display_name = each.value.team
  parent       = google_folder.departments["${each.value.env}-${each.value.dept}"].name
}

# Environment-specific IAM bindings
resource "google_folder_iam_binding" "environment_viewers" {
  for_each = google_folder.environments
  folder   = each.value.name
  role     = "roles/resourcemanager.folderViewer"
  
  members = [
    "domain:${var.domain_name}",
    "group:${var.organization_name}-${each.key}-viewers@${var.domain_name}",
  ]
}

resource "google_folder_iam_binding" "environment_billing_users" {
  for_each = google_folder.environments
  folder   = each.value.name
  role     = "roles/billing.user"
  
  members = [
    "group:${var.organization_name}-${each.key}-developers@${var.domain_name}",
    "group:${var.organization_name}-${each.key}-admins@${var.domain_name}",
  ]
}

# Department-specific IAM bindings
resource "google_folder_iam_binding" "department_admins" {
  for_each = google_folder.departments
  folder   = each.value.name
  role     = "roles/resourcemanager.folderAdmin"
  
  members = [
    "group:${var.organization_name}-${each.value.display_name}-admins@${var.domain_name}",
  ]
}

resource "google_folder_iam_binding" "department_editors" {
  for_each = google_folder.departments
  folder   = each.value.name
  role     = "roles/resourcemanager.folderEditor"
  
  members = [
    "group:${var.organization_name}-${each.value.display_name}-editors@${var.domain_name}",
  ]
}

# Security department gets additional permissions
resource "google_folder_iam_binding" "security_admin" {
  for_each = { for k, v in google_folder.departments : k => v if endswith(k, "-security") }
  folder   = each.value.name
  role     = "roles/securitycenter.admin"
  
  members = [
    "group:${var.organization_name}-security-team@${var.domain_name}",
  ]
}

# Networking department gets network admin permissions
resource "google_folder_iam_binding" "networking_admin" {
  for_each = { for k, v in google_folder.departments : k => v if endswith(k, "-networking") }
  folder   = each.value.name
  role     = "roles/compute.networkAdmin"
  
  members = [
    "group:${var.organization_name}-networking-team@${var.domain_name}",
  ]
}