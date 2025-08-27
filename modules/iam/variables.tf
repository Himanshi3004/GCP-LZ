variable "organization_id" {
  description = "The GCP organization ID"
  type        = string
}

variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
  default     = "company"
}

variable "domain_name" {
  description = "Organization domain name"
  type        = string
}

variable "customer_id" {
  description = "Google Cloud Identity customer ID"
  type        = string
  default     = "C01234567"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "default_region" {
  description = "Default GCP region"
  type        = string
  default     = "us-central1"
}

variable "projects" {
  description = "Projects from project factory"
  type        = any
  default     = {}
}

variable "folder_ids" {
  description = "Folder IDs for environment-specific bindings"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_workload_identity" {
  description = "Enable workload identity configuration"
  type        = bool
  default     = true
}

variable "enable_key_rotation" {
  description = "Enable automatic service account key rotation"
  type        = bool
  default     = true
}

variable "inventory_bucket" {
  description = "GCS bucket for service account inventory"
  type        = string
  default     = ""
}

variable "notification_channels" {
  description = "Notification channels for alerts"
  type        = list(string)
  default     = []
}

variable "groups" {
  description = "IAM groups configuration"
  type = map(object({
    display_name = string
    description  = string
    members      = list(string)
    roles        = list(string)
  }))
  default = {
    "platform-admins" = {
      display_name = "Platform Administrators"
      description  = "Full platform administration access"
      members      = []
      roles        = ["roles/owner"]
    }
    "security-team" = {
      display_name = "Security Team"
      description  = "Security monitoring and compliance"
      members      = []
      roles        = ["roles/securitycenter.admin", "roles/cloudkms.admin"]
    }
    "developers" = {
      display_name = "Developers"
      description  = "Development team access"
      members      = []
      roles        = ["roles/editor"]
    }
  }
}

variable "application_service_accounts" {
  description = "Application-specific service accounts"
  type = map(object({
    project      = string
    display_name = string
    description  = string
    roles        = list(string)
  }))
  default = {}
}

variable "custom_roles_config" {
  description = "Configuration for custom roles"
  type = object({
    enable_versioning = bool
    role_prefix      = string
    default_stage    = string
  })
  default = {
    enable_versioning = true
    role_prefix      = "custom"
    default_stage    = "GA"
  }
}

variable "group_settings" {
  description = "Settings for group management"
  type = object({
    enable_nested_groups = bool
    auto_create_groups  = bool
    group_naming_prefix = string
  })
  default = {
    enable_nested_groups = true
    auto_create_groups  = true
    group_naming_prefix = ""
  }
}

variable "service_account_settings" {
  description = "Settings for service account management"
  type = object({
    enable_usage_tracking    = bool
    enable_impersonation    = bool
    key_rotation_schedule   = string
    naming_convention       = string
  })
  default = {
    enable_usage_tracking    = true
    enable_impersonation    = true
    key_rotation_schedule   = "0 2 1 * *"
    naming_convention       = "{org}-{project}-{type}-sa"
  }
}

variable "conditional_access_settings" {
  description = "Settings for conditional access policies"
  type = object({
    enable_time_based_access = bool
    business_hours_start    = number
    business_hours_end      = number
    emergency_access_hours  = list(number)
  })
  default = {
    enable_time_based_access = true
    business_hours_start    = 9
    business_hours_end      = 17
    emergency_access_hours  = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23]
  }
}

variable "audit_settings" {
  description = "Settings for IAM audit and monitoring"
  type = object({
    enable_binding_audit     = bool
    enable_sa_usage_tracking = bool
    enable_role_analytics   = bool
    retention_days          = number
  })
  default = {
    enable_binding_audit     = true
    enable_sa_usage_tracking = true
    enable_role_analytics   = true
    retention_days          = 365
  }
}variable "enable_role_testing" {
  description = "Enable role testing and validation framework"
  type        = bool
  default     = true
}