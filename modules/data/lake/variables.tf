variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "enable_composer" {
  description = "Enable Cloud Composer"
  type        = bool
  default     = true
}

variable "storage_classes" {
  description = "Storage classes for different data tiers"
  type = map(string)
  default = {
    raw       = "STANDARD"
    processed = "NEARLINE"
    archive   = "COLDLINE"
    backup    = "ARCHIVE"
  }
}

variable "retention_days" {
  description = "Data retention periods"
  type = map(number)
  default = {
    raw       = 30
    processed = 90
    archive   = 365
    backup    = 2555  # 7 years
  }
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

# Enhanced storage configuration variables
variable "enable_versioning" {
  description = "Enable object versioning"
  type        = bool
  default     = true
}

variable "data_classification" {
  description = "Data classification levels for each tier"
  type = map(string)
  default = {
    raw       = "internal"
    processed = "internal"
    archive   = "confidential"
    backup    = "restricted"
  }
}

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
  default     = "data-platform"
}

variable "data_owner" {
  description = "Data owner team"
  type        = string
  default     = "data-engineering"
}

variable "kms_key_name" {
  description = "KMS key for bucket encryption"
  type        = string
  default     = null
}

variable "access_logs_retention_days" {
  description = "Retention period for access logs"
  type        = number
  default     = 90
}

variable "lifecycle_rules" {
  description = "Comprehensive lifecycle rules for each bucket tier"
  type = map(list(object({
    age                        = optional(number)
    created_before            = optional(string)
    with_state               = optional(string)
    matches_storage_class    = optional(list(string))
    num_newer_versions       = optional(number)
    custom_time_before       = optional(string)
    days_since_custom_time   = optional(number)
    days_since_noncurrent_time = optional(number)
    noncurrent_time_before   = optional(string)
    action_type              = string
    action_storage_class     = optional(string)
  })))
  default = {
    raw = [
      {
        age = 7
        action_type = "SetStorageClass"
        action_storage_class = "NEARLINE"
      },
      {
        age = 30
        action_type = "SetStorageClass"
        action_storage_class = "COLDLINE"
      },
      {
        age = 90
        action_type = "Delete"
      }
    ]
    processed = [
      {
        age = 30
        action_type = "SetStorageClass"
        action_storage_class = "COLDLINE"
      },
      {
        age = 180
        action_type = "Delete"
      }
    ]
    archive = [
      {
        age = 365
        action_type = "Delete"
      }
    ]
    backup = [
      {
        age = 2555
        action_type = "Delete"
      }
    ]
  }
}

variable "bucket_access_patterns" {
  description = "IAM access patterns for each bucket tier"
  type = map(object({
    iam_bindings = list(object({
      role      = string
      member    = string
      condition = optional(object({
        title       = string
        description = string
        expression  = string
      }))
    }))
  }))
  default = {}
}

variable "processing_service_accounts" {
  description = "Service accounts for data processing with bucket access"
  type = map(object({
    service_account = string
    bucket_tier     = string
    role           = string
  }))
  default = {}
}

variable "processing_triggers" {
  description = "Pub/Sub triggers for data processing"
  type = map(object({
    bucket_tier        = string
    pubsub_topic      = string
    event_types       = list(string)
    object_prefix     = optional(string)
    custom_attributes = optional(map(string))
  }))
  default = {}
}

variable "notification_configs" {
  description = "Bucket notification configurations"
  type = list(object({
    topic                = string
    payload_format      = string
    event_types         = list(string)
    custom_attributes   = optional(map(string))
    object_name_prefix  = optional(string)
  }))
  default = []
}

# CORS configuration
variable "enable_cors" {
  description = "Enable CORS for web access"
  type        = bool
  default     = false
}

variable "cors_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = ["*"]
}

variable "cors_methods" {
  description = "CORS allowed methods"
  type        = list(string)
  default     = ["GET", "HEAD", "PUT", "POST", "DELETE"]
}

variable "cors_headers" {
  description = "CORS allowed headers"
  type        = list(string)
  default     = ["*"]
}

variable "cors_max_age" {
  description = "CORS max age in seconds"
  type        = number
  default     = 3600
}

# Website configuration
variable "enable_website" {
  description = "Enable static website hosting per bucket"
  type        = map(bool)
  default = {
    raw       = false
    processed = false
    archive   = false
    backup    = false
  }
}

variable "website_main_page" {
  description = "Main page for static website"
  type        = string
  default     = "index.html"
}

variable "website_not_found_page" {
  description = "404 page for static website"
  type        = string
  default     = "404.html"
}# Dataflow processing variables
variable "dataflow_templates" {
  description = "Custom Dataflow templates to upload"
  type = map(object({
    template_path = string
    type         = string
    version      = string
    description  = string
  }))
  default = {}
}

variable "streaming_pipelines" {
  description = "Streaming Dataflow pipelines configuration"
  type = map(object({
    template_path          = string
    parameters            = map(string)
    network               = optional(string)
    subnetwork            = optional(string)
    machine_type          = optional(string, "n1-standard-1")
    max_workers           = optional(number, 10)
    num_workers           = optional(number, 1)
    additional_experiments = optional(list(string), [])
  }))
  default = {}
}

variable "batch_pipelines" {
  description = "Batch Dataflow pipelines configuration"
  type = map(object({
    template_path          = string
    parameters            = map(string)
    network               = optional(string)
    subnetwork            = optional(string)
    machine_type          = optional(string, "n1-standard-1")
    max_workers           = optional(number, 10)
    num_workers           = optional(number, 1)
    additional_experiments = optional(list(string), [])
  }))
  default = {}
}

variable "flex_pipelines" {
  description = "Flex template Dataflow pipelines configuration"
  type = map(object({
    container_spec_path    = string
    parameters            = map(string)
    network               = optional(string)
    subnetwork            = optional(string)
    machine_type          = optional(string, "n1-standard-1")
    max_workers           = optional(number, 10)
    num_workers           = optional(number, 1)
  }))
  default = {}
}

# Dataproc cluster variables
variable "dataproc_clusters" {
  description = "Dataproc clusters configuration"
  type = map(object({
    zone                    = string
    network                = string
    subnetwork             = string
    image_version          = optional(string, "2.0-debian10")
    enable_shielded_vm     = optional(bool, true)
    kms_key                = optional(string)
    service_account_scopes = optional(list(string), ["https://www.googleapis.com/auth/cloud-platform"])
    
    master_config = object({
      num_instances     = optional(number, 1)
      machine_type      = optional(string, "n1-standard-2")
      boot_disk_type    = optional(string, "pd-standard")
      boot_disk_size_gb = optional(number, 50)
      num_local_ssds    = optional(number, 0)
    })
    
    worker_config = object({
      num_instances     = optional(number, 2)
      machine_type      = optional(string, "n1-standard-2")
      boot_disk_type    = optional(string, "pd-standard")
      boot_disk_size_gb = optional(number, 50)
      num_local_ssds    = optional(number, 0)
    })
    
    preemptible_workers = optional(object({
      num_instances     = number
      boot_disk_type    = optional(string, "pd-standard")
      boot_disk_size_gb = optional(number, 50)
      num_local_ssds    = optional(number, 0)
    }))
    
    properties           = optional(map(string), {})
    optional_components  = optional(list(string), [])
    initialization_actions = optional(list(object({
      script      = string
      timeout_sec = optional(number, 300)
    })), [])
  }))
  default = {}
}

variable "dataproc_jobs" {
  description = "Scheduled Dataproc jobs configuration"
  type = map(object({
    cluster  = string
    job_type = string
    
    spark_config = optional(object({
      main_class           = string
      main_jar_file_uri    = string
      args                = optional(list(string), [])
      jar_file_uris       = optional(list(string), [])
      file_uris           = optional(list(string), [])
      archive_uris        = optional(list(string), [])
      properties          = optional(map(string), {})
      driver_log_levels   = optional(map(string), {})
    }))
    
    pyspark_config = optional(object({
      main_python_file_uri = string
      args                = optional(list(string), [])
      python_file_uris    = optional(list(string), [])
      jar_file_uris       = optional(list(string), [])
      file_uris           = optional(list(string), [])
      archive_uris        = optional(list(string), [])
      properties          = optional(map(string), {})
      driver_log_levels   = optional(map(string), {})
    }))
  }))
  default = {}
}

# Pub/Sub variables
variable "pubsub_topics" {
  description = "Pub/Sub topics configuration"
  type = map(object({
    message_retention_duration   = optional(string, "604800s")
    topic_type                  = string
    data_source                 = string
    allowed_persistence_regions = optional(list(string))
    schema = optional(object({
      name     = string
      encoding = string
    }))
  }))
  default = {}
}

variable "dead_letter_topics" {
  description = "Dead letter topics configuration"
  type = map(object({
    message_retention_duration = optional(string, "604800s")
  }))
  default = {}
}

variable "pubsub_schemas" {
  description = "Pub/Sub schemas for message validation"
  type = map(object({
    type       = string
    definition = string
  }))
  default = {}
}

variable "pubsub_subscriptions" {
  description = "Pub/Sub subscriptions configuration"
  type = map(object({
    topic                      = string
    subscription_type          = string
    message_retention_duration = optional(string, "604800s")
    retain_acked_messages      = optional(bool, false)
    ack_deadline_seconds       = optional(number, 20)
    expiration_ttl            = optional(string)
    filter                    = optional(string)
    enable_message_ordering   = optional(bool, false)
    dead_letter_topic         = optional(string)
    max_delivery_attempts     = optional(number, 5)
    
    retry_policy = optional(object({
      minimum_backoff = string
      maximum_backoff = string
    }))
    
    push_config = optional(object({
      push_endpoint = string
      attributes    = optional(map(string), {})
      oidc_token = optional(object({
        service_account_email = string
        audience             = string
      }))
    }))
    
    bigquery_config = optional(object({
      table               = string
      use_topic_schema    = optional(bool, false)
      write_metadata      = optional(bool, false)
      drop_unknown_fields = optional(bool, false)
    }))
    
    cloud_storage_config = optional(object({
      bucket          = string
      filename_prefix = optional(string)
      filename_suffix = optional(string)
      max_duration    = optional(string, "300s")
      max_bytes       = optional(number, 1000000)
      avro_config = optional(object({
        write_metadata = bool
      }))
    }))
  }))
  default = {}
}

variable "pubsub_snapshots" {
  description = "Pub/Sub snapshots configuration"
  type = map(object({
    subscription  = string
    snapshot_type = string
  }))
  default = {}
}

variable "topic_iam_bindings" {
  description = "IAM bindings for Pub/Sub topics"
  type = map(object({
    bindings = list(object({
      role    = string
      members = list(string)
      condition = optional(object({
        title       = string
        description = string
        expression  = string
      }))
    }))
  }))
  default = {}
}

variable "subscription_iam_bindings" {
  description = "IAM bindings for Pub/Sub subscriptions"
  type = map(object({
    bindings = list(object({
      role    = string
      members = list(string)
      condition = optional(object({
        title       = string
        description = string
        expression  = string
      }))
    }))
  }))
  default = {}
}

# Cloud Composer variables
variable "composer_environments" {
  description = "Cloud Composer environments configuration"
  type = map(object({
    node_count       = optional(number, 3)
    zone            = string
    machine_type    = optional(string, "e2-medium")
    disk_size_gb    = optional(number, 30)
    network         = string
    subnetwork      = string
    oauth_scopes    = optional(list(string), ["https://www.googleapis.com/auth/cloud-platform"])
    tags            = optional(list(string), [])
    image_version   = optional(string, "composer-2-airflow-2")
    python_version  = optional(string, "3")
    environment_type = string
    private_environment = optional(bool, true)
    kms_key         = optional(string)
    
    ip_allocation_policy = optional(object({
      use_ip_aliases                = bool
      cluster_secondary_range_name  = string
      services_secondary_range_name = string
      cluster_ipv4_cidr_block      = optional(string)
      services_ipv4_cidr_block     = optional(string)
    }))
    
    private_environment_config = optional(object({
      enable_private_endpoint    = bool
      master_ipv4_cidr_block    = string
      cloud_sql_ipv4_cidr_block = string
      web_server_ipv4_cidr_block = string
      private_cluster_config = optional(object({
        enable_private_nodes    = bool
        master_ipv4_cidr_block = string
      }))
    }))
    
    web_server_config = optional(object({
      machine_type = string
    }))
    
    database_config = optional(object({
      machine_type = string
    }))
    
    maintenance_window = optional(object({
      start_time = string
      end_time   = string
      recurrence = string
    }))
    
    workloads_config = optional(object({
      scheduler = optional(object({
        cpu        = number
        memory_gb  = number
        storage_gb = number
        count      = number
      }))
      web_server = optional(object({
        cpu        = number
        memory_gb  = number
        storage_gb = number
      }))
      worker = optional(object({
        cpu        = number
        memory_gb  = number
        storage_gb = number
        min_count  = number
        max_count  = number
      }))
    }))
    
    pypi_packages            = optional(map(string), {})
    env_variables           = optional(map(string), {})
    airflow_config_overrides = optional(map(string), {})
    
    dags = optional(map(object({
      template      = string
      template_vars = map(string)
    })), {})
    
    plugins = optional(map(object({
      source_file = string
    })), {})
    
    data_files = optional(map(object({
      content = string
    })), {})
  }))
  default = {}
}

variable "composer_iam_bindings" {
  description = "IAM bindings for Composer environments"
  type = map(object({
    bindings = list(object({
      role    = string
      members = list(string)
      condition = optional(object({
        title       = string
        description = string
        expression  = string
      }))
    }))
  }))
  default = {}
}