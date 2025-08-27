resource "google_data_catalog_taxonomy" "data_classification" {
  count                = var.enable_data_catalog ? 1 : 0
  project              = var.project_id
  region               = var.region
  display_name         = "Data Classification"
  description          = "Taxonomy for data classification levels"
  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]
}

resource "google_data_catalog_policy_tag" "classification_levels" {
  count       = var.enable_data_catalog ? length(var.data_classification_levels) : 0
  taxonomy    = google_data_catalog_taxonomy.data_classification[0].id
  display_name = var.data_classification_levels[count.index]
  description  = "Data classified as ${var.data_classification_levels[count.index]}"
}

resource "google_data_catalog_taxonomy" "pii_taxonomy" {
  count                = var.enable_data_catalog ? 1 : 0
  project              = var.project_id
  region               = var.region
  display_name         = "PII Taxonomy"
  description          = "Taxonomy for personally identifiable information"
  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]
}

resource "google_data_catalog_policy_tag" "pii_tags" {
  count       = var.enable_data_catalog ? length(var.pii_info_types) : 0
  taxonomy    = google_data_catalog_taxonomy.pii_taxonomy[0].id
  display_name = var.pii_info_types[count.index]
  description  = "PII type: ${var.pii_info_types[count.index]}"
}

resource "google_data_catalog_entry_group" "data_assets" {
  count           = var.enable_data_catalog ? 1 : 0
  entry_group_id  = "data_assets"
  project         = var.project_id
  region          = var.region
  display_name    = "Data Assets"
  description     = "Entry group for data assets"
}