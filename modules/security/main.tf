# Security Module - Main Orchestration
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

# Security Command Center module
module "scc" {
  source = "./scc"
  
  project_id         = var.project_id
  organization_id    = var.organization_id
  enable_premium_tier = var.enable_scc_premium
  
  monitored_projects     = var.monitored_projects
  compliance_standards   = var.compliance_standards
  auto_remediation_enabled = var.enable_auto_remediation
  
  notification_config = var.scc_notification_config
  severity_threshold  = var.severity_threshold
  
  labels = var.labels
}

# Data Protection module
module "data_protection" {
  source = "./data-protection"
  
  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  
  enable_kms  = var.enable_kms
  enable_dlp  = var.enable_dlp
  enable_cmek = var.enable_cmek
  
  key_rotation_period        = var.key_rotation_period
  enable_access_justification = var.enable_access_justification
  key_users                  = var.key_users
  access_policy_id           = var.access_policy_id
  
  dlp_templates = var.dlp_templates
  
  labels = var.labels
}

# VPC Service Controls module
module "vpc_service_controls" {
  source = "./vpc-service-controls"
  
  organization_id   = var.organization_id
  organization_name = var.organization_name
  project_id        = var.project_id
  environment       = var.environment
  
  allowed_ip_ranges    = var.allowed_ip_ranges
  protected_projects   = var.protected_projects
  restricted_services  = var.restricted_services
  allowed_services     = var.allowed_services
  
  bridge_perimeter_projects = var.bridge_perimeter_projects
  ingress_policies         = var.ingress_policies
  egress_policies          = var.egress_policies
  
  allowed_regions          = var.allowed_regions
  enable_time_based_access = var.enable_time_based_access
}