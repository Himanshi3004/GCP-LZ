variable "host_project_id" {
  description = "The project ID of the shared VPC host project"
  type        = string
}

variable "service_project_ids" {
  description = "List of service project IDs to attach to the shared VPC"
  type        = list(string)
  default     = []
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "shared-vpc"
}

variable "default_region" {
  description = "Default region for network resources"
  type        = string
  default     = "us-central1"
}

variable "subnets" {
  description = "List of subnets to create with enhanced configuration"
  type = list(object({
    name                     = string
    ip_cidr_range           = string
    region                  = string
    description             = optional(string)
    private_ip_google_access = optional(bool, true)
    
    # Flow logs configuration
    flow_logs_aggregation_interval = optional(string, "INTERVAL_10_MIN")
    flow_logs_sampling            = optional(number, 0.5)
    flow_logs_metadata            = optional(string, "INCLUDE_ALL_METADATA")
    flow_logs_metadata_fields     = optional(list(string), [])
    flow_logs_filter              = optional(string, "true")
    
    # Purpose and role for specialized subnets
    purpose          = optional(string)
    role             = optional(string)
    stack_type       = optional(string, "IPV4_ONLY")
    ipv6_access_type = optional(string)
    
    # Environment and workload classification
    environment    = optional(string, "unknown")
    workload_type  = optional(string, "general")
    
    # IAM members for subnet access
    subnet_users  = optional(list(string), [])
    subnet_admins = optional(list(string), [])
    
    # Secondary IP ranges for GKE
    secondary_ip_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
  }))
  default = []
}

variable "firewall_rules" {
  description = "List of firewall rules to create"
  type = list(object({
    name        = string
    description = optional(string)
    direction   = optional(string, "INGRESS")
    priority    = optional(number, 1000)
    ranges      = optional(list(string), [])
    source_tags = optional(list(string), [])
    target_tags = optional(list(string), [])
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
  }))
  default = []
}

variable "enable_cloud_nat" {
  description = "Enable Cloud NAT for the network"
  type        = bool
  default     = true
}

variable "nat_regions" {
  description = "List of regions where Cloud NAT should be created"
  type        = list(string)
  default     = ["us-central1"]
}

variable "enable_private_service_connect" {
  description = "Enable Private Service Connect"
  type        = bool
  default     = true
}

variable "psc_subnet_cidr" {
  description = "CIDR range for Private Service Connect subnet"
  type        = string
  default     = "10.0.255.0/24"
}

variable "generate_subnet_docs" {
  description = "Generate subnet allocation documentation"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}# Private Service Connect variables
variable "psc_google_services" {
  description = "Google services to create PSC endpoints for"
  type = map(object({
    target = string
  }))
  default = {
    storage = {
      target = "storage-googleapis-com"
    }
    bigquery = {
      target = "bigquery-googleapis-com"
    }
    pubsub = {
      target = "pubsub-googleapis-com"
    }
  }
}

variable "psc_published_services" {
  description = "Internal services to publish via PSC"
  type = map(object({
    name                    = string
    region                  = string
    description             = string
    target_service          = string
    connection_preference   = string
    nat_subnets            = list(string)
    enable_proxy_protocol  = bool
    consumer_reject_lists  = list(string)
    consumer_accept_lists = list(object({
      project_id_or_num = string
      connection_limit  = number
    }))
  }))
  default = {}
}

variable "psc_consumer_endpoints" {
  description = "PSC consumer endpoints for internal services"
  type = map(object({
    name           = string
    region         = string
    subnetwork     = string
    target_service = string
  }))
  default = {}
}

variable "psc_dns_zones" {
  description = "DNS zones for PSC endpoints"
  type = map(object({
    name        = string
    dns_name    = string
    description = string
  }))
  default = {}
}

variable "psc_dns_records" {
  description = "DNS records for PSC endpoints"
  type = map(object({
    name     = string
    zone_key = string
    type     = string
    ttl      = number
    rrdatas  = list(string)
  }))
  default = {}
}

variable "enable_psc_monitoring" {
  description = "Enable PSC connection monitoring"
  type        = bool
  default     = true
}

variable "psc_notification_channels" {
  description = "Notification channels for PSC alerts"
  type        = list(string)
  default     = []
}# Enhanced firewall variables
variable "enable_security_groups" {
  description = "Enable predefined security group firewall rules"
  type        = bool
  default     = true
}

variable "web_tier_allowed_sources" {
  description = "Source IP ranges allowed to access web tier"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_tier_ports" {
  description = "Ports allowed for app tier communication"
  type        = list(string)
  default     = ["8080", "8443"]
}

variable "db_tier_ports" {
  description = "Ports allowed for database tier communication"
  type        = list(string)
  default     = ["3306", "5432", "1433"]
}

variable "enable_egress_internet" {
  description = "Enable controlled egress to internet"
  type        = bool
  default     = true
}

variable "enable_firewall_insights" {
  description = "Enable firewall insights for rule optimization"
  type        = bool
  default     = true
}