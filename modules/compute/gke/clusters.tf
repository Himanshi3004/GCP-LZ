resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id
  
  network    = var.network
  subnetwork = var.subnetwork
  
  enable_autopilot = var.enable_autopilot
  
  dynamic "cluster_autoscaling" {
    for_each = var.enable_autopilot ? [] : [1]
    content {
      enabled = var.enable_cluster_autoscaling
      
      resource_limits {
        resource_type = "cpu"
        minimum       = var.autoscaling_cpu_min
        maximum       = var.autoscaling_cpu_max
      }
      
      resource_limits {
        resource_type = "memory"
        minimum       = var.autoscaling_memory_min
        maximum       = var.autoscaling_memory_max
      }
      
      auto_provisioning_defaults {
        oauth_scopes = [
          "https://www.googleapis.com/auth/cloud-platform"
        ]
        
        service_account = var.node_service_account
        
        management {
          auto_repair  = true
          auto_upgrade = var.enable_node_auto_upgrade
        }
        
        shielded_instance_config {
          enable_secure_boot          = true
          enable_integrity_monitoring = true
        }
      }
    }
  }
  
  workload_identity_config {
    workload_pool = var.enable_workload_identity ? "${var.project_id}.svc.id.goog" : null
  }
  
  binary_authorization {
    evaluation_mode = var.enable_binary_authorization ? "PROJECT_SINGLETON_POLICY_ENFORCE" : "DISABLED"
  }
  
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }
  
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
    
    master_global_access_config {
      enabled = var.enable_master_global_access
    }
  }
  
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }
  
  network_policy {
    enabled  = var.enable_network_policies
    provider = "CALICO"
  }
  
  addons_config {
    network_policy_config {
      disabled = !var.enable_network_policies
    }
    
    http_load_balancing {
      disabled = !var.enable_http_load_balancing
    }
    
    horizontal_pod_autoscaling {
      disabled = !var.enable_horizontal_pod_autoscaling
    }
  }
  
  resource_labels = var.labels
  
  depends_on = [google_project_service.apis]
}