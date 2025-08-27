# Organization-level variables
variable "organization_id" {
  description = "The GCP organization ID"
  type        = string
  validation {
    condition     = can(regex("^[0-9]+$", var.organization_id))
    error_message = "Organization ID must be numeric."
  }
}

variable "billing_account" {
  description = "The billing account ID to associate with projects"
  type        = string
  validation {
    condition     = can(regex("^[A-F0-9]{6}-[A-F0-9]{6}-[A-F0-9]{6}$", var.billing_account))
    error_message = "Billing account must be in format XXXXXX-XXXXXX-XXXXXX."
  }
}

variable "project_id" {
  description = "The GCP project ID for the landing zone management"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, start with lowercase letter, contain only lowercase letters, numbers, and hyphens."
  }
}

# Regional settings
variable "default_region" {
  description = "Default GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "default_zone" {
  description = "Default GCP zone for resources"
  type        = string
  default     = "us-central1-a"
}

# Environment configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# Naming and tagging
variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
  default     = "netskope"
}

variable "domain_name" {
  description = "Organization domain name"
  type        = string
  default     = "netskope.com"
}

variable "default_labels" {
  description = "Default labels to apply to all resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "gcp-landing-zone"
  }
}

# Security settings
variable "enable_audit_logs" {
  description = "Enable audit logging for all services"
  type        = bool
  default     = true
}

variable "enable_vpc_service_controls" {
  description = "Enable VPC Service Controls"
  type        = bool
  default     = true
}

variable "enable_organization_policies" {
  description = "Enable organization policies"
  type        = bool
  default     = true
}

# Networking
variable "shared_vpc_host_project_id" {
  description = "Project ID for the Shared VPC host project"
  type        = string
  default     = ""
}

variable "enable_hybrid_connectivity" {
  description = "Enable hybrid connectivity module"
  type        = bool
  default     = false
}

variable "enable_network_security" {
  description = "Enable network security module"
  type        = bool
  default     = true
}

variable "enable_vpn" {
  description = "Enable Cloud VPN"
  type        = bool
  default     = false
}

variable "vpn_config" {
  description = "VPN configuration"
  type = object({
    peer_ip                   = string
    shared_secret            = string
    peer_asn                 = number
    cloud_asn                = number
    advertised_route_priority = number
    ike_version              = number
  })
  default = null
}

variable "enable_interconnect" {
  description = "Enable Cloud Interconnect"
  type        = bool
  default     = false
}

variable "interconnect_config" {
  description = "Interconnect configuration"
  type = object({
    interconnect_name    = string
    type                = string
    link_type           = string
    location            = string
    requested_link_count = number
  })
  default = null
}

variable "enable_cloud_armor" {
  description = "Enable Cloud Armor"
  type        = bool
  default     = true
}

variable "enable_cloud_ids" {
  description = "Enable Cloud IDS"
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

# Cost management
variable "enable_billing_export" {
  description = "Enable billing export to BigQuery"
  type        = bool
  default     = true
}

variable "budget_alert_threshold" {
  description = "Budget alert threshold percentage"
  type        = number
  default     = 80
  validation {
    condition     = var.budget_alert_threshold > 0 && var.budget_alert_threshold <= 100
    error_message = "Budget alert threshold must be between 1 and 100."
  }
}

# Module feature flags
variable "enable_organization_module" {
  description = "Enable organization and folder hierarchy module"
  type        = bool
  default     = true
}

variable "enable_project_factory" {
  description = "Enable project factory module"
  type        = bool
  default     = true
}

variable "enable_iam_module" {
  description = "Enable IAM foundation module"
  type        = bool
  default     = true
}

variable "enable_networking_module" {
  description = "Enable networking modules"
  type        = bool
  default     = true
}

variable "enable_security_module" {
  description = "Enable security modules"
  type        = bool
  default     = true
}

variable "enable_observability_module" {
  description = "Enable observability modules"
  type        = bool
  default     = true
}

# Security Command Center variables
variable "enable_scc_premium" {
  description = "Enable Security Command Center Premium tier"
  type        = bool
  default     = true
}

variable "scc_notification_config" {
  description = "Configuration for SCC security notifications"
  type = object({
    pubsub_topic    = optional(string)
    email_addresses = optional(list(string))
    slack_webhook   = optional(string)
  })
  default = {}
}

variable "scc_compliance_standards" {
  description = "Compliance standards to monitor in SCC"
  type        = list(string)
  default     = ["CIS", "PCI-DSS", "NIST", "ISO27001"]
}

variable "scc_severity_threshold" {
  description = "Minimum severity level for SCC notifications"
  type        = string
  default     = "MEDIUM"
  validation {
    condition     = contains(["LOW", "MEDIUM", "HIGH", "CRITICAL"], var.scc_severity_threshold)
    error_message = "SCC severity threshold must be one of: LOW, MEDIUM, HIGH, CRITICAL."
  }
}

variable "enable_scc_auto_remediation" {
  description = "Enable automated remediation for SCC findings"
  type        = bool
  default     = false
}

# Additional module feature flags
variable "enable_identity_federation" {
  description = "Enable identity federation module"
  type        = bool
  default     = false
}

variable "enable_cost_management" {
  description = "Enable cost management module"
  type        = bool
  default     = true
}

variable "enable_compute_module" {
  description = "Enable compute modules (GKE, instances, serverless)"
  type        = bool
  default     = true
}

variable "enable_data_module" {
  description = "Enable data modules (lake, warehouse, governance)"
  type        = bool
  default     = true
}

variable "enable_cicd_module" {
  description = "Enable CI/CD pipeline module"
  type        = bool
  default     = true
}

variable "enable_policy_module" {
  description = "Enable policy as code module"
  type        = bool
  default     = true
}

variable "enable_backup_module" {
  description = "Enable backup strategy module"
  type        = bool
  default     = true
}

variable "enable_disaster_recovery_module" {
  description = "Enable disaster recovery module"
  type        = bool
  default     = true
}

variable "vpc_sc_allowed_ip_ranges" {
  description = "List of allowed IP ranges for VPC Service Controls"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

# Organization module enhancements
variable "prod_allowed_regions" {
  description = "List of allowed GCP regions for production environment"
  type        = list(string)
  default     = ["us-central1", "us-east1"]
}

variable "folder_policies" {
  description = "Folder-specific organization policies"
  type = map(object({
    allowed_services = optional(list(string))
    denied_services  = optional(list(string))
    location_restrictions = optional(list(string))
  }))
  default = {}
}

variable "allowed_vpn_peer_ips" {
  description = "List of allowed VPN peer IP addresses for organization policies"
  type        = list(string)
  default     = []
}
# Cost Management Enhanced Variables
variable "enable_cost_optimization" {
  description = "Enable cost optimization features"
  type        = bool
  default     = true
}

variable "enable_finops_practices" {
  description = "Enable FinOps practices and reporting"
  type        = bool
  default     = true
}

variable "cost_management_budget_amount" {
  description = "Monthly budget amount in USD for cost management"
  type        = number
  default     = 5000
}

variable "cost_alert_emails" {
  description = "Email addresses for cost alerts"
  type        = list(string)
  default     = []
}

variable "enable_rightsizing_recommendations" {
  description = "Enable rightsizing recommendations"
  type        = bool
  default     = true
}

variable "enable_idle_resource_cleanup" {
  description = "Enable idle resource cleanup automation"
  type        = bool
  default     = false
}

variable "cost_anomaly_threshold" {
  description = "Threshold for cost anomaly detection (percentage)"
  type        = number
  default     = 20
}

variable "billing_data_retention_days" {
  description = "Number of days to retain billing data"
  type        = number
  default     = 365
}