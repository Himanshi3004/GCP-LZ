# Root module outputs for inter-module dependencies and external consumption

# Organization outputs
output "organization_id" {
  description = "The GCP organization ID"
  value       = var.organization_id
}

output "folders" {
  description = "Created folder hierarchy"
  value       = var.enable_organization_module ? module.organization[0].folders : {}
  sensitive   = false
}

output "organization_policies" {
  description = "Applied organization policies"
  value       = var.enable_organization_module ? module.organization[0].organization_policies : {}
  sensitive   = false
}

output "naming_standards" {
  description = "Naming standards and patterns for resources"
  value       = var.enable_organization_module ? module.organization[0].naming_standards : {}
  sensitive   = false
}

# Project outputs
output "projects" {
  description = "Created projects with their details"
  value       = var.enable_project_factory ? module.project_factory[0].projects : {}
  sensitive   = false
}

output "project_service_accounts" {
  description = "Service accounts created for projects"
  value       = var.enable_project_factory ? module.project_factory[0].service_accounts : {}
  sensitive   = true
}

# IAM outputs
output "custom_roles" {
  description = "Custom IAM roles created"
  value       = var.enable_iam_module ? module.iam[0].custom_roles : {}
  sensitive   = false
}

output "group_bindings" {
  description = "IAM group bindings"
  value       = var.enable_iam_module ? module.iam[0].group_bindings : {}
  sensitive   = false
}

# Networking outputs
output "shared_vpc" {
  description = "Shared VPC configuration"
  value = var.enable_networking_module ? {
    network_id      = module.shared_vpc[0].network_id
    network_name    = module.shared_vpc[0].network_name
    subnets         = module.shared_vpc[0].subnets
    subnet_ids      = module.shared_vpc[0].subnet_ids
    nat_ips         = module.shared_vpc[0].nat_ips
  } : {}
  sensitive = false
}

output "hybrid_connectivity" {
  description = "Hybrid connectivity configuration"
  value = var.enable_networking_module && var.enable_hybrid_connectivity ? {
    router_id       = module.hybrid_connectivity[0].router_id
    vpn_gateway_id  = module.hybrid_connectivity[0].vpn_gateway_id
    vpn_tunnels     = module.hybrid_connectivity[0].vpn_tunnels
    interconnect_attachment_id = module.hybrid_connectivity[0].interconnect_attachment_id
  } : {}
  sensitive = false
}

output "network_security" {
  description = "Network security configuration"
  value = var.enable_networking_module && var.enable_network_security ? {
    cloud_armor_policies = module.network_security[0].cloud_armor_policies
    cloud_ids_endpoint   = module.network_security[0].cloud_ids_endpoint
    firewall_policies    = module.network_security[0].firewall_policies
    vpc_flow_logs_dataset = module.network_security[0].vpc_flow_logs_dataset
  } : {}
  sensitive = false
}

# Security outputs
output "security_command_center" {
  description = "Security Command Center configuration"
  value = var.enable_security_module ? {
    organization_settings    = module.security_command_center[0].scc_organization_settings
    notification_config_id   = module.security_command_center[0].notification_config_id
    pubsub_topic_name       = module.security_command_center[0].pubsub_topic_name
    custom_sources          = module.security_command_center[0].custom_sources
    custom_modules          = module.security_command_center[0].custom_modules
    compliance_dashboard_url = module.security_command_center[0].compliance_dashboard_url
    bigquery_dataset        = module.security_command_center[0].bigquery_dataset
    service_account_email   = module.security_command_center[0].service_account_email
  } : {}
  sensitive = false
}

# Identity Federation outputs
output "identity_federation" {
  description = "Identity federation configuration"
  value = var.enable_identity_federation ? {
    workforce_pools = module.identity_federation[0].workforce_pools
    providers       = module.identity_federation[0].providers
  } : {}
  sensitive = false
}

# Data Protection outputs
output "data_protection" {
  description = "Data protection configuration"
  value = var.enable_security_module ? {
    kms_keys     = module.data_protection[0].kms_keys
    dlp_policies = module.data_protection[0].dlp_policies
  } : {}
  sensitive = false
}

# Compliance outputs
output "compliance" {
  description = "Compliance configuration"
  value = var.enable_security_module ? {
    assured_workloads      = module.compliance[0].assured_workloads
    vpc_service_controls   = module.compliance[0].vpc_service_controls
    access_context_manager = module.compliance[0].access_context_manager
  } : {}
  sensitive = false
}

# Observability outputs
output "logging_monitoring" {
  description = "Logging and monitoring configuration"
  value = var.enable_observability_module ? {
    log_sinks    = module.logging_monitoring[0].log_sinks
    dashboards   = module.logging_monitoring[0].dashboards
    alert_policies = module.logging_monitoring[0].alert_policies
  } : {}
  sensitive = false
}

output "cloud_operations" {
  description = "Cloud operations configuration"
  value = var.enable_observability_module ? {
    trace_config    = module.cloud_operations[0].trace_config
    profiler_config = module.cloud_operations[0].profiler_config
    uptime_checks   = module.cloud_operations[0].uptime_checks
  } : {}
  sensitive = false
}

# Cost Management outputs
output "cost_management" {
  description = "Cost management configuration"
  value = var.enable_cost_management ? {
    billing_export = module.cost_management[0].billing_export
    budgets        = module.cost_management[0].budgets
    dashboards     = module.cost_management[0].dashboards
  } : {}
  sensitive = false
}

# Compute outputs
output "gke_platform" {
  description = "GKE platform configuration"
  value = var.enable_compute_module ? {
    cluster_ids   = module.gke_platform[0].cluster_ids
    cluster_names = module.gke_platform[0].cluster_names
  } : {}
  sensitive = false
}

output "compute_instances" {
  description = "Compute instances configuration"
  value = var.enable_compute_module ? {
    instance_templates = module.compute_instances[0].instance_templates
  } : {}
  sensitive = false
}

output "serverless_platform" {
  description = "Serverless platform configuration"
  value = var.enable_compute_module ? {
    cloud_run_services = module.serverless_platform[0].cloud_run_services
    cloud_functions    = module.serverless_platform[0].cloud_functions
  } : {}
  sensitive = false
}

# Data outputs
output "data_lake" {
  description = "Data lake configuration"
  value = var.enable_data_module ? {
    storage_buckets = module.data_lake[0].storage_buckets
    bigquery_datasets = module.data_lake[0].bigquery_datasets
  } : {}
  sensitive = false
}

output "data_warehouse" {
  description = "Data warehouse configuration"
  value = var.enable_data_module ? {
    bigquery_datasets = module.data_warehouse[0].bigquery_datasets
    reservations      = module.data_warehouse[0].reservations
  } : {}
  sensitive = false
}

output "data_governance" {
  description = "Data governance configuration"
  value = var.enable_data_module ? {
    data_catalog = module.data_governance[0].data_catalog
    policy_tags  = module.data_governance[0].policy_tags
  } : {}
  sensitive = false
}

# CI/CD outputs
output "cicd_pipeline" {
  description = "CI/CD pipeline configuration"
  value = var.enable_cicd_module ? {
    build_triggers = module.cicd_pipeline[0].build_triggers
    repositories   = module.cicd_pipeline[0].repositories
  } : {}
  sensitive = false
}

# Policy outputs
output "policy" {
  description = "Policy as code configuration"
  value = var.enable_policy_module ? {
    policies = module.policy[0].policies
  } : {}
  sensitive = false
}

# Backup outputs
output "backup" {
  description = "Backup strategy configuration"
  value = var.enable_backup_module ? {
    backup_policies = module.backup[0].backup_policies
  } : {}
  sensitive = false
}

# Disaster Recovery outputs
output "disaster_recovery" {
  description = "Disaster recovery configuration"
  value = var.enable_disaster_recovery_module ? {
    failover_config = module.disaster_recovery[0].failover_config
  } : {}
  sensitive = false
}

# Environment information
output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "default_region" {
  description = "Default region for resources"
  value       = var.default_region
}

output "common_labels" {
  description = "Common labels applied to all resources"
  value       = local.common_labels
  sensitive   = false
}

# Landing zone metadata
output "landing_zone_info" {
  description = "Landing zone deployment information"
  value = {
    organization_name = var.organization_name
    environment      = var.environment
    deployment_time  = timestamp()
    terraform_version = "~> 1.5"
    modules_enabled = {
      organization         = var.enable_organization_module
      project_factory      = var.enable_project_factory
      iam                 = var.enable_iam_module
      identity_federation = var.enable_identity_federation
      networking          = var.enable_networking_module
      hybrid_connectivity = var.enable_hybrid_connectivity
      network_security    = var.enable_network_security
      security            = var.enable_security_module
      observability       = var.enable_observability_module
      cost_management     = var.enable_cost_management
      compute             = var.enable_compute_module
      data                = var.enable_data_module
      cicd                = var.enable_cicd_module
      policy              = var.enable_policy_module
      backup              = var.enable_backup_module
      disaster_recovery   = var.enable_disaster_recovery_module
    }
  }
  sensitive = false
}