resource "google_service_account" "workload_identity" {
  count        = var.enable_workload_identity ? 1 : 0
  project      = var.project_id
  account_id   = "workload-identity-sa"
  display_name = "Workload Identity Service Account"
}

resource "google_service_account_iam_binding" "workload_identity" {
  count              = var.enable_workload_identity ? 1 : 0
  service_account_id = google_service_account.workload_identity[0].name
  role               = "roles/iam.workloadIdentityUser"
  
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[default/default]"
  ]
}

resource "google_project_iam_member" "workload_identity_roles" {
  for_each = var.enable_workload_identity ? toset([
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter"
  ]) : []
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.workload_identity[0].email}"
}