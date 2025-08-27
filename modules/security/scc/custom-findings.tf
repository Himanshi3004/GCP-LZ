# Custom SCC Findings Configuration

# Custom finding sources for different security domains
resource "google_scc_source" "security_domains" {
  for_each = toset([
    "network-security",
    "data-protection", 
    "identity-access",
    "compliance-monitoring",
    "threat-detection"
  ])
  
  organization = var.organization_id
  display_name = "${title(replace(each.value, "-", " "))} Security Source"
  description  = "Custom source for ${each.value} security findings"
}

# Custom finding categories with severity mappings
locals {
  finding_categories = {
    "CRITICAL_VULNERABILITY" = {
      severity = "CRITICAL"
      description = "Critical security vulnerabilities requiring immediate attention"
      remediation_priority = 1
    }
    "DATA_EXPOSURE_RISK" = {
      severity = "HIGH"
      description = "Potential data exposure or privacy violations"
      remediation_priority = 2
    }
    "COMPLIANCE_VIOLATION" = {
      severity = "HIGH"
      description = "Violations of compliance standards and policies"
      remediation_priority = 2
    }
    "CONFIGURATION_DRIFT" = {
      severity = "MEDIUM"
      description = "Security configuration drift from baseline"
      remediation_priority = 3
    }
    "ACCESS_ANOMALY" = {
      severity = "MEDIUM"
      description = "Unusual access patterns or privilege escalation"
      remediation_priority = 3
    }
    "POLICY_VIOLATION" = {
      severity = "LOW"
      description = "Organization policy violations"
      remediation_priority = 4
    }
  }
}

# Custom modules for each finding category
resource "google_scc_organization_custom_module" "finding_categories" {
  for_each = local.finding_categories
  
  organization = var.organization_id
  display_name = each.key
  enablement_state = "ENABLED"
  
  custom_config {
    predicate {
      expression = "true"
    }
    
    custom_output {
      properties {
        name = "category"
        value_expression {
          expression = "\"${each.key}\""
        }
      }
      properties {
        name = "severity"
        value_expression {
          expression = "\"${each.value.severity}\""
        }
      }
      properties {
        name = "remediation_priority"
        value_expression {
          expression = "\"${each.value.remediation_priority}\""
        }
      }
    }
    
    description = each.value.description
    recommendation = "Review and remediate according to priority level ${each.value.remediation_priority}"
    severity = each.value.severity
  }
}

# Finding lifecycle management
resource "google_scc_organization_custom_module" "finding_lifecycle" {
  organization = var.organization_id
  display_name = "Finding Lifecycle Manager"
  enablement_state = "ENABLED"
  
  custom_config {
    predicate {
      expression = "finding.state == \"ACTIVE\""
    }
    
    custom_output {
      properties {
        name = "lifecycle_stage"
        value_expression {
          expression = "\"active\""
        }
      }
      properties {
        name = "age_days"
        value_expression {
          expression = "(timestamp(now()) - timestamp(finding.create_time)) / 86400"
        }
      }
    }
    
    description = "Manages finding lifecycle and aging"
    recommendation = "Review findings older than 30 days for resolution or closure"
    severity = "LOW"
  }
}

# Custom dashboard for findings overview
resource "google_monitoring_dashboard" "custom_findings_dashboard" {
  project = var.project_id
  dashboard_json = jsonencode({
    displayName = "Custom Security Findings Dashboard"
    mosaicLayout = {
      tiles = [
        {
          width = 6
          height = 4
          widget = {
            title = "Findings by Severity"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"security_finding\""
                  aggregation = {
                    alignmentPeriod = "60s"
                    perSeriesAligner = "ALIGN_COUNT"
                    crossSeriesReducer = "REDUCE_SUM"
                    groupByFields = ["metric.label.severity"]
                  }
                }
              }
            }
          }
        },
        {
          width = 6
          height = 4
          xPos = 6
          widget = {
            title = "Findings by Category"
            pieChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"security_finding\""
                    aggregation = {
                      alignmentPeriod = "300s"
                      perSeriesAligner = "ALIGN_COUNT"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields = ["metric.label.category"]
                    }
                  }
                }
              }]
            }
          }
        },
        {
          width = 12
          height = 4
          yPos = 4
          widget = {
            title = "Finding Trends Over Time"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"security_finding\""
                    aggregation = {
                      alignmentPeriod = "3600s"
                      perSeriesAligner = "ALIGN_COUNT"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
              }]
              timeshiftDuration = "0s"
              yAxis = {
                label = "Number of Findings"
                scale = "LINEAR"
              }
            }
          }
        }
      ]
    }
  })
}

# BigQuery dataset for custom findings analytics
resource "google_bigquery_dataset" "custom_findings" {
  dataset_id  = "scc_custom_findings"
  project     = var.project_id
  location    = "US"
  description = "Dataset for custom SCC findings analytics and reporting"
  
  labels = var.labels
}

# Custom findings analytics table
resource "google_bigquery_table" "findings_analytics" {
  dataset_id = google_bigquery_dataset.custom_findings.dataset_id
  table_id   = "findings_analytics"
  project    = var.project_id
  
  schema = jsonencode([
    {
      name = "finding_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "source_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "category"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "severity"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "resource_name"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "create_time"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    },
    {
      name = "state"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "remediation_priority"
      type = "INTEGER"
      mode = "NULLABLE"
    },
    {
      name = "compliance_standards"
      type = "STRING"
      mode = "REPEATED"
    }
  ])
}

# Scheduled query for findings analytics
resource "google_bigquery_data_transfer_config" "findings_analytics_transfer" {
  display_name   = "SCC Custom Findings Analytics"
  project        = var.project_id
  location       = "US"
  data_source_id = "scheduled_query"
  
  schedule = "every 6 hours"
  
  params = {
    query = <<-SQL
      INSERT INTO `${var.project_id}.scc_custom_findings.findings_analytics`
      SELECT 
        name as finding_id,
        source_display_name as source_id,
        category,
        severity,
        resource_name,
        create_time,
        state,
        CAST(JSON_EXTRACT_SCALAR(source_properties, '$.remediation_priority') AS INT64) as remediation_priority,
        ARRAY(SELECT JSON_EXTRACT_SCALAR(compliance_standard) FROM UNNEST(JSON_EXTRACT_ARRAY(source_properties, '$.compliance_standards')) as compliance_standard) as compliance_standards
      FROM `${var.project_id}.security_center_findings.findings`
      WHERE DATE(create_time) = CURRENT_DATE()
    SQL
  }
}