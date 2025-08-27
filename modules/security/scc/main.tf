terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

# Enable Security Command Center API
resource "google_project_service" "scc_api" {
  project = var.project_id
  service = "securitycenter.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Enable Cloud Asset API (required for SCC)
resource "google_project_service" "asset_api" {
  project = var.project_id
  service = "cloudasset.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Enable Cloud Resource Manager API
resource "google_project_service" "resource_manager_api" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Enable Compute Engine API (for security findings)
resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Enable additional APIs for SCC Premium
resource "google_project_service" "additional_apis" {
  for_each = toset([
    "container.googleapis.com",
    "binaryauthorization.googleapis.com",
    "websecurityscanner.googleapis.com",
    "eventarc.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value

  disable_dependent_services = false
  disable_on_destroy         = false
}

# SCC Notification Config
resource "google_scc_notification_config" "basic_notification" {
  count           = var.enable_premium_tier ? 1 : 0
  config_id       = "basic-scc-notification"
  organization    = var.organization_id
  description     = "Basic SCC notification configuration"
  pubsub_topic    = var.notification_config.pubsub_topic

  streaming_config {
    filter = "severity=\"HIGH\" OR severity=\"CRITICAL\""
  }

  depends_on = [google_project_service.scc_api]
}

# Event Threat Detection settings
resource "google_scc_organization_custom_module" "event_threat_detection" {
  count                      = var.enable_premium_tier ? 1 : 0
  organization              = var.organization_id
  display_name              = "Event Threat Detection"
  enablement_state          = "ENABLED"
  
  custom_config {
    predicate {
      expression = "resource.type == \"gce_instance\""
    }
    
    custom_output {
      properties {
        name           = "threat_detected"
        value_expression {
          expression = "true"
        }
      }
    }
    
    description = "Detects potential security threats in compute instances"
    recommendation = "Investigate the flagged instance for potential security issues"
    severity = "HIGH"
  }

  depends_on = [google_project_service.scc_api]
}