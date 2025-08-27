# Cloud Composer environments for workflow orchestration
resource "google_composer_environment" "data_orchestration" {
  for_each = var.composer_environments
  
  name    = each.key
  region  = var.region
  project = var.project_id
  
  config {
    node_count = each.value.node_count
    
    node_config {
      zone         = each.value.zone
      machine_type = each.value.machine_type
      disk_size_gb = each.value.disk_size_gb
      
      service_account = google_service_account.data_lake.email
      
      # Network configuration
      network    = each.value.network
      subnetwork = each.value.subnetwork
      
      # OAuth scopes
      oauth_scopes = each.value.oauth_scopes
      
      # Tags for firewall rules
      tags = each.value.tags
      
      # IP allocation policy
      dynamic "ip_allocation_policy" {
        for_each = each.value.ip_allocation_policy != null ? [each.value.ip_allocation_policy] : []
        content {
          use_ip_aliases                = ip_allocation_policy.value.use_ip_aliases
          cluster_secondary_range_name  = ip_allocation_policy.value.cluster_secondary_range_name
          services_secondary_range_name = ip_allocation_policy.value.services_secondary_range_name
          cluster_ipv4_cidr_block      = ip_allocation_policy.value.cluster_ipv4_cidr_block
          services_ipv4_cidr_block     = ip_allocation_policy.value.services_ipv4_cidr_block
        }
      }
    }
    
    software_config {
      image_version = each.value.image_version
      
      # Python packages
      pypi_packages = merge(each.value.pypi_packages, {
        "apache-airflow-providers-google" = ""
        "pandas"                         = ""
        "numpy"                          = ""
        "google-cloud-storage"           = ""
        "google-cloud-bigquery"          = ""
        "google-cloud-dataflow-client"   = ""
      })
      
      # Environment variables
      env_variables = merge(each.value.env_variables, {
        PROJECT_ID = var.project_id
        REGION     = var.region
        ENVIRONMENT = var.environment
      })
      
      # Airflow configuration overrides
      airflow_config_overrides = each.value.airflow_config_overrides
      
      # Python version
      python_version = each.value.python_version
    }
    
    # Private environment configuration
    dynamic "private_environment_config" {
      for_each = each.value.private_environment ? [each.value.private_environment_config] : []
      content {
        enable_private_endpoint   = private_environment_config.value.enable_private_endpoint
        master_ipv4_cidr_block   = private_environment_config.value.master_ipv4_cidr_block
        cloud_sql_ipv4_cidr_block = private_environment_config.value.cloud_sql_ipv4_cidr_block
        web_server_ipv4_cidr_block = private_environment_config.value.web_server_ipv4_cidr_block
        
        dynamic "private_cluster_config" {
          for_each = private_environment_config.value.private_cluster_config != null ? [private_environment_config.value.private_cluster_config] : []
          content {
            enable_private_nodes    = private_cluster_config.value.enable_private_nodes
            master_ipv4_cidr_block = private_cluster_config.value.master_ipv4_cidr_block
          }
        }
      }
    }
    
    # Web server configuration
    dynamic "web_server_config" {
      for_each = each.value.web_server_config != null ? [each.value.web_server_config] : []
      content {
        machine_type = web_server_config.value.machine_type
      }
    }
    
    # Database configuration
    dynamic "database_config" {
      for_each = each.value.database_config != null ? [each.value.database_config] : []
      content {
        machine_type = database_config.value.machine_type
      }
    }
    
    # Encryption configuration
    dynamic "encryption_config" {
      for_each = each.value.kms_key != null ? [1] : []
      content {
        kms_key_name = each.value.kms_key
      }
    }
    
    # Maintenance window
    dynamic "maintenance_window" {
      for_each = each.value.maintenance_window != null ? [each.value.maintenance_window] : []
      content {
        start_time = maintenance_window.value.start_time
        end_time   = maintenance_window.value.end_time
        recurrence = maintenance_window.value.recurrence
      }
    }
    
    # Workloads configuration
    dynamic "workloads_config" {
      for_each = each.value.workloads_config != null ? [each.value.workloads_config] : []
      content {
        dynamic "scheduler" {
          for_each = workloads_config.value.scheduler != null ? [workloads_config.value.scheduler] : []
          content {
            cpu        = scheduler.value.cpu
            memory_gb  = scheduler.value.memory_gb
            storage_gb = scheduler.value.storage_gb
            count      = scheduler.value.count
          }
        }
        
        dynamic "web_server" {
          for_each = workloads_config.value.web_server != null ? [workloads_config.value.web_server] : []
          content {
            cpu        = web_server.value.cpu
            memory_gb  = web_server.value.memory_gb
            storage_gb = web_server.value.storage_gb
          }
        }
        
        dynamic "worker" {
          for_each = workloads_config.value.worker != null ? [workloads_config.value.worker] : []
          content {
            cpu        = worker.value.cpu
            memory_gb  = worker.value.memory_gb
            storage_gb = worker.value.storage_gb
            min_count  = worker.value.min_count
            max_count  = worker.value.max_count
          }
        }
      }
    }
  }
  
  labels = merge(var.labels, {
    environment_type = each.value.environment_type
    environment_name = each.key
    environment      = var.environment
  })
  
  depends_on = [
    google_project_service.apis,
    google_service_account.data_lake
  ]
}

# Upload DAG files to Composer environments
resource "google_storage_bucket_object" "dag_files" {
  for_each = local.dag_files
  
  name   = "dags/${each.key}"
  bucket = split("/", google_composer_environment.data_orchestration[each.value.environment].config[0].dag_gcs_prefix)[2]
  
  content = templatefile("${path.module}/templates/dags/${each.value.template}", each.value.template_vars)
  
  depends_on = [google_composer_environment.data_orchestration]
}

# Upload plugin files to Composer environments
resource "google_storage_bucket_object" "plugin_files" {
  for_each = local.plugin_files
  
  name   = "plugins/${each.key}"
  bucket = split("/", google_composer_environment.data_orchestration[each.value.environment].config[0].dag_gcs_prefix)[2]
  
  source = "${path.module}/templates/plugins/${each.value.source_file}"
  
  depends_on = [google_composer_environment.data_orchestration]
}

# Upload data files and configurations
resource "google_storage_bucket_object" "data_files" {
  for_each = local.data_files
  
  name   = "data/${each.key}"
  bucket = split("/", google_composer_environment.data_orchestration[each.value.environment].config[0].dag_gcs_prefix)[2]
  
  content = each.value.content
  
  depends_on = [google_composer_environment.data_orchestration]
}

# Composer environment IAM bindings
resource "google_composer_environment_iam_binding" "composer_bindings" {
  for_each = local.composer_iam_bindings
  
  project     = var.project_id
  region      = var.region
  environment = google_composer_environment.data_orchestration[each.value.environment].name
  role        = each.value.role
  members     = each.value.members
  
  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Local values for file and IAM management
locals {
  dag_files = merge([
    for env_key, env_config in var.composer_environments : {
      for dag_key, dag_config in env_config.dags :
      "${dag_key}.py" => {
        environment   = env_key
        template      = dag_config.template
        template_vars = merge(dag_config.template_vars, {
          project_id  = var.project_id
          region      = var.region
          environment = var.environment
        })
      }
    }
  ]...)
  
  plugin_files = merge([
    for env_key, env_config in var.composer_environments : {
      for plugin_key, plugin_config in env_config.plugins :
      plugin_key => {
        environment = env_key
        source_file = plugin_config.source_file
      }
    }
  ]...)
  
  data_files = merge([
    for env_key, env_config in var.composer_environments : {
      for data_key, data_config in env_config.data_files :
      data_key => {
        environment = env_key
        content     = data_config.content
      }
    }
  ]...)
  
  composer_iam_bindings = merge([
    for env_key, env_config in var.composer_iam_bindings : {
      for binding in env_config.bindings :
      "${env_key}-${binding.role}" => {
        environment = env_key
        role        = binding.role
        members     = binding.members
        condition   = binding.condition
      }
    }
  ]...)
}