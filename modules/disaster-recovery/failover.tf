# Global load balancer IP
resource "google_compute_global_address" "lb_ip" {
  name    = "dr-lb-ip"
  project = var.project_id
}

# Health checks for primary region
resource "google_compute_health_check" "primary" {
  for_each = var.primary_instance_groups
  
  name    = "${each.key}-primary-health-check"
  project = var.project_id
  
  dynamic "http_health_check" {
    for_each = each.value.protocol == "HTTP" ? [1] : []
    content {
      port         = each.value.port
      request_path = var.health_check_path
    }
  }
  
  dynamic "https_health_check" {
    for_each = each.value.protocol == "HTTPS" ? [1] : []
    content {
      port         = each.value.port
      request_path = var.health_check_path
    }
  }
  
  check_interval_sec  = 10
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 3
}

# Health checks for DR region
resource "google_compute_health_check" "dr" {
  for_each = var.dr_instance_groups
  
  name    = "${each.key}-dr-health-check"
  project = var.project_id
  
  dynamic "http_health_check" {
    for_each = each.value.protocol == "HTTP" ? [1] : []
    content {
      port         = each.value.port
      request_path = var.health_check_path
    }
  }
  
  dynamic "https_health_check" {
    for_each = each.value.protocol == "HTTPS" ? [1] : []
    content {
      port         = each.value.port
      request_path = var.health_check_path
    }
  }
  
  check_interval_sec  = 10
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 3
}

# Backend services for primary region
resource "google_compute_backend_service" "primary" {
  for_each = var.primary_instance_groups
  
  name        = "${each.key}-primary-backend"
  project     = var.project_id
  protocol    = each.value.protocol
  port_name   = lower(each.value.protocol)
  timeout_sec = 30
  
  health_checks = [google_compute_health_check.primary[each.key].id]
  
  backend {
    group = each.value.instance_group
    
    # Configure capacity and failover
    capacity_scaler        = var.enable_multi_region_setup ? (var.traffic_split_primary / 100) : 1.0
    max_utilization       = 0.8
    max_rate_per_instance = 100
  }
  
  # Configure failover policy
  failover_policy {
    disable_connection_drain_on_failover = false
    drop_traffic_if_unhealthy           = true
    failover_ratio                      = 0.1
  }
  
  # Enable CDN for static content
  enable_cdn = true
  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                 = 3600
    max_ttl                     = 86400
    negative_caching            = true
    serve_while_stale           = 86400
  }
}

# Backend services for DR region
resource "google_compute_backend_service" "dr" {
  for_each = var.dr_instance_groups
  
  name        = "${each.key}-dr-backend"
  project     = var.project_id
  protocol    = each.value.protocol
  port_name   = lower(each.value.protocol)
  timeout_sec = 30
  
  health_checks = [google_compute_health_check.dr[each.key].id]
  
  backend {
    group = each.value.instance_group
    
    # Configure capacity for DR
    capacity_scaler        = var.enable_multi_region_setup ? ((100 - var.traffic_split_primary) / 100) : 0.0
    max_utilization       = 0.8
    max_rate_per_instance = 100
  }
  
  # Configure failover policy
  failover_policy {
    disable_connection_drain_on_failover = false
    drop_traffic_if_unhealthy           = true
    failover_ratio                      = 0.1
  }
}

# URL map with intelligent routing
resource "google_compute_url_map" "main" {
  name            = "dr-url-map"
  project         = var.project_id
  default_service = length(var.primary_instance_groups) > 0 ? google_compute_backend_service.primary[keys(var.primary_instance_groups)[0]].id : null
  
  dynamic "host_rule" {
    for_each = var.primary_instance_groups
    content {
      hosts        = [var.domain_name]
      path_matcher = "${host_rule.key}-matcher"
    }
  }
  
  dynamic "path_matcher" {
    for_each = var.primary_instance_groups
    content {
      name            = "${path_matcher.key}-matcher"
      default_service = google_compute_backend_service.primary[path_matcher.key].id
      
      # Route to DR if primary is unhealthy
      dynamic "route_rules" {
        for_each = contains(keys(var.dr_instance_groups), path_matcher.key) ? [1] : []
        content {
          priority = 1
          
          match_rules {
            prefix_match = "/"
            
            header_matches {
              header_name  = "X-Health-Check"
              exact_match  = "primary-unhealthy"
            }
          }
          
          route_action {
            weighted_backend_services {
              backend_service = google_compute_backend_service.dr[path_matcher.key].id
              weight         = 100
            }
          }
        }
      }
    }
  }
}

# SSL certificate for HTTPS
resource "google_compute_managed_ssl_certificate" "main" {
  name    = "dr-ssl-cert"
  project = var.project_id
  
  managed {
    domains = [var.domain_name]
  }
}

# HTTPS proxy
resource "google_compute_target_https_proxy" "main" {
  name             = "dr-https-proxy"
  project          = var.project_id
  url_map          = google_compute_url_map.main.id
  ssl_certificates = [google_compute_managed_ssl_certificate.main.id]
}

# HTTP proxy (redirect to HTTPS)
resource "google_compute_target_http_proxy" "main" {
  name    = "dr-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.redirect_https.id
}

# URL map for HTTPS redirect
resource "google_compute_url_map" "redirect_https" {
  name    = "dr-https-redirect"
  project = var.project_id
  
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

# Global forwarding rules
resource "google_compute_global_forwarding_rule" "https" {
  name       = "dr-https-forwarding-rule"
  project    = var.project_id
  target     = google_compute_target_https_proxy.main.id
  port_range = "443"
  ip_address = google_compute_global_address.lb_ip.address
}

resource "google_compute_global_forwarding_rule" "http" {
  name       = "dr-http-forwarding-rule"
  project    = var.project_id
  target     = google_compute_target_http_proxy.main.id
  port_range = "80"
  ip_address = google_compute_global_address.lb_ip.address
}

# Automated failover trigger
resource "google_cloudbuild_trigger" "failover" {
  count = var.enable_automated_failover ? 1 : 0
  
  project     = var.project_id
  name        = "dr-failover-trigger"
  description = "Automated DR failover trigger"
  
  webhook_config {
    secret = "failover-webhook-secret"
  }
  
  build {
    step {
      name = "gcr.io/cloud-builders/gcloud"
      script = <<-EOF
        #!/bin/bash
        set -e
        
        echo "Initiating failover to DR region..."
        
        # Update backend service weights for failover
        for backend in ${join(" ", [for k, v in var.primary_instance_groups : "${k}-primary-backend"])}; do
          echo "Failing over backend: $backend"
          
          # Set primary backend capacity to 0
          gcloud compute backend-services update $backend \
            --global \
            --project=${var.project_id} \
            --update-backend-capacity-scaler=0.0
          
          # Set DR backend capacity to 1.0
          dr_backend="${replace(backend, "-primary-", "-dr-")}"
          gcloud compute backend-services update $dr_backend \
            --global \
            --project=${var.project_id} \
            --update-backend-capacity-scaler=1.0
        done
        
        # Update DNS records with lower TTL
        gcloud dns record-sets transaction start \
          --zone=${var.dns_zone_name} \
          --project=${var.project_id}
        
        gcloud dns record-sets transaction add \
          ${google_compute_global_address.lb_ip.address} \
          --name=${var.domain_name}. \
          --ttl=60 \
          --type=A \
          --zone=${var.dns_zone_name} \
          --project=${var.project_id}
        
        gcloud dns record-sets transaction execute \
          --zone=${var.dns_zone_name} \
          --project=${var.project_id}
        
        # Publish failover notification
        gcloud pubsub topics publish dr-events \
          --message="{\"event\":\"failover_initiated\",\"timestamp\":\"$(date -Iseconds)\",\"region\":\"${var.dr_region}\"}" \
          --project=${var.project_id}
        
        echo "Failover completed successfully"
      EOF
    }
  }
  
  service_account = google_service_account.dr_sa.id
}

# Failback trigger
resource "google_cloudbuild_trigger" "failback" {
  count = var.enable_automated_failover ? 1 : 0
  
  project     = var.project_id
  name        = "dr-failback-trigger"
  description = "Automated DR failback trigger"
  
  webhook_config {
    secret = "failback-webhook-secret"
  }
  
  build {
    step {
      name = "gcr.io/cloud-builders/gcloud"
      script = <<-EOF
        #!/bin/bash
        set -e
        
        echo "Initiating failback to primary region..."
        
        # Restore primary backend service weights
        for backend in ${join(" ", [for k, v in var.primary_instance_groups : "${k}-primary-backend"])}; do
          echo "Restoring backend: $backend"
          
          # Set primary backend capacity to 1.0
          gcloud compute backend-services update $backend \
            --global \
            --project=${var.project_id} \
            --update-backend-capacity-scaler=1.0
          
          # Set DR backend capacity to 0
          dr_backend="${replace(backend, "-primary-", "-dr-")}"
          gcloud compute backend-services update $dr_backend \
            --global \
            --project=${var.project_id} \
            --update-backend-capacity-scaler=0.0
        done
        
        # Restore DNS TTL
        gcloud dns record-sets transaction start \
          --zone=${var.dns_zone_name} \
          --project=${var.project_id}
        
        gcloud dns record-sets transaction add \
          ${google_compute_global_address.lb_ip.address} \
          --name=${var.domain_name}. \
          --ttl=300 \
          --type=A \
          --zone=${var.dns_zone_name} \
          --project=${var.project_id}
        
        gcloud dns record-sets transaction execute \
          --zone=${var.dns_zone_name} \
          --project=${var.project_id}
        
        # Publish failback notification
        gcloud pubsub topics publish dr-events \
          --message="{\"event\":\"failback_completed\",\"timestamp\":\"$(date -Iseconds)\",\"region\":\"${var.primary_region}\"}" \
          --project=${var.project_id}
        
        echo "Failback completed successfully"
      EOF
    }
  }
  
  service_account = google_service_account.dr_sa.id
}