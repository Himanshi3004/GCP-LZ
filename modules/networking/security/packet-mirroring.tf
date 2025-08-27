# Packet Mirroring Policy
resource "google_compute_packet_mirroring" "mirroring" {
  count = var.enable_packet_mirroring && var.packet_mirroring_config != null ? 1 : 0
  
  name        = var.packet_mirroring_config.name
  project     = var.project_id
  region      = var.region
  description = var.packet_mirroring_config.description
  
  network {
    url = data.google_compute_network.network.id
  }
  
  collector_ilb {
    url = var.packet_mirroring_config.collector_ilb
  }
  
  mirrored_resources {
    dynamic "subnetworks" {
      for_each = var.packet_mirroring_config.mirrored_resources.subnetworks
      content {
        url = "projects/${var.project_id}/regions/${var.region}/subnetworks/${subnetworks.value}"
      }
    }
    
    dynamic "instances" {
      for_each = var.packet_mirroring_config.mirrored_resources.instances
      content {
        url = "projects/${var.project_id}/zones/${var.region}-a/instances/${instances.value}"
      }
    }
    
    tags = var.packet_mirroring_config.mirrored_resources.tags
  }
  
  filter {
    ip_protocols = var.packet_mirroring_config.filter.ip_protocols
    cidr_ranges  = var.packet_mirroring_config.filter.cidr_ranges
    direction    = var.packet_mirroring_config.filter.direction
  }
}