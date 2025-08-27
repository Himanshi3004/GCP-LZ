# Dataflow temporary storage buckets
resource "google_storage_bucket" "dataflow_temp" {
  name     = "${var.project_id}-dataflow-temp"
  location = var.region
  project  = var.project_id
  
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "Delete"
    }
  }
  
  labels = merge(var.labels, {
    purpose = "dataflow-temp"
    environment = var.environment
  })
}

resource "google_storage_bucket" "dataflow_staging" {
  name     = "${var.project_id}-dataflow-staging"
  location = var.region
  project  = var.project_id
  
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }
  
  labels = merge(var.labels, {
    purpose = "dataflow-staging"
    environment = var.environment
  })
}

# Dataflow templates bucket
resource "google_storage_bucket" "dataflow_templates" {
  name     = "${var.project_id}-dataflow-templates"
  location = var.region
  project  = var.project_id
  
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
  
  labels = merge(var.labels, {
    purpose = "dataflow-templates"
    environment = var.environment
  })
}

# Upload custom Dataflow templates
resource "google_storage_bucket_object" "dataflow_templates" {
  for_each = var.dataflow_templates
  
  name   = "templates/${each.key}.json"
  bucket = google_storage_bucket.dataflow_templates.name
  source = each.value.template_path
  
  metadata = {
    template_type = each.value.type
    version      = each.value.version
    description  = each.value.description
  }
}

# Streaming data pipelines
resource "google_dataflow_job" "streaming_pipelines" {
  for_each = var.streaming_pipelines
  
  name              = "${each.key}-streaming-pipeline"
  project           = var.project_id
  region            = var.region
  template_gcs_path = each.value.template_path
  temp_gcs_location = "gs://${google_storage_bucket.dataflow_temp.name}/temp/${each.key}"
  
  parameters = merge(each.value.parameters, {
    tempLocation    = "gs://${google_storage_bucket.dataflow_temp.name}/temp/${each.key}"
    stagingLocation = "gs://${google_storage_bucket.dataflow_staging.name}/staging/${each.key}"
  })
  
  service_account_email = google_service_account.data_lake.email
  
  # Network configuration
  network    = each.value.network
  subnetwork = each.value.subnetwork
  
  # Machine configuration
  machine_type     = each.value.machine_type
  max_workers      = each.value.max_workers
  num_workers      = each.value.num_workers
  
  # Additional options
  additional_experiments = each.value.additional_experiments
  
  labels = merge(var.labels, {
    pipeline_type = "streaming"
    pipeline_name = each.key
    environment   = var.environment
  })
  
  depends_on = [
    google_project_service.apis,
    google_service_account.data_lake
  ]
}

# Batch data pipelines
resource "google_dataflow_job" "batch_pipelines" {
  for_each = var.batch_pipelines
  
  name              = "${each.key}-batch-pipeline"
  project           = var.project_id
  region            = var.region
  template_gcs_path = each.value.template_path
  temp_gcs_location = "gs://${google_storage_bucket.dataflow_temp.name}/temp/${each.key}"
  
  parameters = merge(each.value.parameters, {
    tempLocation    = "gs://${google_storage_bucket.dataflow_temp.name}/temp/${each.key}"
    stagingLocation = "gs://${google_storage_bucket.dataflow_staging.name}/staging/${each.key}"
  })
  
  service_account_email = google_service_account.data_lake.email
  
  # Network configuration
  network    = each.value.network
  subnetwork = each.value.subnetwork
  
  # Machine configuration
  machine_type     = each.value.machine_type
  max_workers      = each.value.max_workers
  num_workers      = each.value.num_workers
  
  # Additional options
  additional_experiments = each.value.additional_experiments
  
  labels = merge(var.labels, {
    pipeline_type = "batch"
    pipeline_name = each.key
    environment   = var.environment
  })
  
  depends_on = [
    google_project_service.apis,
    google_service_account.data_lake
  ]
}

# Flex templates for custom processing
resource "google_dataflow_flex_template_job" "flex_pipelines" {
  for_each = var.flex_pipelines
  
  name                = "${each.key}-flex-pipeline"
  project             = var.project_id
  region              = var.region
  container_spec_gcs_path = each.value.container_spec_path
  
  parameters = merge(each.value.parameters, {
    tempLocation    = "gs://${google_storage_bucket.dataflow_temp.name}/temp/${each.key}"
    stagingLocation = "gs://${google_storage_bucket.dataflow_staging.name}/staging/${each.key}"
  })
  
  service_account_email = google_service_account.data_lake.email
  
  # Network configuration
  network    = each.value.network
  subnetwork = each.value.subnetwork
  
  # Machine configuration
  machine_type     = each.value.machine_type
  max_workers      = each.value.max_workers
  num_workers      = each.value.num_workers
  
  labels = merge(var.labels, {
    pipeline_type = "flex"
    pipeline_name = each.key
    environment   = var.environment
  })
  
  depends_on = [
    google_project_service.apis,
    google_service_account.data_lake
  ]
}

# Dataproc clusters for Spark/Hadoop processing
resource "google_dataproc_cluster" "processing_clusters" {
  for_each = var.dataproc_clusters
  
  name     = "${each.key}-cluster"
  project  = var.project_id
  region   = var.region
  
  cluster_config {
    staging_bucket = google_storage_bucket.dataflow_staging.name
    
    master_config {
      num_instances = each.value.master_config.num_instances
      machine_type  = each.value.master_config.machine_type
      disk_config {
        boot_disk_type    = each.value.master_config.boot_disk_type
        boot_disk_size_gb = each.value.master_config.boot_disk_size_gb
        num_local_ssds    = each.value.master_config.num_local_ssds
      }
    }
    
    worker_config {
      num_instances = each.value.worker_config.num_instances
      machine_type  = each.value.worker_config.machine_type
      disk_config {
        boot_disk_type    = each.value.worker_config.boot_disk_type
        boot_disk_size_gb = each.value.worker_config.boot_disk_size_gb
        num_local_ssds    = each.value.worker_config.num_local_ssds
      }
    }
    
    dynamic "preemptible_worker_config" {
      for_each = each.value.preemptible_workers != null ? [each.value.preemptible_workers] : []
      content {
        num_instances = preemptible_worker_config.value.num_instances
        disk_config {
          boot_disk_type    = preemptible_worker_config.value.boot_disk_type
          boot_disk_size_gb = preemptible_worker_config.value.boot_disk_size_gb
          num_local_ssds    = preemptible_worker_config.value.num_local_ssds
        }
      }
    }
    
    software_config {
      image_version = each.value.image_version
      override_properties = each.value.properties
      
      dynamic "optional_components" {
        for_each = each.value.optional_components
        content {
          component = optional_components.value
        }
      }
    }
    
    gce_cluster_config {
      zone               = each.value.zone
      network            = each.value.network
      subnetwork         = each.value.subnetwork
      service_account    = google_service_account.data_lake.email
      service_account_scopes = each.value.service_account_scopes
      
      dynamic "shielded_instance_config" {
        for_each = each.value.enable_shielded_vm ? [1] : []
        content {
          enable_secure_boot          = true
          enable_vtpm                = true
          enable_integrity_monitoring = true
        }
      }
    }
    
    dynamic "initialization_action" {
      for_each = each.value.initialization_actions
      content {
        script      = initialization_action.value.script
        timeout_sec = initialization_action.value.timeout_sec
      }
    }
    
    dynamic "encryption_config" {
      for_each = each.value.kms_key != null ? [1] : []
      content {
        gce_pd_kms_key_name = each.value.kms_key
      }
    }
  }
  
  labels = merge(var.labels, {
    cluster_type = "dataproc"
    cluster_name = each.key
    environment  = var.environment
  })
  
  depends_on = [
    google_project_service.apis,
    google_service_account.data_lake
  ]
}

# Scheduled Dataproc jobs
resource "google_dataproc_job" "scheduled_jobs" {
  for_each = var.dataproc_jobs
  
  project = var.project_id
  region  = var.region
  
  placement {
    cluster_name = google_dataproc_cluster.processing_clusters[each.value.cluster].name
  }
  
  dynamic "spark_config" {
    for_each = each.value.job_type == "spark" ? [each.value.spark_config] : []
    content {
      main_class    = spark_config.value.main_class
      main_jar_file_uri = spark_config.value.main_jar_file_uri
      args          = spark_config.value.args
      jar_file_uris = spark_config.value.jar_file_uris
      file_uris     = spark_config.value.file_uris
      archive_uris  = spark_config.value.archive_uris
      properties    = spark_config.value.properties
      
      logging_config {
        driver_log_levels = spark_config.value.driver_log_levels
      }
    }
  }
  
  dynamic "pyspark_config" {
    for_each = each.value.job_type == "pyspark" ? [each.value.pyspark_config] : []
    content {
      main_python_file_uri = pyspark_config.value.main_python_file_uri
      args                = pyspark_config.value.args
      python_file_uris    = pyspark_config.value.python_file_uris
      jar_file_uris       = pyspark_config.value.jar_file_uris
      file_uris           = pyspark_config.value.file_uris
      archive_uris        = pyspark_config.value.archive_uris
      properties          = pyspark_config.value.properties
      
      logging_config {
        driver_log_levels = pyspark_config.value.driver_log_levels
      }
    }
  }
  
  labels = merge(var.labels, {
    job_type    = each.value.job_type
    job_name    = each.key
    environment = var.environment
  })
  
  depends_on = [
    google_dataproc_cluster.processing_clusters
  ]
}