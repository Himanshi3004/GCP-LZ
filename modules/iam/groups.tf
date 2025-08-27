# Group Structure for RBAC
# Creates and manages Google Groups for role-based access control

# Admin groups
resource "google_cloud_identity_group" "org_admins" {
  display_name = "${var.organization_name} Organization Admins"
  description  = "Organization administrators with full access"
  
  parent = "customers/${var.customer_id}"
  
  group_key {
    id = "org-admins@${var.domain_name}"
  }
  
  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

resource "google_cloud_identity_group" "billing_admins" {
  display_name = "${var.organization_name} Billing Admins"
  description  = "Billing administrators"
  
  parent = "customers/${var.customer_id}"
  
  group_key {
    id = "billing-admins@${var.domain_name}"
  }
  
  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

resource "google_cloud_identity_group" "security_admins" {
  display_name = "${var.organization_name} Security Admins"
  description  = "Security administrators"
  
  parent = "customers/${var.customer_id}"
  
  group_key {
    id = "security-admins@${var.domain_name}"
  }
  
  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

# Environment-specific admin groups
resource "google_cloud_identity_group" "env_admins" {
  for_each = toset(["dev", "staging", "prod"])
  
  display_name = "${var.organization_name} ${title(each.key)} Admins"
  description  = "${title(each.key)} environment administrators"
  
  parent = "customers/${var.customer_id}"
  
  group_key {
    id = "${each.key}-admins@${var.domain_name}"
  }
  
  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

# Developer groups
resource "google_cloud_identity_group" "developers" {
  for_each = toset(["dev", "staging", "prod"])
  
  display_name = "${var.organization_name} ${title(each.key)} Developers"
  description  = "${title(each.key)} environment developers"
  
  parent = "customers/${var.customer_id}"
  
  group_key {
    id = "${each.key}-developers@${var.domain_name}"
  }
  
  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

# Viewer groups
resource "google_cloud_identity_group" "viewers" {
  for_each = toset(["dev", "staging", "prod"])
  
  display_name = "${var.organization_name} ${title(each.key)} Viewers"
  description  = "${title(each.key)} environment viewers"
  
  parent = "customers/${var.customer_id}"
  
  group_key {
    id = "${each.key}-viewers@${var.domain_name}"
  }
  
  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

# Specialized groups
resource "google_cloud_identity_group" "network_team" {
  display_name = "${var.organization_name} Network Team"
  description  = "Network operations team"
  
  parent = "customers/${var.customer_id}"
  
  group_key {
    id = "network-team@${var.domain_name}"
  }
  
  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

resource "google_cloud_identity_group" "data_team" {
  display_name = "${var.organization_name} Data Team"
  description  = "Data engineering and analytics team"
  
  parent = "customers/${var.customer_id}"
  
  group_key {
    id = "data-team@${var.domain_name}"
  }
  
  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

resource "google_cloud_identity_group" "security_team" {
  display_name = "${var.organization_name} Security Team"
  description  = "Security operations team"
  
  parent = "customers/${var.customer_id}"
  
  group_key {
    id = "security-team@${var.domain_name}"
  }
  
  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

# Emergency access group
resource "google_cloud_identity_group" "emergency_access" {
  display_name = "${var.organization_name} Emergency Access"
  description  = "Break-glass emergency access group"
  
  parent = "customers/${var.customer_id}"
  
  group_key {
    id = "emergency-access@${var.domain_name}"
  }
  
  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

# Nested group support - Add developers to admin groups
resource "google_cloud_identity_group_membership" "dev_to_staging_admins" {
  count = var.enable_nested_groups ? 1 : 0
  
  group    = google_cloud_identity_group.env_admins["staging"].id
  
  preferred_member_key {
    id = google_cloud_identity_group.env_admins["dev"].group_key[0].id
  }
  
  roles {
    name = "MEMBER"
  }
}

resource "google_cloud_identity_group_membership" "staging_to_prod_viewers" {
  count = var.enable_nested_groups ? 1 : 0
  
  group    = google_cloud_identity_group.viewers["prod"].id
  
  preferred_member_key {
    id = google_cloud_identity_group.env_admins["staging"].group_key[0].id
  }
  
  roles {
    name = "MEMBER"
  }
}

# Dynamic group membership based on attributes
resource "google_cloud_identity_group" "dynamic_developers" {
  count = var.enable_dynamic_groups ? 1 : 0
  
  display_name = "${var.organization_name} Dynamic Developers"
  description  = "Dynamically managed developer group"
  
  parent = "customers/${var.customer_id}"
  
  group_key {
    id = "dynamic-developers@${var.domain_name}"
  }
  
  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
  
  dynamic_group_metadata {
    queries {
      query = "user.department=='Engineering'"
    }
  }
}

# Group naming conventions validation
locals {
  group_naming_pattern = "^[a-z0-9-]+@${replace(var.domain_name, ".", "\\.")}$"
  
  all_groups = merge(
    { for k, v in google_cloud_identity_group.env_admins : k => v.group_key[0].id },
    { for k, v in google_cloud_identity_group.developers : k => v.group_key[0].id },
    { for k, v in google_cloud_identity_group.viewers : k => v.group_key[0].id },
    {
      org_admins      = google_cloud_identity_group.org_admins.group_key[0].id
      billing_admins  = google_cloud_identity_group.billing_admins.group_key[0].id
      security_admins = google_cloud_identity_group.security_admins.group_key[0].id
      network_team    = google_cloud_identity_group.network_team.group_key[0].id
      data_team       = google_cloud_identity_group.data_team.group_key[0].id
      security_team   = google_cloud_identity_group.security_team.group_key[0].id
      emergency_access = google_cloud_identity_group.emergency_access.group_key[0].id
    }
  )
  
  invalid_group_names = [
    for name, email in local.all_groups : name
    if !can(regex(local.group_naming_pattern, email))
  ]
}

# Validation for group naming
resource "null_resource" "validate_group_names" {
  count = length(local.invalid_group_names) > 0 ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo 'Error: Invalid group names: ${join(", ", local.invalid_group_names)}' && exit 1"
  }
}