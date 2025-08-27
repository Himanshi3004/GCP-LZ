# Custom IAM roles outputs
output "custom_roles" {
  description = "Custom IAM roles created"
  value = {
    network_admin           = google_organization_iam_custom_role.network_admin.name
    security_reviewer       = google_organization_iam_custom_role.security_reviewer.name
    project_creator         = google_organization_iam_custom_role.project_creator.name
    monitoring_viewer_plus  = google_organization_iam_custom_role.monitoring_viewer_plus.name
    compute_viewer_plus     = google_organization_iam_custom_role.compute_viewer_plus.name
    ci_cd_deployer         = google_organization_iam_custom_role.ci_cd_deployer.name
    terraform_deployer     = google_organization_iam_custom_role.terraform_deployer.name
    emergency_responder    = google_organization_iam_custom_role.emergency_responder.name
    emergency_network_admin = google_organization_iam_custom_role.emergency_network_admin.name
    data_analyst           = google_organization_iam_custom_role.data_analyst.name
  }
}

# Core administrative groups
output "admin_groups" {
  description = "Administrative Google Cloud Identity groups"
  value = {
    platform_admins = {
      id           = google_cloud_identity_group.platform_admins.id
      display_name = google_cloud_identity_group.platform_admins.display_name
      group_key    = google_cloud_identity_group.platform_admins.group_key[0].id
    }
    org_admins = {
      id           = google_cloud_identity_group.org_admins.id
      display_name = google_cloud_identity_group.org_admins.display_name
      group_key    = google_cloud_identity_group.org_admins.group_key[0].id
    }
  }
}

# Environment-specific groups
output "environment_groups" {
  description = "Environment-specific Google Cloud Identity groups"
  value = {
    admins = {
      for env in ["dev", "staging", "prod"] : env => {
        id           = google_cloud_identity_group.env_admins[env].id
        display_name = google_cloud_identity_group.env_admins[env].display_name
        group_key    = google_cloud_identity_group.env_admins[env].group_key[0].id
      }
    }
    developers = {
      for env in ["dev", "staging", "prod"] : env => {
        id           = google_cloud_identity_group.developers[env].id
        display_name = google_cloud_identity_group.developers[env].display_name
        group_key    = google_cloud_identity_group.developers[env].group_key[0].id
      }
    }
    viewers = {
      for env in ["dev", "staging", "prod"] : env => {
        id           = google_cloud_identity_group.viewers[env].id
        display_name = google_cloud_identity_group.viewers[env].display_name
        group_key    = google_cloud_identity_group.viewers[env].group_key[0].id
      }
    }
  }
}

# Specialized groups
output "specialized_groups" {
  description = "Specialized Google Cloud Identity groups"
  value = {
    security_team = {
      id           = google_cloud_identity_group.security_team.id
      display_name = google_cloud_identity_group.security_team.display_name
      group_key    = google_cloud_identity_group.security_team.group_key[0].id
    }
    security_reviewers = {
      id           = google_cloud_identity_group.security_reviewers.id
      display_name = google_cloud_identity_group.security_reviewers.display_name
      group_key    = google_cloud_identity_group.security_reviewers.group_key[0].id
    }
    network_admins = {
      id           = google_cloud_identity_group.network_admins.id
      display_name = google_cloud_identity_group.network_admins.display_name
      group_key    = google_cloud_identity_group.network_admins.group_key[0].id
    }
    data_engineers = {
      id           = google_cloud_identity_group.data_engineers.id
      display_name = google_cloud_identity_group.data_engineers.display_name
      group_key    = google_cloud_identity_group.data_engineers.group_key[0].id
    }
    data_analysts = {
      id           = google_cloud_identity_group.data_analysts.id
      display_name = google_cloud_identity_group.data_analysts.display_name
      group_key    = google_cloud_identity_group.data_analysts.group_key[0].id
    }
    billing_admins = {
      id           = google_cloud_identity_group.billing_admins.id
      display_name = google_cloud_identity_group.billing_admins.display_name
      group_key    = google_cloud_identity_group.billing_admins.group_key[0].id
    }
    cost_viewers = {
      id           = google_cloud_identity_group.cost_viewers.id
      display_name = google_cloud_identity_group.cost_viewers.display_name
      group_key    = google_cloud_identity_group.cost_viewers.group_key[0].id
    }
    emergency_responders = {
      id           = google_cloud_identity_group.emergency_responders.id
      display_name = google_cloud_identity_group.emergency_responders.display_name
      group_key    = google_cloud_identity_group.emergency_responders.group_key[0].id
    }
  }
}

# Service accounts outputs
output "workload_identity_service_accounts" {
  description = "Workload identity service accounts"
  value = var.enable_workload_identity ? {
    for k, v in google_service_account.workload_identity_sa : k => {
      email     = v.email
      unique_id = v.unique_id
      name      = v.name
      project   = v.project
    }
  } : {}
  sensitive = true
}

output "application_service_accounts" {
  description = "Application-specific service accounts"
  value = {
    for k, v in google_service_account.app_service_accounts : k => {
      email     = v.email
      unique_id = v.unique_id
      name      = v.name
      project   = v.project
    }
  }
  sensitive = true
}

output "cicd_service_accounts" {
  description = "CI/CD service accounts"
  value = {
    for k, v in google_service_account.cicd_service_accounts : k => {
      email     = v.email
      unique_id = v.unique_id
      name      = v.name
      project   = v.project
    }
  }
  sensitive = true
}

output "monitoring_service_account" {
  description = "Monitoring service account"
  value = length(google_service_account.monitoring_sa) > 0 ? {
    email     = google_service_account.monitoring_sa[0].email
    unique_id = google_service_account.monitoring_sa[0].unique_id
    name      = google_service_account.monitoring_sa[0].name
    project   = google_service_account.monitoring_sa[0].project
  } : null
  sensitive = true
}

output "security_service_account" {
  description = "Security service account"
  value = length(google_service_account.security_sa) > 0 ? {
    email     = google_service_account.security_sa[0].email
    unique_id = google_service_account.security_sa[0].unique_id
    name      = google_service_account.security_sa[0].name
    project   = google_service_account.security_sa[0].project
  } : null
  sensitive = true
}

# Workload identity pool configuration
output "workload_identity_pool" {
  description = "Workload identity pool configuration"
  value = var.enable_workload_identity ? {
    pool_id = google_iam_workload_identity_pool.external_pool[0].name
    provider_id = google_iam_workload_identity_pool_provider.github_provider[0].name
  } : null
}

# IAM bindings summary
output "organization_bindings_summary" {
  description = "Summary of organization-level IAM bindings"
  value = {
    platform_admin_roles = keys(google_organization_iam_binding.platform_admin_bindings)
    org_admin_roles     = keys(google_organization_iam_binding.org_admin_bindings)
    security_team_roles = keys(google_organization_iam_binding.security_team_bindings)
    network_admin_roles = keys(google_organization_iam_binding.network_admin_bindings)
    billing_admin_roles = keys(google_organization_iam_binding.billing_admin_bindings)
    data_engineer_roles = keys(google_organization_iam_binding.data_engineer_bindings)
  }
}

# Audit and monitoring outputs
output "iam_audit_sink" {
  description = "IAM audit log sink"
  value = length(google_logging_organization_sink.iam_audit) > 0 ? {
    name        = google_logging_organization_sink.iam_audit[0].name
    destination = google_logging_organization_sink.iam_audit[0].destination
  } : null
}

output "iam_binding_audit_sink" {
  description = "IAM binding changes audit sink"
  value = length(google_logging_organization_sink.iam_binding_audit) > 0 ? {
    name        = google_logging_organization_sink.iam_binding_audit[0].name
    destination = google_logging_organization_sink.iam_binding_audit[0].destination
  } : null
}

# Role versioning information
output "role_versions" {
  description = "Custom role versions for tracking"
  value = local.role_versions
}

# Service account inventory location
output "service_account_inventory" {
  description = "Service account inventory location"
  value = var.inventory_bucket != "" ? {
    bucket = var.inventory_bucket
    object = google_storage_bucket_object.sa_inventory.name
  } : null
}