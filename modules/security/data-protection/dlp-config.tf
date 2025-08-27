# Cloud DLP Configuration
# Configures Data Loss Prevention for sensitive data discovery and protection

# DLP inspection templates
resource "google_data_loss_prevention_inspect_template" "pii_template" {
  parent       = "projects/${var.project_id}"
  description  = "Template for detecting PII data"
  display_name = "PII Detection Template"
  
  inspect_config {
    info_types {
      name = "EMAIL_ADDRESS"
    }
    info_types {
      name = "PHONE_NUMBER"
    }
    info_types {
      name = "CREDIT_CARD_NUMBER"
    }
    info_types {
      name = "US_SOCIAL_SECURITY_NUMBER"
    }
    info_types {
      name = "PERSON_NAME"
    }
    
    min_likelihood = "POSSIBLE"
    
    limits {
      max_findings_per_item    = 100
      max_findings_per_request = 1000
    }
    
    include_quote = true
  }
}

resource "google_data_loss_prevention_inspect_template" "financial_template" {
  parent       = "projects/${var.project_id}"
  description  = "Template for detecting financial data"
  display_name = "Financial Data Detection Template"
  
  inspect_config {
    info_types {
      name = "CREDIT_CARD_NUMBER"
    }
    info_types {
      name = "IBAN_CODE"
    }
    info_types {
      name = "SWIFT_CODE"
    }
    
    custom_info_types {
      info_type {
        name = "ACCOUNT_NUMBER"
      }
      regex {
        pattern = "[0-9]{8,17}"
      }
      likelihood = "LIKELY"
    }
    
    min_likelihood = "LIKELY"
    
    limits {
      max_findings_per_item    = 50
      max_findings_per_request = 500
    }
  }
}

resource "google_data_loss_prevention_inspect_template" "healthcare_template" {
  parent       = "projects/${var.project_id}"
  description  = "Template for detecting healthcare data"
  display_name = "Healthcare Data Detection Template"
  
  inspect_config {
    info_types {
      name = "US_HEALTHCARE_NPI"
    }
    info_types {
      name = "US_DEA_NUMBER"
    }
    info_types {
      name = "MEDICAL_RECORD_NUMBER"
    }
    
    min_likelihood = "POSSIBLE"
    
    limits {
      max_findings_per_item    = 100
      max_findings_per_request = 1000
    }
  }
}

# DLP de-identification templates
resource "google_data_loss_prevention_deidentify_template" "masking_template" {
  parent       = "projects/${var.project_id}"
  description  = "Template for masking sensitive data"
  display_name = "Data Masking Template"
  
  deidentify_config {
    info_type_transformations {
      transformations {
        info_types {
          name = "EMAIL_ADDRESS"
        }
        primitive_transformation {
          character_mask_config {
            masking_character = "*"
            number_to_mask    = 5
          }
        }
      }
      
      transformations {
        info_types {
          name = "PHONE_NUMBER"
        }
        primitive_transformation {
          character_mask_config {
            masking_character = "X"
            number_to_mask    = 4
            reverse_order     = true
          }
        }
      }
      
      transformations {
        info_types {
          name = "CREDIT_CARD_NUMBER"
        }
        primitive_transformation {
          replace_config {
            new_value {
              string_value = "[CREDIT_CARD]"
            }
          }
        }
      }
    }
  }
}

resource "google_data_loss_prevention_deidentify_template" "encryption_template" {
  parent       = "projects/${var.project_id}"
  description  = "Template for encrypting sensitive data"
  display_name = "Data Encryption Template"
  
  deidentify_config {
    info_type_transformations {
      transformations {
        info_types {
          name = "US_SOCIAL_SECURITY_NUMBER"
        }
        primitive_transformation {
          crypto_deterministic_config {
            crypto_key {
              kms_wrapped {
                wrapped_key   = google_kms_crypto_key.dlp_key.id
                crypto_key_name = google_kms_crypto_key.dlp_key.id
              }
            }
            surrogate_info_type {
              name = "SSN_TOKEN"
            }
          }
        }
      }
    }
  }
}

# DLP job triggers for automatic scanning
resource "google_data_loss_prevention_job_trigger" "storage_scan_trigger" {
  parent       = "projects/${var.project_id}"
  description  = "Trigger for scanning Cloud Storage buckets"
  display_name = "Storage Scan Trigger"
  status       = "HEALTHY"
  
  triggers {
    schedule {
      recurrence_period_duration = "86400s"  # Daily
    }
  }
  
  inspect_job {
    inspect_template_name = google_data_loss_prevention_inspect_template.pii_template.id
    
    storage_config {
      cloud_storage_options {
        file_set {
          url = "gs://${var.data_bucket}/*"
        }
        bytes_limit_per_file = 1073741824  # 1GB
        file_types = ["TEXT_FILE", "CSV", "JSON"]
      }
    }
    
    actions {
      pub_sub {
        topic = google_pubsub_topic.dlp_findings.id
      }
    }
    
    actions {
      save_findings {
        output_config {
          table {
            project_id = var.project_id
            dataset_id = google_bigquery_dataset.dlp_findings.dataset_id
            table_id   = "storage_findings"
          }
        }
      }
    }
  }
}

resource "google_data_loss_prevention_job_trigger" "bigquery_scan_trigger" {
  parent       = "projects/${var.project_id}"
  description  = "Trigger for scanning BigQuery datasets"
  display_name = "BigQuery Scan Trigger"
  status       = "HEALTHY"
  
  triggers {
    schedule {
      recurrence_period_duration = "604800s"  # Weekly
    }
  }
  
  inspect_job {
    inspect_template_name = google_data_loss_prevention_inspect_template.pii_template.id
    
    storage_config {
      big_query_options {
        table_reference {
          project_id = var.project_id
          dataset_id = var.bigquery_dataset_id
          table_id   = "*"
        }
        rows_limit = 10000
        sample_method = "RANDOM_START"
      }
    }
    
    actions {
      pub_sub {
        topic = google_pubsub_topic.dlp_findings.id
      }
    }
    
    actions {
      save_findings {
        output_config {
          table {
            project_id = var.project_id
            dataset_id = google_bigquery_dataset.dlp_findings.dataset_id
            table_id   = "bigquery_findings"
          }
        }
      }
    }
  }
}

# DLP findings storage
resource "google_bigquery_dataset" "dlp_findings" {
  project    = var.project_id
  dataset_id = "dlp_findings"
  location   = var.default_region
  
  description = "Dataset for storing DLP scan findings"
  
  default_table_expiration_ms = 7776000000  # 90 days
  
  labels = var.labels
}

resource "google_pubsub_topic" "dlp_findings" {
  project = var.project_id
  name    = "dlp-findings"
  
  labels = var.labels
}

# DLP key for encryption
resource "google_kms_crypto_key" "dlp_key" {
  name            = "dlp-encryption-key"
  key_ring        = var.kms_key_ring_id
  rotation_period = "2592000s"  # 30 days
  
  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"
  }
  
  labels = merge(var.labels, {
    purpose = "dlp-encryption"
  })
}

# Data profiles for automatic discovery
resource "google_data_loss_prevention_discovery_config" "data_profile_config" {
  parent   = "projects/${var.project_id}/locations/${var.default_region}"
  location = var.default_region
  
  display_name = "Automatic Data Profiling"
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
    google_data_loss_prevention_inspect_template.pii_template.id,
    google_data_loss_prevention_inspect_template.financial_template.id
  ]
  
  actions {
    export_data {
      profile_table {
        project_id = var.project_id
        dataset_id = google_bigquery_dataset.dlp_findings.dataset_id
        table_id   = "data_profiles"
      }
    }
  }
  
  actions {
    pub_sub_notification {
      topic                = google_pubsub_topic.dlp_findings.id
      event                = "NEW_PROFILE"
      detail_of_message    = "TABLE_PROFILE"
      pubsub_condition {
        expressions {
          logical_operator = "OR"
          conditions {
            minimum_risk_score = "RISK_HIGH"
          }
        }
      }
    }
  }
}

# DLP findings processing function
resource "google_storage_bucket_object" "dlp_function_zip" {
  count  = var.enable_dlp_automation ? 1 : 0
  name   = "dlp-findings-processor.zip"
  bucket = var.functions_bucket
  source = "${path.module}/functions/dlp-findings-processor.zip"
}

resource "google_cloudfunctions_function" "dlp_findings_processor" {
  count   = var.enable_dlp_automation ? 1 : 0
  project = var.project_id
  region  = var.default_region
  name    = "dlp-findings-processor"
  
  source_archive_bucket = var.functions_bucket
  source_archive_object = google_storage_bucket_object.dlp_function_zip[0].name
  
  entry_point = "processDlpFindings"
  runtime     = "python39"
  
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.dlp_findings.id
  }
  
  environment_variables = {
    PROJECT_ID = var.project_id
    DATASET_ID = google_bigquery_dataset.dlp_findings.dataset_id
  }
  
  labels = var.labels
}

# DLP monitoring dashboard
resource "google_monitoring_dashboard" "dlp_dashboard" {
  project        = var.project_id
  dashboard_json = jsonencode({
    displayName = "DLP Findings Dashboard"
    mosaicLayout = {
      tiles = [
        {
          width = 6
          height = 4
          widget = {
            title = "DLP Findings by Info Type"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"dlp_job\""
                    aggregation = {
                      alignmentPeriod = "3600s"
                      perSeriesAligner = "ALIGN_SUM"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields = ["metric.labels.info_type"]
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
            title = "High Risk Data Profiles"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"dlp_data_profile\" AND metric.labels.risk_level=\"HIGH\""
                  aggregation = {
                    alignmentPeriod = "3600s"
                    perSeriesAligner = "ALIGN_SUM"
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