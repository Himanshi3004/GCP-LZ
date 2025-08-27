# Security Command Center Premium Configuration
# Configures SCC premium features including vulnerability scanning and compliance

# Enable SCC Premium tier
resource "google_scc_organization_custom_module" "premium_features" {
  organization          = var.organization_id
  display_name         = "SCC Premium Features"
  enablement_state     = "ENABLED"
  
  custom_config {
    predicate {
      expression = "true"  # Enable for all resources
    }
    
    custom_output {
      properties {
        name = "premium_enabled"
        value_expression {
          expression = "true"
        }
      }
    }
    
    resource_selector {
      resource_types = ["*"]
    }
    
    description = "Enables SCC Premium features across the organization"
    recommendation = "SCC Premium provides advanced security insights and compliance monitoring"
    severity = "MEDIUM"
  }
}

# Vulnerability scanning configuration
resource "google_scc_organization_custom_module" "vulnerability_scanning" {
  count = var.enable_vulnerability_scanning ? 1 : 0
  
  organization     = var.organization_id
  display_name     = "Vulnerability Scanning"
  enablement_state = "ENABLED"
  
  custom_config {
    predicate {
      expression = "resource.type == \"gce_instance\" || resource.type == \"gke_cluster\""
    }
    
    custom_output {
      properties {
        name = "vulnerability_scan_enabled"
        value_expression {
          expression = "true"
        }
      }
    }
    
    resource_selector {
      resource_types = ["gce_instance", "gke_cluster"]
    }
    
    description = "Enables vulnerability scanning for compute resources"
    recommendation = "Enable vulnerability scanning to identify security issues"
    severity = "HIGH"
  }
}

# Compliance scanning configuration
resource "google_scc_organization_custom_module" "compliance_scanning" {
  for_each = toset(var.compliance_standards)
  
  organization          = var.organization_id
  display_name         = "${each.key} Compliance Scanner"
  enablement_state     = "ENABLED"
  
  custom_config {
    predicate {
      expression = "true"
    }
    
    custom_output {
      properties {
        name = "compliance_standard"
        value_expression {
          expression = "\"${each.key}\""
        }
      }
    }
    
    resource_selector {
      resource_types = ["*"]
    }
    
    description = "Compliance scanner for ${each.key} standard"
    recommendation = "Ensure compliance with ${each.key} standards"
    severity = "MEDIUM"
  }
}

# Event Threat Detection configuration
resource "google_scc_organization_custom_module" "event_threat_detection" {
  organization          = var.organization_id
  display_name         = "Advanced Event Threat Detection"
  enablement_state     = "ENABLED"
  
  custom_config {
    predicate {
      expression = <<-EOT
        resource.type == "gce_instance" ||
        resource.type == "gke_cluster" ||
        resource.type == "cloud_sql_database"
      EOT
    }
    
    custom_output {
      properties {
        name = "threat_detected"
        value_expression {
          expression = <<-EOT
            has(resource.data.malware_detected) ||
            has(resource.data.suspicious_activity) ||
            has(resource.data.anomalous_behavior)
          EOT
        }
      }
      properties {
        name = "threat_type"
        value_expression {
          expression = <<-EOT
            resource.data.malware_detected ? "malware" :
            resource.data.suspicious_activity ? "suspicious" :
            resource.data.anomalous_behavior ? "anomaly" : "unknown"
          EOT
        }
      }
    }
    
    resource_selector {
      resource_types = ["gce_instance", "gke_cluster", "cloud_sql_database"]
    }
    
    description = "Advanced threat detection for compute and database resources"
    recommendation = "Investigate flagged resources for potential security threats"
    severity = "HIGH"
  }
}

# Web Security Scanner configuration
resource "google_security_scanner_scan_config" "web_security_scan" {
  for_each = toset(var.web_applications)
  
  project     = var.project_id
  display_name = "Security scan for ${each.key}"
  
  starting_urls = [each.key]
  
  schedule {
    schedule_time = "2023-01-01T02:00:00Z"
    interval_duration_days = 7
  }
  
  export_to_security_command_center = "ENABLED"
  
  user_agent = "Mozilla/5.0 (compatible; Google-Security-Scanner)"
}

# Binary Authorization configuration
resource "google_binary_authorization_policy" "binary_auth_policy" {
  project = var.project_id
  
  # Default admission rule
  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    
    require_attestations_by = [
      google_binary_authorization_attestor.build_attestor.name,
      google_binary_authorization_attestor.security_attestor.name
    ]
  }
  
  # Cluster-specific admission rules
  dynamic "cluster_admission_rules" {
    for_each = var.gke_clusters
    content {
      cluster = cluster_admission_rules.value
      
      evaluation_mode  = "REQUIRE_ATTESTATION"
      enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
      
      require_attestations_by = [
        google_binary_authorization_attestor.build_attestor.name,
        google_binary_authorization_attestor.security_attestor.name
      ]
    }
  }
  
  # Global policy evaluation mode
  global_policy_evaluation_mode = "ENABLE"
}

# Binary Authorization attestors
resource "google_binary_authorization_attestor" "build_attestor" {
  project = var.project_id
  name    = "build-attestor"
  
  attestation_authority_note {
    note_reference = google_container_analysis_note.build_note.name
    
    public_keys {
      ascii_armored_pgp_public_key = var.build_attestor_public_key
      id = "build-key"
    }
  }
  
  description = "Attestor for build process verification"
}

resource "google_binary_authorization_attestor" "security_attestor" {
  project = var.project_id
  name    = "security-attestor"
  
  attestation_authority_note {
    note_reference = google_container_analysis_note.security_note.name
    
    public_keys {
      ascii_armored_pgp_public_key = var.security_attestor_public_key
      id = "security-key"
    }
  }
  
  description = "Attestor for security scan verification"
}

# Container Analysis notes for attestors
resource "google_container_analysis_note" "build_note" {
  project = var.project_id
  name    = "build-attestor-note"
  
  attestation_authority {
    hint {
      human_readable_name = "Build Process Attestor"
    }
  }
  
  short_description = "Note for build process attestation"
  long_description  = "This note is used to attest that images have passed the build process verification"
}

resource "google_container_analysis_note" "security_note" {
  project = var.project_id
  name    = "security-attestor-note"
  
  attestation_authority {
    hint {
      human_readable_name = "Security Scan Attestor"
    }
  }
  
  short_description = "Note for security scan attestation"
  long_description  = "This note is used to attest that images have passed security scanning"
}

# SCC notification configurations
resource "google_scc_notification_config" "high_severity_findings" {
  config_id    = "high-severity-findings"
  organization = var.organization_id
  description  = "Notification for high severity security findings"
  pubsub_topic = google_pubsub_topic.scc_notifications.id
  
  streaming_config {
    filter = <<-EOT
      severity="HIGH" OR severity="CRITICAL" OR
      finding_class="THREAT" OR
      category="MALWARE" OR category="VULNERABILITY"
    EOT
  }
}

resource "google_scc_notification_config" "compliance_violations" {
  config_id    = "compliance-violations"
  organization = var.organization_id
  description  = "Notification for compliance violations"
  pubsub_topic = google_pubsub_topic.scc_notifications.id
  
  streaming_config {
    filter = <<-EOT
      category="COMPLIANCE_VIOLATION" OR
      (state="ACTIVE" AND finding_class="MISCONFIGURATION")
    EOT
  }
}

# Pub/Sub topic for SCC notifications
resource "google_pubsub_topic" "scc_notifications" {
  project = var.project_id
  name    = "scc-notifications"
  
  labels = var.labels
}

# SCC findings processing function
resource "google_storage_bucket_object" "scc_function_zip" {
  count  = var.enable_scc_automation ? 1 : 0
  name   = "scc-findings-processor.zip"
  bucket = var.functions_bucket
  source = "${path.module}/functions/scc-findings-processor.zip"
}

resource "google_cloudfunctions_function" "scc_findings_processor" {
  count   = var.enable_scc_automation ? 1 : 0
  project = var.project_id
  region  = var.default_region
  name    = "scc-findings-processor"
  
  source_archive_bucket = var.functions_bucket
  source_archive_object = google_storage_bucket_object.scc_function_zip[0].name
  
  entry_point = "processSccFindings"
  runtime     = "python39"
  
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.scc_notifications.id
  }
  
  environment_variables = {
    PROJECT_ID = var.project_id
    SLACK_WEBHOOK_URL = var.slack_webhook_url
    ENABLE_AUTO_REMEDIATION = var.enable_auto_remediation
  }
  
  labels = var.labels
}

# SCC dashboard
resource "google_monitoring_dashboard" "scc_dashboard" {
  project        = var.project_id
  dashboard_json = jsonencode({
    displayName = "Security Command Center Dashboard"
    mosaicLayout = {
      tiles = [
        {
          width = 6
          height = 4
          widget = {
            title = "Security Findings by Severity"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"organization\" AND metric.type=\"securitycenter.googleapis.com/finding/count\""
                    aggregation = {
                      alignmentPeriod = "3600s"
                      perSeriesAligner = "ALIGN_SUM"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields = ["metric.labels.severity"]
                    }
                  }
                }
                plotType = "STACKED_BAR"
              }]
            }
          }
        },
        {
          width = 6
          height = 4
          widget = {
            title = "Compliance Status"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"organization\" AND metric.type=\"securitycenter.googleapis.com/compliance/score\""
                  aggregation = {
                    alignmentPeriod = "3600s"
                    perSeriesAligner = "ALIGN_MEAN"
                  }
                }
              }
            }
          }
        }
      ]
    }
  })
}