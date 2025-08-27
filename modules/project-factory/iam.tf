# Project-level IAM policies
resource "google_project_iam_policy" "project_policies" {
  for_each    = google_project.projects
  project     = each.value.project_id
  policy_data = data.google_iam_policy.project_policy[each.key].policy_data
}

data "google_iam_policy" "project_policy" {
  for_each = var.projects
  
  binding {
    role = "roles/viewer"
    members = [
      "serviceAccount:${google_service_account.project_sa[each.key].email}",
    ]
  }
  
  binding {
    role = "roles/logging.logWriter"
    members = [
      "serviceAccount:${google_service_account.project_sa[each.key].email}",
    ]
  }
  
  binding {
    role = "roles/monitoring.metricWriter"
    members = [
      "serviceAccount:${google_service_account.project_sa[each.key].email}",
    ]
  }
}