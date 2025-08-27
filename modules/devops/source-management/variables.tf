variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "repositories" {
  description = "Source repositories to create"
  type = map(object({
    description = string
    url         = optional(string)
  }))
  default = {
    "landing-zone" = {
      description = "GCP Landing Zone Infrastructure"
    }
    "applications" = {
      description = "Application source code"
    }
  }
}

variable "enable_github_integration" {
  description = "Enable GitHub integration"
  type        = bool
  default     = true
}

variable "github_config" {
  description = "GitHub integration configuration"
  type = object({
    owner             = string
    installation_id   = optional(number)
    app_id           = optional(number)
    webhook_secret   = optional(string)
  })
  default = null
}

variable "branch_protection_rules" {
  description = "Branch protection rules"
  type = map(object({
    pattern                = string
    required_status_checks = list(string)
    require_code_review    = bool
    dismiss_stale_reviews  = bool
    require_up_to_date     = bool
  }))
  default = {
    "main" = {
      pattern                = "main"
      required_status_checks = ["security-scan", "terraform-validate"]
      require_code_review    = true
      dismiss_stale_reviews  = true
      require_up_to_date     = true
    }
  }
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}