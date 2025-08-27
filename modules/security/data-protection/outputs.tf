output "kms_key_ring_id" {
  description = "The ID of the KMS key ring"
  value       = var.enable_kms ? google_kms_key_ring.main[0].id : null
}

output "application_key_id" {
  description = "The ID of the application encryption key"
  value       = var.enable_kms ? google_kms_crypto_key.application[0].id : null
}

output "database_key_id" {
  description = "The ID of the database encryption key"
  value       = var.enable_kms ? google_kms_crypto_key.database[0].id : null
}

output "storage_key_id" {
  description = "The ID of the storage encryption key"
  value       = var.enable_kms ? google_kms_crypto_key.storage[0].id : null
}

output "hsm_key_id" {
  description = "The ID of the HSM-backed encryption key"
  value       = var.enable_cmek ? google_kms_crypto_key.hsm_key[0].id : null
}

output "dlp_inspect_templates" {
  description = "The DLP inspect templates"
  value       = var.enable_dlp ? google_data_loss_prevention_inspect_template.templates[*].id : []
}

output "service_account_email" {
  description = "Email of the data protection service account"
  value       = google_service_account.data_protection.email
}

# Additional outputs for main module integration
output "main_key_ring" {
  description = "Main KMS key ring"
  value       = var.enable_kms ? google_kms_key_ring.main[0].id : null
}

output "critical_key_ring" {
  description = "Critical KMS key ring (HSM-backed)"
  value       = var.enable_kms && var.environment == "prod" ? google_kms_key_ring.critical[0].id : null
}

output "application_key" {
  description = "Application encryption key"
  value       = var.enable_kms ? google_kms_crypto_key.application[0].id : null
}

output "database_key" {
  description = "Database encryption key"
  value       = var.enable_kms ? google_kms_crypto_key.database[0].id : null
}

output "storage_key" {
  description = "Storage encryption key"
  value       = var.enable_kms ? google_kms_crypto_key.storage[0].id : null
}

output "compute_key" {
  description = "Compute encryption key"
  value       = var.enable_kms ? google_kms_crypto_key.compute[0].id : null
}

output "bigquery_key" {
  description = "BigQuery encryption key"
  value       = var.enable_kms ? google_kms_crypto_key.bigquery[0].id : null
}

output "dlp_templates" {
  description = "DLP inspect templates"
  value       = var.enable_dlp ? google_data_loss_prevention_inspect_template.templates[*].id : []
}

output "dlp_job_triggers" {
  description = "DLP job triggers"
  value       = var.enable_dlp ? google_data_loss_prevention_job_trigger.scan_trigger[*].id : []
}