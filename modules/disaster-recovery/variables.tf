variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "primary_region" {
  description = "Primary region"
  type        = string
  default     = "us-central1"
}

variable "dr_region" {
  description = "Disaster recovery region"
  type        = string
  default     = "us-east1"
}

variable "dns_zone_name" {
  description = "DNS zone name for failover"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "rto_minutes" {
  description = "Recovery Time Objective in minutes"
  type        = number
  default     = 60
}

variable "rpo_minutes" {
  description = "Recovery Point Objective in minutes"
  type        = number
  default     = 15
}

variable "enable_automated_failover" {
  description = "Enable automated failover"
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "primary_instance_groups" {
  description = "Primary region instance groups"
  type = map(object({
    instance_group = string
    port          = optional(number, 80)
    protocol      = optional(string, "HTTP")
  }))
  default = {}
}

variable "dr_instance_groups" {
  description = "DR region instance groups"
  type = map(object({
    instance_group = string
    port          = optional(number, 80)
    protocol      = optional(string, "HTTP")
  }))
  default = {}
}

variable "primary_data_buckets" {
  description = "Primary data buckets for replication"
  type = map(object({
    bucket_name = string
    sync_path   = optional(string, "")
  }))
  default = {}
}

variable "enable_sql_replica" {
  description = "Enable SQL replica in DR region"
  type        = bool
  default     = false
}

variable "sql_instances" {
  description = "SQL instances for DR configuration"
  type = map(object({
    instance_name    = string
    database_version = string
    tier            = string
    region          = optional(string)
  }))
  default = {}
}

variable "gke_clusters" {
  description = "GKE clusters for DR configuration"
  type = map(object({
    cluster_id     = string
    location       = string
    backup_plan_id = optional(string)
  }))
  default = {}
}

variable "notification_channels" {
  description = "Notification channels for alerts"
  type        = list(string)
  default     = []
}

variable "enable_dr_testing" {
  description = "Enable automated DR testing"
  type        = bool
  default     = true
}

variable "dr_test_schedule" {
  description = "Cron schedule for DR testing"
  type        = string
  default     = "0 2 * * 0"  # Weekly on Sunday at 2 AM
}

variable "enable_chaos_engineering" {
  description = "Enable chaos engineering tests"
  type        = bool
  default     = false
}

variable "chaos_test_schedule" {
  description = "Cron schedule for chaos engineering tests"
  type        = string
  default     = "0 3 1 * *"  # Monthly on 1st at 3 AM
}

variable "dr_runbook_bucket" {
  description = "Storage bucket for DR runbooks and procedures"
  type        = string
  default     = null
}

variable "enable_multi_region_setup" {
  description = "Enable multi-region active-active setup"
  type        = bool
  default     = false
}

variable "traffic_split_primary" {
  description = "Traffic percentage for primary region (0-100)"
  type        = number
  default     = 100
  
  validation {
    condition     = var.traffic_split_primary >= 0 && var.traffic_split_primary <= 100
    error_message = "Traffic split must be between 0 and 100."
  }
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}