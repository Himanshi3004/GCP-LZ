# Binary Authorization Policy
resource "google_binary_authorization_policy" "policy" {
  count   = var.enable_binary_authorization ? 1 : 0
  project = var.project_id
  
  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    
    require_attestations_by = [
      google_binary_authorization_attestor.attestor[0].name
    ]
  }
  
  admission_whitelist_patterns {
    name_pattern = "gcr.io/${var.project_id}/*"
  }
  
  admission_whitelist_patterns {
    name_pattern = "gcr.io/gke-release/*"
  }
  
  admission_whitelist_patterns {
    name_pattern = "k8s.gcr.io/*"
  }
}

resource "google_binary_authorization_attestor" "attestor" {
  count   = var.enable_binary_authorization ? 1 : 0
  name    = "gke-attestor"
  project = var.project_id
  
  attestation_authority_note {
    note_reference = google_container_analysis_note.note[0].name
  }
}

resource "google_container_analysis_note" "note" {
  count   = var.enable_binary_authorization ? 1 : 0
  name    = "gke-attestor-note"
  project = var.project_id
  
  attestation_authority {
    hint {
      human_readable_name = "GKE Attestor"
    }
  }
}

# Pod Security Standards
resource "kubernetes_namespace" "restricted" {
  count = var.enable_pod_security_standards ? 1 : 0
  
  metadata {
    name = "restricted"
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
  
  depends_on = [google_container_cluster.primary]
}

# Network Policies
resource "kubernetes_network_policy" "deny_all_default" {
  count = var.enable_network_policies ? 1 : 0
  
  metadata {
    name      = "deny-all"
    namespace = "default"
  }
  
  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
  
  depends_on = [google_container_cluster.primary]
}

resource "kubernetes_network_policy" "allow_dns" {
  count = var.enable_network_policies ? 1 : 0
  
  metadata {
    name      = "allow-dns"
    namespace = "default"
  }
  
  spec {
    pod_selector {}
    policy_types = ["Egress"]
    
    egress {
      to {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
      }
      ports {
        protocol = "UDP"
        port     = "53"
      }
    }
  }
  
  depends_on = [google_container_cluster.primary]
}

# Admission Controller Webhook
resource "kubernetes_validating_admission_webhook_configuration_v1" "security_webhook" {
  count = var.enable_admission_controllers ? 1 : 0
  
  metadata {
    name = "security-webhook"
  }
  
  webhook {
    name = "security.admission.controller"
    
    client_config {
      service {
        name      = "security-webhook-service"
        namespace = "kube-system"
        path      = "/validate"
      }
    }
    
    rule {
      operations   = ["CREATE", "UPDATE"]
      api_groups   = [""]
      api_versions = ["v1"]
      resources    = ["pods"]
    }
    
    admission_review_versions = ["v1", "v1beta1"]
    side_effects             = "None"
    failure_policy           = "Fail"
  }
  
  depends_on = [google_container_cluster.primary]
}