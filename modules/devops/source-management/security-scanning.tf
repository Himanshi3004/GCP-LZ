resource "google_cloudbuild_trigger" "security_scan" {
  for_each = var.repositories
  
  project     = var.project_id
  name        = "${each.key}-security-scan"
  description = "Security scanning for ${each.key}"
  
  source_to_build {
    uri       = google_sourcerepo_repository.repositories[each.key].url
    ref       = "refs/heads/main"
    repo_type = "CLOUD_SOURCE_REPOSITORIES"
  }
  
  build {
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = [
        "components", "install", "beta"
      ]
    }
    
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = [
        "beta", "code", "scan", 
        "--source=.",
        "--format=json"
      ]
    }
    
    step {
      name = "gcr.io/cloud-builders/docker"
      args = [
        "run", "--rm", "-v", "/workspace:/workspace",
        "aquasec/trivy:latest",
        "fs", "/workspace"
      ]
    }
  }
  
  service_account = google_service_account.source_management.id
}

resource "google_container_analysis_note" "vulnerability_note" {
  name    = "vulnerability-scanning-note"
  project = var.project_id
  
  vulnerability {
    details {
      severity_name = "CRITICAL"
      description   = "Critical vulnerability found in source code"
    }
  }
}

resource "google_monitoring_alert_policy" "security_scan_failure" {
  display_name = "Security Scan Failure"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Security scan failed"
    
    condition_threshold {
      filter          = "resource.type=\"cloud_build\""
      comparison      = "COMPARISON_EQUAL"
      threshold_value = 0
      duration        = "300s"
    }
  }
  
  notification_channels = []
  
  alert_strategy {
    auto_close = "86400s"
  }
}