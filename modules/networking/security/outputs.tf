output "cloud_armor_policies" {
  description = "Cloud Armor security policies"
  value = {
    for policy in google_compute_security_policy.policies : policy.name => {
      id        = policy.id
      self_link = policy.self_link
      name      = policy.name
    }
  }
}

output "cloud_ids_endpoint" {
  description = "Cloud IDS endpoint information"
  value = var.enable_cloud_ids && var.ids_config != null ? {
    id                      = google_cloud_ids_endpoint.endpoint[0].id
    name                    = google_cloud_ids_endpoint.endpoint[0].name
    endpoint_forwarding_rule = google_cloud_ids_endpoint.endpoint[0].endpoint_forwarding_rule
    endpoint_ip             = google_cloud_ids_endpoint.endpoint[0].endpoint_ip
  } : null
}

output "firewall_policies" {
  description = "Hierarchical firewall policies"
  value = {
    for policy in google_compute_firewall_policy.policies : policy.short_name => {
      id        = policy.id
      name      = policy.name
      self_link = policy.self_link
    }
  }
}

output "vpc_flow_logs_dataset" {
  description = "BigQuery dataset for VPC Flow Logs"
  value = var.enable_vpc_flow_logs ? {
    dataset_id = google_bigquery_dataset.vpc_flow_logs[0].dataset_id
    project    = google_bigquery_dataset.vpc_flow_logs[0].project
    location   = google_bigquery_dataset.vpc_flow_logs[0].location
  } : null
}

output "packet_mirroring_policy" {
  description = "Packet mirroring policy information"
  value = var.enable_packet_mirroring && var.packet_mirroring_config != null ? {
    id   = google_compute_packet_mirroring.mirroring[0].id
    name = google_compute_packet_mirroring.mirroring[0].name
  } : null
}