# HSM Configuration (Optional)
resource "google_kms_key_ring" "hsm" {
  count    = var.enable_cmek ? 1 : 0
  name     = "hsm-keyring"
  location = var.region
  project  = var.project_id
}

# HSM-backed encryption key
resource "google_kms_crypto_key" "hsm_key" {
  count           = var.enable_cmek ? 1 : 0
  name            = "hsm-key"
  key_ring        = google_kms_key_ring.hsm[0].id
  rotation_period = var.key_rotation_period
  
  purpose = "ENCRYPT_DECRYPT"
  
  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "HSM"
  }
  
  labels = var.labels
}

# HSM key access policy
resource "google_kms_crypto_key_iam_binding" "hsm_key_binding" {
  count         = var.enable_cmek ? 1 : 0
  crypto_key_id = google_kms_crypto_key.hsm_key[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  
  members = [
    "serviceAccount:${google_service_account.data_protection.email}",
  ]
}