# Assured Workloads Configuration
resource "google_assured_workloads_workload" "workload" {
  count = var.enable_assured_workloads ? 1 : 0
  
  organization    = var.organization_id
  location        = var.region
  display_name    = "Compliance Workload"
  compliance_regime = var.compliance_regime
  
  billing_account = "billingAccounts/${var.billing_account}"
  
  kms_settings {
    next_rotation_time = "2024-12-31T23:59:59Z"
    rotation_period    = "7776000s" # 90 days
  }
  
  resource_settings {
    resource_id   = var.project_id
    resource_type = "CONSUMER_PROJECT"
  }
  
  labels = var.labels
}

# Workload monitoring
resource "google_monitoring_alert_policy" "workload_violations" {
  count        = var.enable_assured_workloads ? 1 : 0
  display_name = "Assured Workloads Violations"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Workload compliance violations"
    
    condition_threshold {
      filter          = "resource.type=\"assured_workloads_workload\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "60s"
    }
  }
  
  notification_channels = []
  
  alert_strategy {
    auto_close = "1800s"
  }
}