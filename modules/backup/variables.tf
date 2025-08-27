variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "long_term_retention_days" {
  description = "Number of days to retain long-term backups"
  type        = number
  default     = 365
}

variable "snapshot_schedule" {
  description = "Cron schedule for disk snapshots"
  type        = string
  default     = "0 2 * * *"
}

variable "enable_cross_region_backup" {
  description = "Enable cross-region backup replication"
  type        = bool
  default     = true
}

variable "backup_regions" {
  description = "List of regions for backup replication"
  type        = list(string)
  default     = ["us-central1", "us-east1"]
}

variable "disk_names" {
  description = "List of disk names to backup"
  type        = list(string)
  default     = []
}

variable "sql_instances" {
  description = "SQL instances to backup"
  type = map(object({
    database_version = string
    tier            = string
    region          = optional(string)
  }))
  default = {}
}

variable "gke_clusters" {
  description = "GKE clusters to backup"
  type = map(object({
    cluster_id = string
    location   = string
  }))
  default = {}
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
}

variable "backup_notification_channels" {
  description = "Notification channels for backup alerts"
  type        = list(string)
  default     = []
}

variable "enable_backup_testing" {
  description = "Enable automated backup testing"
  type        = bool
  default     = true
}

variable "backup_test_schedule" {
  description = "Cron schedule for backup testing"
  type        = string
  default     = "0 6 * * 0"  # Weekly on Sunday at 6 AM
}

variable "application_backup_paths" {
  description = "Application-specific backup paths"
  type = map(object({
    source_bucket = string
    backup_path   = string
    schedule      = optional(string, "0 3 * * *")
  }))
  default = {}
}

variable "enable_backup_monitoring" {
  description = "Enable backup monitoring and alerting"
  type        = bool
  default     = true
}

variable "backup_sla_hours" {
  description = "Backup SLA in hours for alerting"
  type        = number
  default     = 24
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}