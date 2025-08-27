# GCP Landing Zone - Main Configuration
# This is the root module that orchestrates all landing zone components

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

locals {
  # Common labels for all resources
  common_labels = merge(var.default_labels, {
    environment     = var.environment
    organization    = var.organization_name
    terraform_root  = "gcp-landing-zone"
    created_date    = formatdate("YYYY-MM-DD", timestamp())
  })

  # Naming convention
  name_prefix = "${var.organization_name}-${var.environment}"
  
  # Project naming
  project_suffix = {
    dev     = "dev"
    staging = "stg" 
    prod    = "prd"
  }
}

# Organization and Folder Hierarchy Module
module "organization" {
  count  = var.enable_organization_module ? 1 : 0
  source = "./modules/organization"

  organization_id   = var.organization_id
  billing_account   = var.billing_account
  organization_name = var.organization_name
  domain_name       = var.domain_name
  environment       = var.environment
  
  enable_audit_logs            = var.enable_audit_logs
  enable_organization_policies = var.enable_organization_policies
  
  # Enhanced organization features
  allowed_regions      = [var.default_region]
  prod_allowed_regions = var.prod_allowed_regions
  folder_policies      = var.folder_policies
  allowed_vpn_peer_ips = var.allowed_vpn_peer_ips
  
  labels = local.common_labels
}

# Project Factory Module
module "project_factory" {
  count  = var.enable_project_factory ? 1 : 0
  source = "./modules/project-factory"

  organization_id = var.organization_id
  billing_account = var.billing_account
  
  # Folder dependencies
  folders = var.enable_organization_module ? module.organization[0].folders : {}
  
  environment           = var.environment
  name_prefix          = local.name_prefix
  default_region       = var.default_region
  enable_billing_export = var.enable_billing_export
  budget_alert_threshold = var.budget_alert_threshold
  
  labels = local.common_labels
  
  depends_on = [module.organization]
}

# IAM Foundation Module
module "iam" {
  count  = var.enable_iam_module ? 1 : 0
  source = "./modules/iam"

  organization_id   = var.organization_id
  domain_name       = var.domain_name
  environment       = var.environment
  organization_name = var.organization_name
  project_id        = var.project_id
  
  # Project dependencies
  projects = var.enable_project_factory ? module.project_factory[0].projects : {}
  
  labels = local.common_labels
  
  depends_on = [module.project_factory]
}

# Shared VPC Module
module "shared_vpc" {
  count  = var.enable_networking_module ? 1 : 0
  source = "./modules/networking/shared-vpc"

  host_project_id     = var.shared_vpc_host_project_id != "" ? var.shared_vpc_host_project_id : var.project_id
  service_project_ids = var.enable_project_factory ? [for p in module.project_factory[0].projects : p.project_id] : []
  network_name        = "${local.name_prefix}-shared-vpc"
  
  subnets = [
    {
      name                     = "${local.name_prefix}-subnet-${var.default_region}"
      ip_cidr_range           = "10.0.0.0/24"
      region                  = var.default_region
      description             = "Main subnet for ${var.environment}"
      private_ip_google_access = true
      secondary_ip_ranges = [
        {
          range_name    = "gke-pods"
          ip_cidr_range = "10.1.0.0/16"
        },
        {
          range_name    = "gke-services"
          ip_cidr_range = "10.2.0.0/20"
        }
      ]
    }
  ]
  
  enable_cloud_nat = true
  nat_regions      = [var.default_region]
  
  labels = local.common_labels
  
  depends_on = [module.project_factory]
}

# Hybrid Connectivity Module
module "hybrid_connectivity" {
  count  = var.enable_networking_module && var.enable_hybrid_connectivity ? 1 : 0
  source = "./modules/networking/hybrid-connectivity"

  project_id   = var.shared_vpc_host_project_id != "" ? var.shared_vpc_host_project_id : var.project_id
  network_name = module.shared_vpc[0].network_name
  region       = var.default_region
  
  enable_vpn = var.enable_vpn
  
  enable_interconnect = var.enable_interconnect
  
  labels = local.common_labels
  
  depends_on = [module.shared_vpc]
}

# Network Security Module
module "network_security" {
  count  = var.enable_networking_module && var.enable_network_security ? 1 : 0
  source = "./modules/networking/security"

  project_id   = var.shared_vpc_host_project_id != "" ? var.shared_vpc_host_project_id : var.project_id
  network_name = module.shared_vpc[0].network_name
  region       = var.default_region
  
  enable_cloud_armor = var.enable_cloud_armor
  enable_cloud_ids   = var.enable_cloud_ids
  enable_vpc_flow_logs = var.enable_vpc_flow_logs
  
  labels = local.common_labels
  
  depends_on = [module.shared_vpc]
}

# Security Command Center Module
module "security_command_center" {
  count  = var.enable_security_module ? 1 : 0
  source = "./modules/security/scc"

  organization_id         = var.organization_id
  project_id             = var.project_id
  enable_premium_tier    = var.enable_scc_premium
  notification_config    = var.scc_notification_config
  compliance_standards   = var.scc_compliance_standards
  severity_threshold     = var.scc_severity_threshold
  auto_remediation_enabled = var.enable_scc_auto_remediation
  
  depends_on = [module.project_factory]
}

# Identity Federation Module
module "identity_federation" {
  count  = var.enable_identity_federation ? 1 : 0
  source = "./modules/identity-federation"

  project_id        = var.project_id
  environment       = var.environment
  domain_name       = var.domain_name
  organization_name = var.organization_name
  billing_account   = var.billing_account
  
  labels = local.common_labels
  
  depends_on = [module.iam]
}

# Data Protection Module
module "data_protection" {
  count  = var.enable_security_module ? 1 : 0
  source = "./modules/security/data-protection"

  project_id = var.project_id
  region     = var.default_region
  
  labels = local.common_labels
  
  depends_on = [module.project_factory]
}

# Compliance Module
module "compliance" {
  count  = var.enable_security_module ? 1 : 0
  source = "./modules/security/compliance"

  project_id      = var.project_id
  organization_id = var.organization_id
  region          = var.default_region
  
  labels = local.common_labels
  
  depends_on = [module.project_factory]
}

# VPC Service Controls Module
module "vpc_service_controls" {
  count  = var.enable_vpc_service_controls ? 1 : 0
  source = "./modules/security/vpc-service-controls"

  organization_id     = var.organization_id
  organization_name   = var.organization_name
  project_id          = var.project_id
  environment         = var.environment
  
  protected_projects  = var.enable_project_factory ? [for p in module.project_factory[0].projects : p.number] : []
  allowed_ip_ranges   = var.vpc_sc_allowed_ip_ranges
  
  depends_on = [module.project_factory]
}

# Logging and Monitoring Module
module "logging_monitoring" {
  count  = var.enable_observability_module ? 1 : 0
  source = "./modules/observability/logging-monitoring"

  organization_id = var.organization_id
  project_id      = var.project_id
  environment     = var.environment
  region          = var.default_region
  
  # Folder dependencies for log sinks
  folders = var.enable_organization_module ? module.organization[0].folders : {}
  
  labels = local.common_labels
  
  depends_on = [module.organization, module.project_factory]
}

# Cloud Operations Module
module "cloud_operations" {
  count  = var.enable_observability_module ? 1 : 0
  source = "./modules/observability/operations"

  project_id = var.project_id
  region     = var.default_region
  
  labels = local.common_labels
  
  depends_on = [module.project_factory]
}

# Cost Management Module
module "cost_management" {
  count  = var.enable_cost_management ? 1 : 0
  source = "./modules/cost-management"

  project_id      = var.project_id
  billing_account = var.billing_account
  region          = var.default_region
  environment     = var.environment
  
  # Enhanced cost management features
  enable_cost_optimization        = var.enable_cost_optimization
  enable_finops_practices        = var.enable_finops_practices
  budget_amount                  = var.cost_management_budget_amount
  cost_alert_emails             = var.cost_alert_emails
  enable_rightsizing_recommendations = var.enable_rightsizing_recommendations
  enable_idle_resource_cleanup   = var.enable_idle_resource_cleanup
  cost_anomaly_threshold        = var.cost_anomaly_threshold
  billing_data_retention_days   = var.billing_data_retention_days
  
  labels = local.common_labels
  
  depends_on = [module.project_factory]
}

# GKE Platform Module
module "gke_platform" {
  count  = var.enable_compute_module ? 1 : 0
  source = "./modules/compute/gke"

  project_id  = var.project_id
  region      = var.default_region
  network     = var.enable_networking_module ? module.shared_vpc[0].network_name : ""
  subnetwork  = var.enable_networking_module ? values(module.shared_vpc[0].subnets)[0].id : ""
  
  labels = local.common_labels
  
  depends_on = [module.shared_vpc]
}

# Compute Instances Module
module "compute_instances" {
  count  = var.enable_compute_module ? 1 : 0
  source = "./modules/compute/instances"

  project_id = var.project_id
  region     = var.default_region
  network    = var.enable_networking_module ? module.shared_vpc[0].network_name : ""
  subnetwork = var.enable_networking_module ? values(module.shared_vpc[0].subnets)[0].id : ""
  
  labels = local.common_labels
  
  depends_on = [module.shared_vpc]
}

# Serverless Platform Module
module "serverless_platform" {
  count  = var.enable_compute_module ? 1 : 0
  source = "./modules/compute/serverless"

  project_id = var.project_id
  region     = var.default_region
  network    = var.enable_networking_module ? module.shared_vpc[0].network_name : ""
  
  labels = local.common_labels
  
  depends_on = [module.project_factory]
}

# Data Lake Module
module "data_lake" {
  count  = var.enable_data_module ? 1 : 0
  source = "./modules/data/lake"

  project_id  = var.project_id
  region      = var.default_region
  environment = var.environment
  
  labels = local.common_labels
  
  depends_on = [module.project_factory]
}

# Data Warehouse Module
module "data_warehouse" {
  count  = var.enable_data_module ? 1 : 0
  source = "./modules/data/warehouse"

  project_id  = var.project_id
  region      = var.default_region
  environment = var.environment
  
  labels = local.common_labels
  
  depends_on = [module.project_factory]
}

# Data Governance Module
module "data_governance" {
  count  = var.enable_data_module ? 1 : 0
  source = "./modules/data/governance"

  project_id      = var.project_id
  organization_id = var.organization_id
  region          = var.default_region
  environment     = var.environment
  
  labels = local.common_labels
  
  depends_on = [module.project_factory]
}

# CI/CD Pipeline Module
module "cicd_pipeline" {
  count  = var.enable_cicd_module ? 1 : 0
  source = "./modules/devops/cicd-pipeline"

  project_id = var.project_id
  region     = var.default_region
  
  labels = local.common_labels
  
  depends_on = [module.project_factory]
}

# Policy as Code Module
module "policy" {
  count  = var.enable_policy_module ? 1 : 0
  source = "./modules/policy"

  project_id      = var.project_id
  region          = var.default_region
  source_repo_url = "https://github.com/${var.organization_name}/terraform-policies"
  
  labels = local.common_labels
  
  depends_on = [module.organization]
}

# Backup Strategy Module
module "backup" {
  count  = var.enable_backup_module ? 1 : 0
  source = "./modules/backup"

  project_id = var.project_id
  region     = var.default_region
  
  labels = local.common_labels
  
  depends_on = [module.project_factory]
}

# Disaster Recovery Module
module "disaster_recovery" {
  count  = var.enable_disaster_recovery_module ? 1 : 0
  source = "./modules/disaster-recovery"

  project_id      = var.project_id
  primary_region  = var.default_region
  dns_zone_name   = "${var.organization_name}-zone"
  domain_name     = var.domain_name
  
  labels = local.common_labels
  
  depends_on = [module.project_factory]
}