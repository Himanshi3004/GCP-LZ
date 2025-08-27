locals {
  common_metadata = {
    enable-oslogin                = var.enable_os_login ? "TRUE" : "FALSE"
    block-project-ssh-keys        = "TRUE"
    enable-guest-attributes       = "TRUE"
    google-logging-enabled        = "TRUE"
    google-monitoring-enabled     = "TRUE"
    install-monitoring-agent      = "TRUE"
    install-logging-agent         = "TRUE"
  }
}

resource "google_compute_project_metadata" "default" {
  project = var.project_id
  
  metadata = merge(local.common_metadata, {
    ssh-keys = ""
  })
}

resource "google_project_iam_member" "os_login" {
  count   = var.enable_os_login ? 1 : 0
  project = var.project_id
  role    = "roles/compute.osLogin"
  member  = "serviceAccount:${google_service_account.instance.email}"
}