resource "google_data_catalog_policy_tag_iam_binding" "restricted_access" {
  count      = var.enable_data_catalog && length(var.data_classification_levels) > 0 ? 1 : 0
  policy_tag = google_data_catalog_policy_tag.classification_levels[length(var.data_classification_levels)-1].id
  role       = "roles/datacatalog.categoryFineGrainedReader"
  
  members = [
    "group:data-admins@company.com",
    "serviceAccount:${google_service_account.governance.email}"
  ]
}

resource "google_data_catalog_policy_tag_iam_binding" "pii_access" {
  count      = var.enable_data_catalog && length(var.pii_info_types) > 0 ? 1 : 0
  policy_tag = google_data_catalog_policy_tag.pii_tags[0].id
  role       = "roles/datacatalog.categoryFineGrainedReader"
  
  members = [
    "group:privacy-team@company.com",
    "serviceAccount:${google_service_account.governance.email}"
  ]
}

resource "google_organization_policy" "restrict_public_access" {
  org_id     = var.organization_id
  constraint = "storage.publicAccessPrevention"
  
  boolean_policy {
    enforced = true
  }
}

resource "google_organization_policy" "require_os_login" {
  org_id     = var.organization_id
  constraint = "compute.requireOsLogin"
  
  boolean_policy {
    enforced = true
  }
}

resource "google_monitoring_alert_policy" "policy_violation" {
  display_name = "Data Policy Violation"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Policy violation detected"
    
    condition_threshold {
      filter          = "resource.type=\"organization\" AND protoPayload.serviceName=\"cloudresourcemanager.googleapis.com\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "60s"
    }
  }
  
  notification_channels = []
  
  alert_strategy {
    auto_close = "86400s"
  }
}