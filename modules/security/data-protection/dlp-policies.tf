# Cloud DLP Configuration
resource "google_data_loss_prevention_inspect_template" "templates" {
  count = var.enable_dlp ? length(var.dlp_templates) : 0
  
  parent       = "projects/${var.project_id}"
  description  = var.dlp_templates[count.index].description
  display_name = var.dlp_templates[count.index].name
  
  inspect_config {
    dynamic "info_types" {
      for_each = var.dlp_templates[count.index].info_types
      content {
        name = info_types.value
      }
    }
    
    min_likelihood = "POSSIBLE"
    
    rule_set {
      info_types {
        name = "EMAIL_ADDRESS"
      }
      rules {
        exclusion_rule {
          matching_type = "MATCHING_TYPE_FULL_MATCH"
          regex {
            pattern = ".*@example\\.com"
          }
        }
      }
    }
  }
}

# DLP Job Trigger for continuous scanning
resource "google_data_loss_prevention_job_trigger" "scan_trigger" {
  count = var.enable_dlp ? 1 : 0
  
  parent       = "projects/${var.project_id}"
  description  = "Continuous DLP scanning trigger"
  display_name = "continuous-scan-trigger"
  
  triggers {
    schedule {
      recurrence_period_duration = "86400s" # Daily
    }
  }
  
  inspect_job {
    inspect_template_name = google_data_loss_prevention_inspect_template.templates[0].id
    
    storage_config {
      cloud_storage_options {
        file_set {
          url = "gs://*"
        }
        files_limit_percent = 90
        bytes_limit_per_file = 1073741824 # 1GB
      }
    }
    
    actions {
      pub_sub {
        topic = "projects/${var.project_id}/topics/dlp-findings"
      }
      save_findings {
        output_config {
          table {
            project_id = var.project_id
            dataset_id = "dlp_findings"
            table_id   = "scan_results"
          }
        }
      }
    }
  }
  
  status = "HEALTHY"
}

# Data profiles for automatic discovery
resource "google_data_loss_prevention_discovery_config" "data_profiles" {
  count = var.enable_dlp ? 1 : 0
  
  parent       = "projects/${var.project_id}/locations/global"
  display_name = "Data Profile Discovery"
  status       = "RUNNING"
  
  targets {
    big_query_target {
      filter {
        other_tables {}
      }
    }
  }
  
  targets {
    cloud_sql_target {
      filter {
        others {}
      }
    }
  }
  
  inspect_templates = [
    google_data_loss_prevention_inspect_template.templates[0].name
  ]
}

# BigQuery dataset for DLP findings
resource "google_bigquery_dataset" "dlp_findings" {
  count       = var.enable_dlp ? 1 : 0
  dataset_id  = "dlp_findings"
  project     = var.project_id
  location    = "US"
  description = "Dataset for DLP scan results and findings"
  
  labels = var.labels
}