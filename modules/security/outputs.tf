# Security Module Outputs

# SCC outputs
output "scc_notification_config_id" {
  description = "Security Command Center notification configuration ID"
  value       = module.scc.notification_config_id
}

output "scc_custom_sources" {
  description = "Custom SCC sources created"
  value       = module.scc.custom_sources
}

output "scc_service_account_email" {
  description = "Service account email for SCC operations"
  value       = module.scc.service_account_email
}

output "scc_compliance_dashboard_url" {
  description = "URL to the compliance monitoring dashboard"
  value       = module.scc.compliance_dashboard_url
}

# Data Protection outputs
output "kms_key_rings" {
  description = "KMS key rings created"
  value = {
    main     = module.data_protection.main_key_ring
    critical = module.data_protection.critical_key_ring
  }
}

output "kms_keys" {
  description = "KMS encryption keys created"
  value = {
    application = module.data_protection.application_key
    database    = module.data_protection.database_key
    storage     = module.data_protection.storage_key
    compute     = module.data_protection.compute_key
    bigquery    = module.data_protection.bigquery_key
  }
}

output "dlp_templates" {
  description = "DLP inspect templates created"
  value       = module.data_protection.dlp_templates
}

output "dlp_job_triggers" {
  description = "DLP job triggers created"
  value       = module.data_protection.dlp_job_triggers
}

# VPC Service Controls outputs
output "access_policy" {
  description = "Access Context Manager policy"
  value = {
    name = module.vpc_service_controls.access_policy_name
    id   = module.vpc_service_controls.access_policy_id
  }
}

output "service_perimeters" {
  description = "Service perimeters created"
  value = {
    main   = module.vpc_service_controls.main_perimeter
    bridge = module.vpc_service_controls.bridge_perimeter
  }
}

output "access_levels" {
  description = "Access levels created"
  value = {
    basic       = module.vpc_service_controls.basic_access_level
    device_trust = module.vpc_service_controls.device_trust_level
    time_based  = module.vpc_service_controls.time_based_level
  }
}

# Security summary
output "security_summary" {
  description = "Summary of security configurations"
  value = {
    scc_enabled           = var.enable_scc_premium
    auto_remediation      = var.enable_auto_remediation
    kms_enabled          = var.enable_kms
    dlp_enabled          = var.enable_dlp
    vpc_sc_enabled       = true
    compliance_standards = var.compliance_standards
    environment         = var.environment
  }
}