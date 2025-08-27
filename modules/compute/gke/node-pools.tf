resource "google_container_node_pool" "primary" {
  count      = var.enable_autopilot ? 0 : 1
  name       = "primary-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  project    = var.project_id
  
  node_count = var.node_count
  
  node_config {
    preemptible  = false
    machine_type = var.machine_type
    
    service_account = google_service_account.gke.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    workload_metadata_config {
      mode = var.enable_workload_identity ? "GKE_METADATA" : "GCE_METADATA"
    }
    
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
    
    labels = var.labels
  }
  
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}