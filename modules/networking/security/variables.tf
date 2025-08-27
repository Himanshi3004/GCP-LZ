variable "project_id" {
  description = "The project ID where resources will be created"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "region" {
  description = "The region for security resources"
  type        = string
  default     = "us-central1"
}

# Cloud Armor variables
variable "enable_cloud_armor" {
  description = "Enable Cloud Armor security policies"
  type        = bool
  default     = true
}

variable "cloud_armor_policies" {
  description = "Cloud Armor security policies configuration"
  type = list(object({
    name                = string
    description         = string
    trusted_ip_ranges   = optional(list(string), [])
    rate_limit_requests = optional(number, 100)
    rate_limit_interval = optional(number, 60)
    ban_duration        = optional(number, 600)
    geo_restrictions = optional(list(object({
      action       = string
      priority     = number
      country_code = string
    })), [])
    rules = list(object({
      action      = string
      priority    = number
      description = string
      match = object({
        versioned_expr = optional(string)
        config = optional(object({
          src_ip_ranges = list(string)
        }))
        expr = optional(object({
          expression = string
        }))
      })
      rate_limit_options = optional(object({
        conform_action = string
        exceed_action  = string
        enforce_on_key = string
        rate_limit_threshold = object({
          count        = number
          interval_sec = number
        })
        ban_duration_sec = optional(number, 600)
      }))
    }))
  }))
  default = []
}

variable "enable_edge_security" {
  description = "Enable Cloud Armor edge security policy"
  type        = bool
  default     = false
}

variable "protected_backend_services" {
  description = "Backend services to protect with Cloud Armor"
  type = map(object({
    name            = string
    description     = string
    security_policy = string
    backend_group   = string
    health_checks   = list(string)
  }))
  default = {}
}

variable "enable_armor_monitoring" {
  description = "Enable Cloud Armor monitoring and alerting"
  type        = bool
  default     = true
}

variable "armor_notification_channels" {
  description = "Notification channels for Cloud Armor alerts"
  type        = list(string)
  default     = []
}

# Cloud IDS variables
variable "enable_cloud_ids" {
  description = "Enable Cloud IDS"
  type        = bool
  default     = false
}

variable "ids_endpoints" {
  description = "Cloud IDS endpoints configuration"
  type = map(object({
    name               = string
    zone               = string
    region             = string
    description        = string
    severity           = string
    threat_exceptions  = list(string)
    monitored_subnets  = list(string)
    monitored_instances = optional(list(string), [])
    monitored_tags     = optional(list(string), [])
    filter = object({
      ip_protocols = list(string)
      cidr_ranges  = optional(list(string), [])
      direction    = string
    })
  }))
  default = {}
}

variable "enable_custom_signatures" {
  description = "Enable custom threat signatures"
  type        = bool
  default     = false
}

variable "custom_threat_exceptions" {
  description = "Custom threat exceptions for false positives"
  type        = list(string)
  default     = []
}

variable "enable_ids_alerts" {
  description = "Enable IDS alert integration"
  type        = bool
  default     = true
}

variable "ids_alert_webhook_url" {
  description = "Webhook URL for IDS alerts"
  type        = string
  default     = ""
}

variable "enable_alert_processing" {
  description = "Enable Cloud Function for alert processing"
  type        = bool
  default     = false
}

variable "alert_processor_bucket" {
  description = "GCS bucket for alert processor function code"
  type        = string
  default     = ""
}

variable "alert_processor_object" {
  description = "GCS object for alert processor function code"
  type        = string
  default     = ""
}

variable "enable_ids_monitoring" {
  description = "Enable IDS monitoring and alerting"
  type        = bool
  default     = true
}

variable "ids_notification_channels" {
  description = "Notification channels for IDS alerts"
  type        = list(string)
  default     = []
}

# Hierarchical firewall variables
variable "enable_hierarchical_firewall" {
  description = "Enable hierarchical firewall policies"
  type        = bool
  default     = true
}

variable "firewall_policies" {
  description = "Hierarchical firewall policies"
  type = list(object({
    name        = string
    description = string
    parent      = string
    rules = list(object({
      description = string
      direction   = string
      action      = string
      priority    = number
      match = object({
        layer4_configs = list(object({
          ip_protocol = string
          ports       = list(string)
        }))
        dest_ip_ranges   = list(string)
        src_ip_ranges    = list(string)
      })
    }))
  }))
  default = []
}

# VPC Flow Logs variables
variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_logs_config" {
  description = "VPC Flow Logs configuration"
  type = object({
    aggregation_interval = string
    flow_sampling        = number
    metadata             = string
    metadata_fields      = list(string)
    filter_expr          = string
  })
  default = {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
    metadata_fields      = []
    filter_expr          = "true"
  }
}

# Packet mirroring variables
variable "enable_packet_mirroring" {
  description = "Enable packet mirroring"
  type        = bool
  default     = false
}

variable "packet_mirroring_config" {
  description = "Packet mirroring configuration"
  type = object({
    name        = string
    description = string
    collector_ilb = string
    mirrored_resources = object({
      subnetworks = list(string)
      instances   = list(string)
      tags        = list(string)
    })
    filter = object({
      ip_protocols = list(string)
      cidr_ranges  = list(string)
      direction    = string
    })
  })
  default = null
}

variable "enable_private_google_access" {
  description = "Enable Private Google Access"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}# Flow logs analysis variables
variable "flow_logs_retention_days" {
  description = "Number of days to retain flow logs in BigQuery"
  type        = number
  default     = 30
}

variable "create_flow_analysis_views" {
  description = "Create BigQuery views for flow log analysis"
  type        = bool
  default     = true
}

variable "enable_anomaly_detection" {
  description = "Enable automated anomaly detection for flow logs"
  type        = bool
  default     = true
}

variable "create_flow_dashboards" {
  description = "Create monitoring dashboards for flow logs"
  type        = bool
  default     = true
}

variable "enable_flow_alerts" {
  description = "Enable alerting for flow log anomalies"
  type        = bool
  default     = true
}

variable "denied_connections_threshold" {
  description = "Threshold for denied connections alert"
  type        = number
  default     = 100
}

variable "flow_notification_channels" {
  description = "Notification channels for flow log alerts"
  type        = list(string)
  default     = []
}

variable "enable_flow_archive" {
  description = "Enable long-term archival of flow logs"
  type        = bool
  default     = true
}