resource "google_clouddeploy_delivery_pipeline" "pipeline" {
  for_each = var.pipelines
  
  location = var.region
  name     = "${each.key}-delivery-pipeline"
  project  = var.project_id
  
  description = "Delivery pipeline for ${each.key}"
  
  serial_pipeline {
    dynamic "stages" {
      for_each = each.value.environments
      content {
        target_id = "${each.key}-${stages.value}"
        profiles  = [stages.value]
      }
    }
  }
  
  labels = var.labels
}

resource "google_clouddeploy_target" "targets" {
  for_each = {
    for combo in flatten([
      for pipeline_key, pipeline in var.pipelines : [
        for env in pipeline.environments : {
          key         = "${pipeline_key}-${env}"
          pipeline    = pipeline_key
          environment = env
          service     = pipeline.target_service
        }
      ]
    ]) : combo.key => combo
  }
  
  location = var.region
  name     = each.value.key
  project  = var.project_id
  
  description = "Target for ${each.value.pipeline} in ${each.value.environment}"
  
  run {
    location = "projects/${var.project_id}/locations/${var.region}"
  }
  
  require_approval = contains(var.approval_required, each.value.environment)
  
  labels = var.labels
}

resource "google_cloud_run_service" "services" {
  for_each = {
    for combo in flatten([
      for pipeline_key, pipeline in var.pipelines : [
        for env in pipeline.environments : {
          key         = "${pipeline_key}-${env}"
          pipeline    = pipeline_key
          environment = env
          service     = pipeline.target_service
        }
      ]
    ]) : combo.key => combo
  }
  
  name     = "${each.value.service}-${each.value.environment}"
  location = var.region
  project  = var.project_id
  
  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
        
        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }
      
      service_account_name = google_service_account.cicd_pipeline.email
    }
    
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = each.value.environment == "prod" ? "100" : "10"
      }
      
      labels = merge(var.labels, {
        environment = each.value.environment
        service     = each.value.service
      })
    }
  }
  
  traffic {
    percent         = 100
    latest_revision = true
  }
}