variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "network" {
  description = "The VPC network name"
  type        = string
}

variable "subnetwork" {
  description = "The VPC subnetwork name"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "main-cluster"
}

variable "enable_autopilot" {
  description = "Enable GKE Autopilot mode"
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity"
  type        = bool
  default     = true
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization"
  type        = bool
  default     = true
}

variable "node_count" {
  description = "Number of nodes per zone"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "Machine type for nodes"
  type        = string
  default     = "e2-medium"
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_pod_security_standards" {
  description = "Enable Pod Security Standards"
  type        = bool
  default     = true
}

variable "enable_network_policies" {
  description = "Enable Kubernetes Network Policies"
  type        = bool
  default     = true
}

variable "enable_admission_controllers" {
  description = "Enable custom admission controllers"
  type        = bool
  default     = true
}

variable "enable_private_nodes" {
  description = "Enable private nodes"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for master nodes"
  type        = string
  default     = "172.16.0.0/28"
}

variable "enable_master_global_access" {
  description = "Enable master global access"
  type        = bool
  default     = false
}

variable "master_authorized_networks" {
  description = "List of master authorized networks"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "internal"
    }
  ]
}

variable "enable_http_load_balancing" {
  description = "Enable HTTP load balancing addon"
  type        = bool
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  description = "Enable horizontal pod autoscaling addon"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable GKE backup"
  type        = bool
  default     = true
}

variable "enable_weekly_backup" {
  description = "Enable weekly backup plan"
  type        = bool
  default     = true
}

variable "backup_include_volume_data" {
  description = "Include volume data in backups"
  type        = bool
  default     = true
}

variable "backup_include_secrets" {
  description = "Include secrets in backups"
  type        = bool
  default     = true
}

variable "backup_namespaces" {
  description = "Namespaces to include in backup"
  type        = list(string)
  default     = ["default", "kube-system"]
}

variable "backup_encryption_key" {
  description = "KMS key for backup encryption"
  type        = string
  default     = null
}

variable "backup_daily_schedule" {
  description = "Cron schedule for daily backups"
  type        = string
  default     = "0 2 * * *"
}

variable "backup_weekly_schedule" {
  description = "Cron schedule for weekly backups"
  type        = string
  default     = "0 3 * * 0"
}

variable "backup_delete_lock_days" {
  description = "Days to lock backup from deletion"
  type        = number
  default     = 7
}

variable "backup_retain_days" {
  description = "Days to retain backups"
  type        = number
  default     = 30
}

variable "enable_cluster_autoscaling" {
  description = "Enable cluster autoscaling"
  type        = bool
  default     = true
}

variable "autoscaling_cpu_min" {
  description = "Minimum CPU for autoscaling"
  type        = number
  default     = 1
}

variable "autoscaling_cpu_max" {
  description = "Maximum CPU for autoscaling"
  type        = number
  default     = 100
}

variable "autoscaling_memory_min" {
  description = "Minimum memory for autoscaling"
  type        = number
  default     = 1
}

variable "autoscaling_memory_max" {
  description = "Maximum memory for autoscaling"
  type        = number
  default     = 1000
}

variable "node_service_account" {
  description = "Service account for nodes"
  type        = string
  default     = null
}

variable "enable_node_auto_upgrade" {
  description = "Enable node auto-upgrade"
  type        = bool
  default     = true
}