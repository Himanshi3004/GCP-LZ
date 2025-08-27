resource "google_vpc_access_connector" "connector" {
  count         = var.enable_vpc_connector ? 1 : 0
  name          = "${var.environment}-serverless-connector"
  project       = var.project_id
  region        = var.region
  network       = var.network
  ip_cidr_range = var.vpc_connector_cidr
  min_instances = var.vpc_connector_min_instances
  max_instances = var.vpc_connector_max_instances
  
  depends_on = [google_project_service.apis]
}

resource "google_cloud_run_service" "services" {
  for_each = var.cloud_run_services
  
  name     = each.key
  location = var.region
  project  = var.project_id
  
  template {
    spec {
      service_account_name = google_service_account.serverless.email
      container_concurrency = lookup(each.value, "concurrency", 80)
      timeout_seconds      = lookup(each.value, "timeout", 300)
      
      containers {
        image = each.value.image
        
        dynamic "ports" {
          for_each = lookup(each.value, "ports", [])
          content {
            container_port = ports.value.port
            name          = lookup(ports.value, "name", "http1")
            protocol      = lookup(ports.value, "protocol", "TCP")
          }
        }
        
        dynamic "env" {
          for_each = lookup(each.value, "env_vars", {})
          content {
            name  = env.key
            value = env.value
          }
        }
        
        resources {
          limits = {
            cpu    = lookup(each.value, "cpu", "1000m")
            memory = lookup(each.value, "memory", "512Mi")
          }
          requests = {
            cpu    = lookup(each.value, "cpu_request", "100m")
            memory = lookup(each.value, "memory_request", "128Mi")
          }
        }
        
        dynamic "volume_mounts" {
          for_each = lookup(each.value, "volume_mounts", [])
          content {
            name       = volume_mounts.value.name
            mount_path = volume_mounts.value.mount_path
          }
        }
      }
      
      dynamic "volumes" {
        for_each = lookup(each.value, "volumes", [])
        content {
          name = volumes.value.name
          secret {
            secret_name = volumes.value.secret_name
          }
        }
      }
    }
    
    metadata {
      annotations = merge({
        "run.googleapis.com/vpc-access-connector" = var.enable_vpc_connector ? google_vpc_access_connector.connector[0].name : null
        "autoscaling.knative.dev/maxScale"        = lookup(each.value, "max_scale", 100)
        "autoscaling.knative.dev/minScale"        = lookup(each.value, "min_scale", 0)
        "run.googleapis.com/execution-environment" = "gen2"
        "run.googleapis.com/cpu-throttling"        = lookup(each.value, "cpu_throttling", "true")
      }, lookup(each.value, "annotations", {}))
      
      labels = merge(var.labels, lookup(each.value, "labels", {}))
    }
  }
  
  dynamic "traffic" {
    for_each = lookup(each.value, "traffic", [{ percent = 100, latest_revision = true }])
    content {
      percent         = traffic.value.percent
      latest_revision = lookup(traffic.value, "latest_revision", false)
      revision_name   = lookup(traffic.value, "revision_name", null)
      tag            = lookup(traffic.value, "tag", null)
    }
  }
}

resource "google_cloud_run_service_iam_member" "invokers" {
  for_each = {
    for k, v in var.cloud_run_services : k => v
    if lookup(v, "allow_public_access", false)
  }
  
  service  = google_cloud_run_service.services[each.key].name
  location = google_cloud_run_service.services[each.key].location
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "authenticated" {
  for_each = {
    for k, v in var.cloud_run_services : k => v
    if !lookup(v, "allow_public_access", false)
  }
  
  service  = google_cloud_run_service.services[each.key].name
  location = google_cloud_run_service.services[each.key].location
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "allAuthenticatedUsers"
}

resource "google_cloud_run_domain_mapping" "custom_domains" {
  for_each = {
    for mapping in flatten([
      for service_name, service_config in var.cloud_run_services : [
        for domain in lookup(service_config, "custom_domains", []) : {
          key         = "${service_name}-${domain}"
          service     = service_name
          domain      = domain
        }
      ]
    ]) : mapping.key => mapping
  }
  
  location = var.region
  name     = each.value.domain
  project  = var.project_id
  
  spec {
    route_name = google_cloud_run_service.services[each.value.service].name
  }
}