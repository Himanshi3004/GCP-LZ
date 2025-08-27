# Key Access Policies
resource "google_kms_crypto_key_iam_binding" "application_key_binding" {
  count         = var.enable_kms ? 1 : 0
  crypto_key_id = google_kms_crypto_key.application[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  
  members = [
    "serviceAccount:${google_service_account.data_protection.email}",
  ]
}

resource "google_kms_crypto_key_iam_binding" "database_key_binding" {
  count         = var.enable_kms ? 1 : 0
  crypto_key_id = google_kms_crypto_key.database[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  
  members = [
    "serviceAccount:${google_service_account.data_protection.email}",
  ]
}

resource "google_kms_crypto_key_iam_binding" "storage_key_binding" {
  count         = var.enable_kms ? 1 : 0
  crypto_key_id = google_kms_crypto_key.storage[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  
  members = [
    "serviceAccount:${google_service_account.data_protection.email}",
  ]
}

# Key rotation monitoring
resource "google_monitoring_alert_policy" "key_rotation_alert" {
  count        = var.enable_kms ? 1 : 0
  display_name = "KMS Key Rotation Alert"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Key rotation overdue"
    
    condition_threshold {
      filter          = "resource.type=\"gce_instance\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1
      duration        = "300s"
    }
  }
  
  notification_channels = []
  
  alert_strategy {
    auto_close = "1800s"
  }
}