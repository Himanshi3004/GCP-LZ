resource "google_compute_firewall" "allow_health_check" {
  name    = "allow-health-check"
  network = var.network
  project = var.project_id
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "allow_iap" {
  name    = "allow-iap"
  network = var.network
  project = var.project_id
  
  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }
  
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-access"]
}

# OS Config for patch management
resource "google_os_config_patch_deployment" "patch_deployment" {
  count           = var.enable_patch_management ? 1 : 0
  patch_deployment_id = "${var.environment}-patch-deployment"
  project         = var.project_id
  
  instance_filter {
    all = true
  }
  
  patch_config {
    reboot_config = "DEFAULT"
    
    apt {
      type = "DIST"
      excludes = var.patch_excludes
    }
    
    yum {
      security = true
      minimal = true
      excludes = var.patch_excludes
    }
  }
  
  one_time_schedule {
    execute_time = "2024-01-01T02:00:00Z"
  }
  
  recurring_schedule {
    time_zone {
      id = "UTC"
    }
    
    time_of_day {
      hours = 2
      minutes = 0
    }
    
    frequency = "WEEKLY"
    
    weekly {
      day_of_week = "SUNDAY"
    }
  }
}

# Security scanning
resource "google_compute_security_policy" "instance_security_policy" {
  count   = var.enable_security_policy ? 1 : 0
  name    = "${var.environment}-instance-security-policy"
  project = var.project_id
  
  rule {
    action   = "allow"
    priority = "1000"
    
    match {
      versioned_expr = "SRC_IPS_V1"
      
      config {
        src_ip_ranges = var.allowed_ip_ranges
      }
    }
    
    description = "Allow traffic from authorized IP ranges"
  }
  
  rule {
    action   = "deny(403)"
    priority = "2147483647"
    
    match {
      versioned_expr = "SRC_IPS_V1"
      
      config {
        src_ip_ranges = ["*"]
      }
    }
    
    description = "Default deny rule"
  }
}

resource "google_monitoring_alert_policy" "instance_down" {
  display_name = "Instance Down Alert"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Instance is down"
    
    condition_threshold {
      filter          = "resource.type=\"gce_instance\""
      comparison      = "COMPARISON_EQ"
      threshold_value = 0
      duration        = "300s"
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}