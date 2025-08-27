output "access_policy_name" {
  description = "The name of the Access Context Manager policy"
  value       = var.enable_vpc_service_controls ? google_access_context_manager_access_policy.policy[0].name : null
}

output "service_perimeter_name" {
  description = "The name of the VPC Service Controls perimeter"
  value       = var.enable_vpc_service_controls ? google_access_context_manager_service_perimeter.perimeter[0].name : null
}

output "binary_authorization_policy" {
  description = "The Binary Authorization policy"
  value       = var.enable_binary_authorization ? google_binary_authorization_policy.policy[0].id : null
}

output "attestor_name" {
  description = "The name of the Binary Authorization attestor"
  value       = var.enable_binary_authorization ? google_binary_authorization_attestor.attestor[0].name : null
}

output "assured_workload_name" {
  description = "The name of the Assured Workloads workload"
  value       = var.enable_assured_workloads ? google_assured_workloads_workload.workload[0].name : null
}

output "service_account_email" {
  description = "Email of the compliance service account"
  value       = google_service_account.compliance.email
}