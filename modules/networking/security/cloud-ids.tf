# Cloud IDS Endpoints for strategic subnet monitoring
resource "google_cloud_ids_endpoint" "endpoints" {
  for_each = var.enable_cloud_ids ? var.ids_endpoints : {}
  
  name        = each.value.name
  project     = var.project_id
  location    = each.value.zone
  network     = data.google_compute_network.network.id
  severity    = each.value.severity
  description = each.value.description
  
  threat_exceptions = each.value.threat_exceptions
  
  depends_on = [google_project_service.ids_api]
}

# Packet Mirroring Policies for each IDS endpoint
resource "google_compute_packet_mirroring" "ids_mirroring" {
  for_each = var.enable_cloud_ids ? var.ids_endpoints : {}
  
  name        = "${each.value.name}-mirroring"
  project     = var.project_id
  region      = each.value.region
  description = "Packet mirroring for Cloud IDS endpoint ${each.value.name}"
  
  network {
    url = data.google_compute_network.network.id
  }
  
  collector_ilb {
    url = google_cloud_ids_endpoint.endpoints[each.key].endpoint_forwarding_rule
  }
  
  # Mirror traffic from specified subnets
  mirrored_resources {
    dynamic "subnetworks" {
      for_each = each.value.monitored_subnets
      content {
        url = "projects/${var.project_id}/regions/${each.value.region}/subnetworks/${subnetworks.value}"
      }
    }
    
    # Mirror traffic from specific instances if specified
    dynamic "instances" {
      for_each = lookup(each.value, "monitored_instances", [])
      content {
        url = instances.value
      }
    }
    
    # Mirror traffic with specific tags
    tags = lookup(each.value, "monitored_tags", [])
  }
  
  # Traffic filtering configuration
  filter {
    ip_protocols = each.value.filter.ip_protocols
    cidr_ranges  = lookup(each.value.filter, "cidr_ranges", [])
    direction    = each.value.filter.direction
  }
  
  depends_on = [google_cloud_ids_endpoint.endpoints]
}

# Custom threat detection signatures
resource "google_cloud_ids_endpoint" "custom_signatures" {
  count = var.enable_cloud_ids && var.enable_custom_signatures ? 1 : 0
  
  name        = "${var.network_name}-custom-signatures"
  project     = var.project_id
  location    = var.region
  network     = data.google_compute_network.network.id
  severity    = "MEDIUM"
  description = "IDS endpoint with custom threat signatures"
  
  # Custom threat exceptions for false positives
  threat_exceptions = var.custom_threat_exceptions
  
  depends_on = [google_project_service.ids_api]
}

# IDS alert integration with Security Command Center
resource "google_pubsub_topic" "ids_alerts" {
  count = var.enable_cloud_ids && var.enable_ids_alerts ? 1 : 0
  
  name    = "${var.network_name}-ids-alerts"
  project = var.project_id
  
  labels = {
    purpose = "ids-alerts"
    network = var.network_name
  }
}

resource "google_pubsub_subscription" "ids_alerts" {
  count = var.enable_cloud_ids && var.enable_ids_alerts ? 1 : 0
  
  name    = "${var.network_name}-ids-alerts-sub"
  project = var.project_id
  topic   = google_pubsub_topic.ids_alerts[0].name
  
  ack_deadline_seconds = 20
  
  push_config {
    push_endpoint = var.ids_alert_webhook_url
    
    attributes = {
      x-goog-version = "v1"
    }
  }
  
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}

# Cloud Function for IDS alert processing
resource "google_cloudfunctions_function" "ids_alert_processor" {
  count = var.enable_cloud_ids && var.enable_ids_alerts && var.enable_alert_processing ? 1 : 0
  
  name        = "${var.network_name}-ids-alert-processor"
  project     = var.project_id
  region      = var.region
  description = "Process IDS alerts and create incidents"
  
  runtime = "python39"
  
  available_memory_mb   = 256
  source_archive_bucket = var.alert_processor_bucket
  source_archive_object = var.alert_processor_object
  entry_point          = "process_ids_alert"
  
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.ids_alerts[0].name
  }
  
  environment_variables = {
    PROJECT_ID = var.project_id
    NETWORK    = var.network_name
  }
}

# Monitoring and alerting for IDS health
resource "google_monitoring_alert_policy" "ids_health_alerts" {
  count = var.enable_cloud_ids && var.enable_ids_monitoring ? 1 : 0
  
  display_name = "Cloud IDS Health Monitoring"
  project      = var.project_id
  
  conditions {
    display_name = "IDS Endpoint Down"
    
    condition_threshold {
      filter          = "resource.type=\"cloud_ids_endpoint\""
      comparison      = "COMPARISON_EQUAL"
      threshold_value = 0
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = var.ids_notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# IDS performance monitoring
resource "google_monitoring_alert_policy" "ids_performance_alerts" {
  count = var.enable_cloud_ids && var.enable_ids_monitoring ? 1 : 0
  
  display_name = "Cloud IDS Performance Monitoring"
  project      = var.project_id
  
  conditions {
    display_name = "High IDS Processing Latency"
    
    condition_threshold {
      filter          = "resource.type=\"cloud_ids_endpoint\" AND metric.type=\"ids.googleapis.com/endpoint/processing_latency\""
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 1000
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = var.ids_notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# IDS threat detection dashboard
resource "google_monitoring_dashboard" "ids_dashboard" {
  count = var.enable_cloud_ids && var.enable_ids_monitoring ? 1 : 0
  
  dashboard_json = jsonencode({
    displayName = "Cloud IDS Threat Detection Dashboard"
    mosaicLayout = {
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Threat Detections by Severity"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_ids_endpoint\" AND metric.type=\"ids.googleapis.com/endpoint/threat_detections\""
                    aggregation = {
                      alignmentPeriod  = "300s"
                      perSeriesAligner = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields = ["metric.label.severity"]
                    }
                  }
                }
              }]
            }
          }
        },
        {
          width  = 6
          height = 4
          widget = {
            title = "IDS Endpoint Health"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_ids_endpoint\" AND metric.type=\"ids.googleapis.com/endpoint/up\""
                    aggregation = {
                      alignmentPeriod  = "300s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
  
  project = var.project_id
}