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

variable "enable_cloud_run" {
  description = "Enable Cloud Run services"
  type        = bool
  default     = true
}

variable "enable_cloud_functions" {
  description = "Enable Cloud Functions"
  type        = bool
  default     = true
}

variable "enable_app_engine" {
  description = "Enable App Engine"
  type        = bool
  default     = false
}

variable "enable_scheduler" {
  description = "Enable Cloud Scheduler"
  type        = bool
  default     = true
}

variable "enable_tasks" {
  description = "Enable Cloud Tasks"
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

variable "cloud_run_services" {
  description = "Cloud Run services configuration"
  type = map(object({
    image                = string
    cpu                  = optional(string, "1000m")
    memory               = optional(string, "512Mi")
    cpu_request          = optional(string, "100m")
    memory_request       = optional(string, "128Mi")
    concurrency          = optional(number, 80)
    timeout              = optional(number, 300)
    max_scale            = optional(number, 100)
    min_scale            = optional(number, 0)
    cpu_throttling       = optional(string, "true")
    allow_public_access  = optional(bool, false)
    custom_domains       = optional(list(string), [])
    env_vars             = optional(map(string), {})
    ports                = optional(list(object({
      port     = number
      name     = optional(string, "http1")
      protocol = optional(string, "TCP")
    })), [])
    volume_mounts        = optional(list(object({
      name       = string
      mount_path = string
    })), [])
    volumes              = optional(list(object({
      name        = string
      secret_name = string
    })), [])
    annotations          = optional(map(string), {})
    labels               = optional(map(string), {})
    traffic              = optional(list(object({
      percent         = number
      latest_revision = optional(bool, false)
      revision_name   = optional(string, null)
      tag            = optional(string, null)
    })), [])
  }))
  default = {}
}

variable "enable_vpc_connector" {
  description = "Enable VPC access connector"
  type        = bool
  default     = true
}

variable "vpc_connector_cidr" {
  description = "CIDR range for VPC connector"
  type        = string
  default     = "10.8.0.0/28"
}

variable "vpc_connector_min_instances" {
  description = "Minimum instances for VPC connector"
  type        = number
  default     = 2
}

variable "vpc_connector_max_instances" {
  description = "Maximum instances for VPC connector"
  type        = number
  default     = 10
}

variable "cloud_functions" {
  description = "Cloud Functions configuration"
  type = map(object({
    entry_point          = string
    runtime              = optional(string, "python39")
    memory               = optional(number, 256)
    timeout              = optional(number, 60)
    max_instances        = optional(number, 10)
    source_object        = optional(string, null)
    egress_settings      = optional(string, "PRIVATE_RANGES_ONLY")
    allow_public_access  = optional(bool, false)
    env_vars             = optional(map(string), {})
    labels               = optional(map(string), {})
    event_trigger        = optional(object({
      event_type = string
      resource   = string
      retry      = optional(bool, false)
    }), null)
  }))
  default = {}
}