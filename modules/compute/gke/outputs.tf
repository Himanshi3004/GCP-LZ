output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate of the GKE cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "service_account_email" {
  description = "Email of the GKE service account"
  value       = google_service_account.gke.email
}

output "workload_identity_sa_email" {
  description = "Email of the Workload Identity service account"
  value       = var.enable_workload_identity ? google_service_account.workload_identity[0].email : null
}

output "backup_plan_name" {
  description = "Name of the GKE backup plan"
  value       = google_gke_backup_backup_plan.plan.name
}