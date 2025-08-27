output "access_policy_name" {
  description = "The name of the access policy"
  value       = google_access_context_manager_access_policy.policy.name
}

output "service_perimeter_name" {
  description = "The name of the service perimeter"
  value       = google_access_context_manager_service_perimeter.perimeter.name
}

output "access_level_name" {
  description = "The name of the access level"
  value       = google_access_context_manager_access_level.basic_level.name
}

# Additional outputs for main module integration
output "access_policy_id" {
  description = "The ID of the access policy"
  value       = google_access_context_manager_access_policy.policy.name
}

output "main_perimeter" {
  description = "Main service perimeter"
  value = {
    name = google_access_context_manager_service_perimeter.perimeter.name
    id   = google_access_context_manager_service_perimeter.perimeter.name
  }
}

output "bridge_perimeter" {
  description = "Bridge service perimeter"
  value = length(var.bridge_perimeter_projects) > 0 ? {
    name = google_access_context_manager_service_perimeter.bridge_perimeter[0].name
    id   = google_access_context_manager_service_perimeter.bridge_perimeter[0].name
  } : null
}

output "basic_access_level" {
  description = "Basic access level"
  value = {
    name = google_access_context_manager_access_level.basic_level.name
    id   = google_access_context_manager_access_level.basic_level.name
  }
}

output "device_trust_level" {
  description = "Device trust access level"
  value = {
    name = google_access_context_manager_access_level.device_trust.name
    id   = google_access_context_manager_access_level.device_trust.name
  }
}

output "time_based_level" {
  description = "Time-based access level"
  value = var.enable_time_based_access ? {
    name = google_access_context_manager_access_level.time_based[0].name
    id   = google_access_context_manager_access_level.time_based[0].name
  } : null
}