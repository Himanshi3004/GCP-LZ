# Hierarchical Firewall Policies
resource "google_compute_firewall_policy" "policies" {
  for_each = var.enable_hierarchical_firewall ? { for policy in var.firewall_policies : policy.name => policy } : {}
  
  short_name  = each.value.name
  parent      = each.value.parent
  description = each.value.description
}

# Firewall Policy Rules
resource "google_compute_firewall_policy_rule" "rules" {
  for_each = var.enable_hierarchical_firewall ? {
    for rule in flatten([
      for policy in var.firewall_policies : [
        for rule in policy.rules : {
          policy_name = policy.name
          rule_name   = "${policy.name}-${rule.priority}"
          rule        = rule
        }
      ]
    ]) : rule.rule_name => rule
  } : {}
  
  firewall_policy = google_compute_firewall_policy.policies[each.value.policy_name].id
  description     = each.value.rule.description
  direction       = each.value.rule.direction
  action          = each.value.rule.action
  priority        = each.value.rule.priority
  
  match {
    dynamic "layer4_configs" {
      for_each = each.value.rule.match.layer4_configs
      content {
        ip_protocol = layer4_configs.value.ip_protocol
        ports       = layer4_configs.value.ports
      }
    }
    
    dest_ip_ranges = each.value.rule.match.dest_ip_ranges
    src_ip_ranges  = each.value.rule.match.src_ip_ranges
  }
}

# Associate firewall policy with network
resource "google_compute_firewall_policy_association" "associations" {
  for_each = var.enable_hierarchical_firewall ? { for policy in var.firewall_policies : policy.name => policy } : {}
  
  firewall_policy = google_compute_firewall_policy.policies[each.key].id
  attachment_target = data.google_compute_network.network.id
  name             = "${each.key}-association"
}