resource "google_data_loss_prevention_inspect_template" "pii_template" {
  count  = var.enable_dlp ? 1 : 0
  parent = "projects/${var.project_id}"
  
  display_name = "PII Inspection Template"
  description  = "Template for detecting PII in data"
  
  inspect_config {
    dynamic "info_types" {
      for_each = var.pii_info_types
      content {
        name = info_types.value
      }
    }
    
    min_likelihood = "POSSIBLE"
    
    limits {
      max_findings_per_item    = 100
      max_findings_per_request = 1000
    }
    
    include_quote = true
  }
}

resource "google_data_loss_prevention_deidentify_template" "pii_deidentify" {
  count  = var.enable_dlp ? 1 : 0
  parent = "projects/${var.project_id}"
  
  display_name = "PII De-identification Template"
  description  = "Template for de-identifying PII data"
  
  deidentify_config {
    info_type_transformations {
      transformations {
        info_types {
          name = "EMAIL_ADDRESS"
        }
        primitive_transformation {
          replace_with_info_type_config = true
        }
      }
      
      transformations {
        info_types {
          name = "PHONE_NUMBER"
        }
        primitive_transformation {
          character_mask_config {
            masking_character = "*"
            number_to_mask    = 7
          }
        }
      }
      
      transformations {
        info_types {
          name = "CREDIT_CARD_NUMBER"
        }
        primitive_transformation {
          replace_with_info_type_config = true
        }
      }
    }
  }
}

resource "google_data_loss_prevention_job_trigger" "bigquery_scan" {
  count  = var.enable_dlp ? 1 : 0
  parent = "projects/${var.project_id}"
  
  display_name = "BigQuery PII Scan"
  description  = "Scheduled scan for PII in BigQuery datasets"
  
  triggers {
    schedule {
      recurrence_period_duration = "86400s" # Daily
    }
  }
  
  inspect_job {
    inspect_template_name = google_data_loss_prevention_inspect_template.pii_template[0].name
    
    storage_config {
      big_query_options {
        table_reference {
          project_id = var.project_id
          dataset_id = "analytics"
          table_id   = "customer_data"
        }
      }
    }
    
    actions {
      pub_sub {
        topic = "projects/${var.project_id}/topics/dlp-findings"
      }
    }
  }
}