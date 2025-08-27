# SCC notification configuration
resource "google_scc_notification_config" "scc_notification" {
  config_id    = "scc-notification-config"
  organization = var.organization_id
  description  = "SCC notification configuration"
  
  pubsub_topic = var.notification_config.pubsub_topic != null || var.auto_remediation_enabled ? google_pubsub_topic.scc_findings[0].id : null
  
  streaming_config {
    filter = "severity=\"HIGH\" OR severity=\"CRITICAL\""
  }
}

# Custom SCC sources
resource "google_scc_source" "custom_sources" {
  for_each = toset(var.compliance_standards)
  
  organization = var.organization_id
  display_name = "${each.value} Compliance Source"
  description  = "Custom source for ${each.value} compliance findings"
}

# Custom SCC modules
resource "google_scc_organization_custom_module" "custom_modules" {
  for_each = { for module in var.custom_modules : module.name => module }
  
  organization     = var.organization_id
  display_name     = each.value.display_name
  enablement_state = each.value.enablement_state
  
  custom_config {
    predicate {
      expression = "true"
    }
    custom_output {
      properties {
        name = "compliance_check"
        value_expression {
          expression = "\"${each.key}\""
        }
      }
    }
    resource_selector {
      resource_types = ["google.compute.Instance"]
    }
    description = "Custom module for ${each.value.display_name}"
    recommendation = "Review and remediate findings"
    severity = "MEDIUM"
  }
}

# Mute configurations
resource "google_scc_mute_config" "mute_rules" {
  for_each = { for filter in var.finding_filters : filter.name => filter }
  
  mute_config_id = each.key
  parent         = "organizations/${var.organization_id}"
  filter         = each.value.filter
  description    = each.value.description
}