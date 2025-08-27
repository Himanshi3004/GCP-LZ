variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "pipelines" {
  description = "CI/CD pipelines configuration"
  type = map(object({
    source_repo    = string
    target_service = string
    environments   = list(string)
    build_config   = string
    test_commands  = list(string)
  }))
  default = {
    "web-app" = {
      source_repo    = "applications"
      target_service = "web-app"
      environments   = ["dev", "staging", "prod"]
      build_config   = "cloudbuild.yaml"
      test_commands  = ["npm test", "npm run e2e"]
    }
  }
}

variable "approval_required" {
  description = "Environments requiring manual approval"
  type        = list(string)
  default     = ["prod"]
}

variable "enable_rollback" {
  description = "Enable automatic rollback on failure"
  type        = bool
  default     = true
}

variable "notification_channels" {
  description = "Notification channels for pipeline events"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}