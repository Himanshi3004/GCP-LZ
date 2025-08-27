resource "google_data_catalog_entry" "data_source" {
  count           = var.enable_data_catalog ? 1 : 0
  entry_group     = google_data_catalog_entry_group.data_assets[0].id
  entry_id        = "raw-data-source"
  display_name    = "Raw Data Source"
  description     = "Source system for raw data ingestion"
  type            = "FILESET"
  
  gcs_fileset_spec {
    file_patterns = ["gs://${var.project_id}-data-lake-raw/*"]
  }
}

resource "google_data_catalog_entry" "processed_data" {
  count           = var.enable_data_catalog ? 1 : 0
  entry_group     = google_data_catalog_entry_group.data_assets[0].id
  entry_id        = "processed-data"
  display_name    = "Processed Data"
  description     = "Processed and cleaned data"
  user_specified_type = "TABLE"
  
  linked_resource = "//bigquery.googleapis.com/projects/${var.project_id}/datasets/analytics/tables/processed_events"
}

resource "google_data_catalog_tag_template" "data_lineage" {
  count               = var.enable_data_catalog ? 1 : 0
  tag_template_id     = "data_lineage"
  project             = var.project_id
  region              = var.region
  display_name        = "Data Lineage"
  
  fields {
    field_id     = "source_system"
    display_name = "Source System"
    type {
      primitive_type = "STRING"
    }
    is_required = true
  }
  
  fields {
    field_id     = "transformation_logic"
    display_name = "Transformation Logic"
    type {
      primitive_type = "STRING"
    }
  }
  
  fields {
    field_id     = "data_owner"
    display_name = "Data Owner"
    type {
      primitive_type = "STRING"
    }
    is_required = true
  }
}

resource "google_data_catalog_tag" "lineage_tag" {
  count    = var.enable_data_catalog ? 1 : 0
  parent   = google_data_catalog_entry.processed_data[0].id
  template = google_data_catalog_tag_template.data_lineage[0].id
  
  fields {
    field_name   = "source_system"
    string_value = "CRM System"
  }
  
  fields {
    field_name   = "transformation_logic"
    string_value = "Dataflow pipeline with data cleaning and enrichment"
  }
  
  fields {
    field_name   = "data_owner"
    string_value = "data-team@company.com"
  }
}