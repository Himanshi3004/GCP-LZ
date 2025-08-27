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

variable "templates" {
  description = "Instance template configurations"
  type = map(object({
    machine_type = string
    image        = string
    disk_size    = number
    tags         = list(string)
  }))
  default = {
    web = {
      machine_type = "e2-medium"
      image        = "ubuntu-2004-lts"
      disk_size    = 20
      tags         = ["web", "http-server"]
    }
  }
}

variable "enable_os_login" {
  description = "Enable OS Login"
  type        = bool
  default     = true
}

variable "enable_shielded_vm" {
  description = "Enable Shielded VM"
  type        = bool
  default     = true
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

variable "hardened_image_project" {
  description = "Project containing hardened OS images"
  type        = string
  default     = "ubuntu-os-cloud"
}

variable "disk_encryption_key" {
  description = "KMS key for disk encryption"
  type        = string
  default     = null
}

variable "instance_scopes" {
  description = "OAuth scopes for instances"
  type        = list(string)
  default     = [
    "https://www.googleapis.com/auth/cloud-platform"
  ]
}

variable "block_project_ssh_keys" {
  description = "Block project-wide SSH keys"
  type        = bool
  default     = true
}

variable "enable_confidential_compute" {
  description = "Enable Confidential Computing"
  type        = bool
  default     = false
}

variable "default_tags" {
  description = "Default tags for all instances"
  type        = list(string)
  default     = ["managed", "terraform"]
}

variable "enable_patch_management" {
  description = "Enable OS patch management"
  type        = bool
  default     = true
}

variable "patch_excludes" {
  description = "Packages to exclude from patching"
  type        = list(string)
  default     = []
}

variable "enable_security_policy" {
  description = "Enable security policy"
  type        = bool
  default     = true
}

variable "allowed_ip_ranges" {
  description = "Allowed IP ranges for security policy"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "notification_channels" {
  description = "Notification channels for alerts"
  type        = list(string)
  default     = []
}