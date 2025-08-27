variable "project_id" {
  description = "The project ID where resources will be created"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "region" {
  description = "The region for the hybrid connectivity resources"
  type        = string
  default     = "us-central1"
}

# Enhanced VPN configuration
variable "enable_vpn" {
  description = "Enable Cloud VPN"
  type        = bool
  default     = true
}

variable "vpn_gateways" {
  description = "External VPN gateway configurations"
  type = map(object({
    redundancy_type = string
    description     = string
    interfaces = list(object({
      id         = number
      ip_address = string
    }))
  }))
  default = {}
}

variable "vpn_tunnels" {
  description = "VPN tunnel configurations"
  type = map(object({
    gateway_key                     = string
    shared_secret                   = string
    vpn_gateway_interface          = number
    peer_external_gateway_interface = number
    ike_version                    = number
    interface_ip_range             = string
    peer_ip_address                = string
    peer_asn                       = number
    advertised_route_priority      = number
    advertise_mode                 = string
    advertised_groups              = list(string)
    local_traffic_selector         = list(string)
    remote_traffic_selector        = list(string)
    advertised_ip_ranges = optional(list(object({
      range       = string
      description = string
    })), [])
    enable_ipv6                    = optional(bool, false)
    ipv6_nexthop_address          = optional(string)
    peer_ipv6_nexthop_address     = optional(string)
    router_appliance_instance     = optional(string)
    interconnect_attachment       = optional(string)
  }))
  default = {}
}

variable "vpn_static_routes" {
  description = "Static routes for VPN"
  type = map(object({
    dest_range  = string
    priority    = number
    description = string
    tunnel_key  = string
    tags        = list(string)
  }))
  default = {}
}

variable "enable_vpn_monitoring" {
  description = "Enable VPN monitoring and alerting"
  type        = bool
  default     = true
}

variable "vpn_notification_channels" {
  description = "Notification channels for VPN alerts"
  type        = list(string)
  default     = []
}

variable "enable_automated_failover" {
  description = "Enable automated VPN failover procedures"
  type        = bool
  default     = false
}

variable "failover_function_bucket" {
  description = "GCS bucket for failover function code"
  type        = string
  default     = ""
}

variable "failover_function_object" {
  description = "GCS object for failover function code"
  type        = string
  default     = ""
}

variable "enable_connection_testing" {
  description = "Enable automated connection testing"
  type        = bool
  default     = false
}

variable "test_subnet" {
  description = "Subnet for VPN test instance"
  type        = string
  default     = ""
}

variable "test_service_account" {
  description = "Service account for VPN test instance"
  type        = string
  default     = ""
}

# Cloud Interconnect configuration
variable "enable_interconnect" {
  description = "Enable Cloud Interconnect"
  type        = bool
  default     = false
}

variable "interconnect_attachments" {
  description = "Interconnect attachment configurations"
  type = map(object({
    name                     = string
    description              = string
    interconnect             = string
    type                     = string
    router                   = string
    region                   = string
    vlan_tag8021q           = number
    candidate_subnets       = list(string)
    bandwidth               = string
    admin_enabled           = bool
    encryption              = string
    ipsec_internal_addresses = list(string)
  }))
  default = {}
}

variable "interconnect_config" {
  description = "Configuration for Cloud Interconnect"
  type = object({
    interconnect_name    = string
    type                = string # DEDICATED or PARTNER
    link_type           = string # LINK_TYPE_ETHERNET_10G_LR or LINK_TYPE_ETHERNET_100G_LR
    location            = string
    requested_link_count = number
    noc_contact_email   = string
    customer_name       = string
  })
  default = null
}

# BGP configuration
variable "bgp_sessions" {
  description = "BGP session configurations"
  type = list(object({
    name                      = string
    peer_ip_address          = string
    peer_asn                 = number
    advertised_route_priority = number
    interface_name           = string
    advertise_mode           = string
    advertised_groups        = list(string)
    advertised_ip_ranges = list(object({
      range       = string
      description = string
    }))
    enable_ipv6                    = bool
    ipv6_nexthop_address          = string
    peer_ipv6_nexthop_address     = string
    router_appliance_instance     = string
  }))
  default = []
}

variable "custom_routes" {
  description = "Custom routes to advertise"
  type = list(object({
    dest_range    = string
    priority      = number
    next_hop_type = string
    description   = string
    tags          = list(string)
  }))
  default = []
}

# Router configuration
variable "router_config" {
  description = "Cloud Router configuration"
  type = object({
    name        = string
    description = string
    asn         = number
    keepalive_interval = number
  })
  default = {
    name        = "hybrid-router"
    description = "Router for hybrid connectivity"
    asn         = 64512
    keepalive_interval = 20
  }
}

variable "enable_interconnect_monitoring" {
  description = "Enable Interconnect monitoring and alerting"
  type        = bool
  default     = true
}

variable "interconnect_notification_channels" {
  description = "Notification channels for Interconnect alerts"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}