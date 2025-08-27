output "folders" {
  description = "Created folder hierarchy"
  value = {
    environments = {
      for k, v in google_folder.environments : k => {
        id           = v.id
        name         = v.name
        display_name = v.display_name
        parent       = v.parent
      }
    }
    departments = {
      for k, v in google_folder.departments : k => {
        id           = v.id
        name         = v.name
        display_name = v.display_name
        parent       = v.parent
        environment  = split("-", k)[0]
        department   = split("-", k)[1]
      }
    }
    teams = {
      for k, v in google_folder.teams : k => {
        id           = v.id
        name         = v.name
        display_name = v.display_name
        parent       = v.parent
        environment  = split("-", k)[0]
        department   = split("-", k)[1]
        team         = split("-", k)[2]
      }
    }
  }
}

output "organization_policies" {
  description = "Applied organization policies"
  value = var.enable_organization_policies ? {
    # Core policies
    vm_external_ips    = google_org_policy_policy.restrict_vm_external_ips[0].name
    require_os_login   = google_org_policy_policy.require_os_login[0].name
    shared_vpc_subnets = google_org_policy_policy.restrict_shared_vpc_subnets[0].name
    sa_key_creation    = google_org_policy_policy.disable_sa_key_creation[0].name
    resource_locations = google_org_policy_policy.restrict_resource_locations[0].name
    require_shielded_vm = google_org_policy_policy.require_shielded_vm[0].name
    uniform_bucket_access = google_org_policy_policy.uniform_bucket_level_access[0].name
    restrict_vpn_peers = google_org_policy_policy.restrict_vpn_peer_ips[0].name
    restrict_sql_public_ip = google_org_policy_policy.restrict_sql_public_ip[0].name
    disable_nested_virtualization = google_org_policy_policy.disable_nested_virtualization[0].name
    
    # Enhanced policies
    restrict_load_balancer = google_org_policy_policy.restrict_load_balancer_creation[0].name
    restrict_protocol_forwarding = google_org_policy_policy.restrict_protocol_forwarding[0].name
    restrict_non_confidential = google_org_policy_policy.restrict_non_confidential_computing[0].name
    storage_retention = google_org_policy_policy.storage_retention_policy[0].name
    disable_sa_key_upload = google_org_policy_policy.disable_sa_key_upload[0].name
    restrict_sa_key_types = google_org_policy_policy.restrict_sa_key_types[0].name
    
    # Folder-level policies
    folder_policies = {
      dev_vm_external_ips = google_org_policy_policy.dev_vm_external_ips[0].name
      prod_compute_locations = google_org_policy_policy.prod_compute_locations[0].name
      security_folder_restrictions = {
        for k, v in google_org_policy_policy.security_folder_restrictions : k => v.name
      }
      data_folder_storage = {
        for k, v in google_org_policy_policy.data_folder_storage : k => v.name
      }
    }
  } : {}
}

output "audit_log_sink" {
  description = "Organization audit log sink"
  value = var.enable_audit_logs ? {
    name        = google_logging_organization_sink.audit_logs[0].name
    destination = google_logging_organization_sink.audit_logs[0].destination
  } : null
}

output "management_project" {
  description = "Management project details"
  value = {
    project_id     = google_project.management.project_id
    project_number = google_project.management.number
    name           = google_project.management.name
  }
}

output "naming_standards" {
  description = "Naming standards and patterns for resources"
  value = {
    patterns = local.naming_patterns
    validation = local.folder_name_validation
    labels = {
      standard = local.standard_labels
      environment = local.environment_labels
      department = local.department_labels
    }
  }
}