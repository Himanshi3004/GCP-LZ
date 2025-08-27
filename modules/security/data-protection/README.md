# Data Protection Module

This module implements comprehensive data security controls including Cloud DLP policies, Cloud KMS encryption, and Customer Managed Encryption Keys (CMEK).

## Features

- **Cloud DLP**: Data Loss Prevention policies for PII detection
- **Cloud KMS**: Customer-managed encryption keys with automatic rotation
- **CMEK**: Customer Managed Encryption Keys for enhanced security
- **HSM**: Hardware Security Module support for high-security environments
- **Key Policies**: Granular access controls for encryption keys

## Usage

```hcl
module "data_protection" {
  source = "./modules/security/data-protection"
  
  project_id           = var.project_id
  region              = var.region
  enable_dlp          = true
  enable_kms          = true
  enable_cmek         = true
  key_rotation_period = "7776000s" # 90 days
  
  dlp_templates = [
    {
      name        = "pii-template"
      description = "Template for PII detection"
      info_types  = ["EMAIL_ADDRESS", "PHONE_NUMBER", "CREDIT_CARD_NUMBER"]
    }
  ]
  
  labels = {
    environment = "prod"
    team        = "security"
  }
}
```

## Requirements

- Cloud KMS API enabled
- Cloud DLP API enabled
- Secret Manager API enabled
- Appropriate IAM permissions

## Outputs

- `kms_key_ring_id`: KMS key ring identifier
- `application_key_id`: Application encryption key ID
- `database_key_id`: Database encryption key ID
- `storage_key_id`: Storage encryption key ID
- `hsm_key_id`: HSM-backed key ID
- `dlp_inspect_templates`: DLP template IDs
- `service_account_email`: Service account email