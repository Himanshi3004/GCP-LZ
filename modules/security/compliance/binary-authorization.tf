# Binary Authorization Configuration
resource "google_binary_authorization_policy" "policy" {
  count = var.enable_binary_authorization ? 1 : 0
  
  project = var.project_id
  
  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    
    require_attestations_by = [
      google_binary_authorization_attestor.attestor[0].name
    ]
  }
  
  cluster_admission_rules {
    cluster                = "*"
    evaluation_mode        = "REQUIRE_ATTESTATION"
    enforcement_mode       = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = [
      google_binary_authorization_attestor.attestor[0].name
    ]
  }
  
  admission_whitelist_patterns {
    name_pattern = "gcr.io/my-project/*"
  }
}

# Attestor for image verification
resource "google_binary_authorization_attestor" "attestor" {
  count = var.enable_binary_authorization ? 1 : 0
  
  project = var.project_id
  name    = "security-attestor"
  
  attestation_authority_note {
    note_reference = google_container_analysis_note.note[0].name
    
    public_keys {
      ascii_armored_pgp_public_key = "-----BEGIN PGP PUBLIC KEY BLOCK-----\n\n# Placeholder PGP public key\n# Replace with actual attestor public key\n\n-----END PGP PUBLIC KEY BLOCK-----"
    }
  }
}

# Container Analysis Note
resource "google_container_analysis_note" "note" {
  count = var.enable_binary_authorization ? 1 : 0
  
  project = var.project_id
  name    = "security-attestor-note"
  
  attestation_authority {
    hint {
      human_readable_name = "Security Attestor"
    }
  }
}