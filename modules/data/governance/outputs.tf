output "data_catalog_taxonomies" {
  description = "Data Catalog taxonomy IDs"
  value = var.enable_data_catalog ? {
    classification = google_data_catalog_taxonomy.data_classification[0].id
    pii           = google_data_catalog_taxonomy.pii_taxonomy[0].id
  } : {}
}

output "dlp_templates" {
  description = "DLP template names"
  value = var.enable_dlp ? {
    inspect_template    = google_data_loss_prevention_inspect_template.pii_template[0].name
    deidentify_template = google_data_loss_prevention_deidentify_template.pii_deidentify[0].name
  } : {}
}

output "audit_dataset_id" {
  description = "Audit logs dataset ID"
  value       = google_bigquery_dataset.audit_logs.dataset_id
}

output "data_access_sink_name" {
  description = "Data access audit sink name"
  value       = google_logging_project_sink.data_access_sink.name
}

output "lineage_tag_template" {
  description = "Data lineage tag template ID"
  value       = var.enable_data_catalog ? google_data_catalog_tag_template.data_lineage[0].id : null
}

output "service_account_email" {
  description = "Governance service account email"
  value       = google_service_account.governance.email
}