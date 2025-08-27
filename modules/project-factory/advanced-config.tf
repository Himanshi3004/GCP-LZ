# Essential contacts configuration
resource "google_essential_contacts_contact" "project_contacts" {
  for_each = {
    for combo in flatten([
      for proj_key, proj_config in var.projects : [
        for contact in try(local.project_types[proj_key].essential_contacts, []) : {
          project = proj_key
          email   = contact
          key     = "${proj_key}-${contact}"
        }
      ]
    ]) : combo.key => combo
  }

  parent                              = google_project.projects[each.value.project].id
  email                              = each.value.email
  language_tag                       = "en"
  notification_category_subscriptions = ["ALL"]

  depends_on = [google_project.projects]
}

# Project liens for critical projects
resource "google_resource_manager_lien" "project_liens" {
  for_each = {
    for proj_key, proj_config in var.projects :
    proj_key => proj_config
    if try(local.project_types[proj_key].deletion_protection, false)
  }

  parent       = "projects/${google_project.projects[each.key].number}"
  restrictions = ["resourcemanager.projects.delete"]
  origin       = "terraform-landing-zone"
  reason       = try(local.project_types[each.key].lien_reason, "Protected by landing zone")

  depends_on = [google_project.projects]
}

# Default network deletion (already handled in main.tf with auto_create_network = false)
# This is a placeholder for additional network configuration if needed

# Project-level organization policy exceptions
resource "google_project_organization_policy" "project_exceptions" {
  for_each = var.project_policy_exceptions

  project    = google_project.projects[each.value.project].project_id
  constraint = each.value.constraint

  dynamic "list_policy" {
    for_each = each.value.type == "list" ? [1] : []
    content {
      inherit_from_parent = try(each.value.inherit_from_parent, false)
      
      dynamic "allow" {
        for_each = try(each.value.allowed_values, [])
        content {
          values = allow.value
        }
      }
      
      dynamic "deny" {
        for_each = try(each.value.denied_values, [])
        content {
          values = deny.value
        }
      }
    }
  }

  dynamic "boolean_policy" {
    for_each = each.value.type == "boolean" ? [1] : []
    content {
      enforced = each.value.enforced
    }
  }

  depends_on = [google_project.projects]
}

# Automated project documentation
resource "local_file" "project_documentation" {
  for_each = var.projects

  filename = "${path.module}/docs/${each.key}-project.md"
  content = templatefile("${path.module}/templates/project-doc.tpl", {
    project_name   = each.key
    project_id     = google_project.projects[each.key].project_id
    project_number = google_project.projects[each.key].number
    department     = each.value.department
    project_type   = local.project_types[each.key]
    apis          = each.value.apis
    budget_amount = each.value.budget_amount
    labels        = merge(var.labels, local.project_types[each.key].labels, {
      department   = each.value.department
      project_type = each.key
    })
  })

  depends_on = [google_project.projects]
}