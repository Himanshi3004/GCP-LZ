# Essential Contacts Configuration
# Configures essential contacts for project notifications

# Essential contacts for each project
resource "google_essential_contacts_contact" "project_contacts" {
  for_each = {
    for contact_key, contact in local.all_project_contacts : contact_key => contact
  }
  
  parent                              = "projects/${google_project.projects[each.value.project_key].project_id}"
  email                              = each.value.email
  language_tag                       = "en-US"
  notification_category_subscriptions = each.value.categories
}

# Local to flatten project contacts
locals {
  all_project_contacts = merge([
    for project_key, project in var.projects : {
      for idx, contact_email in local.project_types[project.type].essential_contacts : 
      "${project_key}-${idx}" => {
        project_key = project_key
        email      = contact_email
        categories = [
          "BILLING",
          "LEGAL",
          "PRODUCT_UPDATES",
          "SECURITY",
          "SUSPENSION",
          "TECHNICAL"
        ]
      }
    }
  ]...)
  
  # Additional contacts from project configuration
  additional_contacts = merge([
    for project_key, project in var.projects : {
      for idx, contact in coalesce(project.additional_contacts, []) :
      "${project_key}-additional-${idx}" => {
        project_key = project_key
        email      = contact.email
        categories = contact.categories
      }
    }
  ]...)
}

# Merge all contacts
locals {
  all_project_contacts = merge(local.all_project_contacts, local.additional_contacts)
}

# Organization-level essential contacts
resource "google_essential_contacts_contact" "organization_contacts" {
  for_each = var.organization_contacts
  
  parent                              = "organizations/${var.organization_id}"
  email                              = each.value.email
  language_tag                       = "en-US"
  notification_category_subscriptions = each.value.categories
}

# Folder-level essential contacts
resource "google_essential_contacts_contact" "folder_contacts" {
  for_each = {
    for contact_key, contact in local.folder_contacts : contact_key => contact
  }
  
  parent                              = each.value.folder_id
  email                              = each.value.email
  language_tag                       = "en-US"
  notification_category_subscriptions = each.value.categories
}

locals {
  folder_contacts = merge([
    for folder_key, folder in var.folders : {
      for contact_key, contact in var.folder_contacts[folder_key] :
      "${folder_key}-${contact_key}" => {
        folder_id  = folder.id
        email     = contact.email
        categories = contact.categories
      }
    } if contains(keys(var.folder_contacts), folder_key)
  ]...)
}

# Contact validation
resource "null_resource" "validate_contacts" {
  for_each = local.all_project_contacts
  
  provisioner "local-exec" {
    command = "python3 -c \"import re; exit(0 if re.match(r'^[^@]+@[^@]+\\.[^@]+$', '${each.value.email}') else 1)\""
  }
  
  triggers = {
    email = each.value.email
  }
}