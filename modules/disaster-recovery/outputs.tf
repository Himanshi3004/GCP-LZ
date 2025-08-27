output "dr_service_account_email" {
  description = "Email of the disaster recovery service account"
  value       = google_service_account.dr_sa.email
}

output "dr_monitor_service_account_email" {
  description = "Email of the DR monitoring service account"
  value       = google_service_account.dr_monitor_sa.email
}

output "global_load_balancer_ip" {
  description = "Global load balancer IP address"
  value       = google_compute_global_address.lb_ip.address
}

output "dns_zone_name" {
  description = "DNS managed zone name"
  value       = google_dns_managed_zone.main.name
}

output "dns_zone_name_servers" {
  description = "DNS zone name servers"
  value       = google_dns_managed_zone.main.name_servers
}

output "primary_backend_services" {
  description = "Primary region backend service names"
  value       = { for k, v in google_compute_backend_service.primary : k => v.name }
}

output "dr_backend_services" {
  description = "DR region backend service names"
  value       = { for k, v in google_compute_backend_service.dr : k => v.name }
}

output "health_checks" {
  description = "Health check configurations"
  value = {
    primary = { for k, v in google_compute_health_check.primary : k => v.name }
    dr      = { for k, v in google_compute_health_check.dr : k => v.name }
  }
}

output "ssl_certificate" {
  description = "Managed SSL certificate name"
  value       = google_compute_managed_ssl_certificate.main.name
}

output "url_map" {
  description = "URL map configuration"
  value       = google_compute_url_map.main.name
}

output "dr_data_buckets" {
  description = "DR data storage bucket names"
  value       = { for k, v in google_storage_bucket.dr_data : k => v.name }
}

output "sql_replicas" {
  description = "SQL replica instance names"
  value       = { for k, v in google_sql_database_instance.dr_replica : k => v.name }
}

output "dr_clusters" {
  description = "DR GKE cluster names"
  value       = { for k, v in google_container_cluster.dr_cluster : k => v.name }
}

output "replication_jobs" {
  description = "Data replication job names"
  value = {
    data_replication = { for k, v in google_storage_transfer_job.dr_replication : k => v.name }
    gke_replication  = { for k, v in google_storage_transfer_job.gke_backup_replication : k => v.name }
  }
}

output "failover_triggers" {
  description = "Failover automation trigger names"
  value = {
    failover = var.enable_automated_failover ? google_cloudbuild_trigger.failover[0].name : null
    failback = var.enable_automated_failover ? google_cloudbuild_trigger.failback[0].name : null
  }
}

output "dr_test_triggers" {
  description = "DR testing trigger names"
  value = {
    dr_test    = google_cloudbuild_trigger.dr_test.name
    chaos_test = var.enable_chaos_engineering ? google_cloudbuild_trigger.chaos_test[0].name : null
  }
}

output "monitoring_policies" {
  description = "DR monitoring alert policy names"
  value = {
    replication_failure = google_monitoring_alert_policy.replication_failure.name
    sql_replica_lag     = var.enable_sql_replica ? google_monitoring_alert_policy.sql_replica_lag[0].name : null
  }
}

output "notification_topics" {
  description = "PubSub topics for DR notifications"
  value = {
    test_results = google_pubsub_topic.dr_test_results.name
    events       = google_pubsub_topic.dr_events.name
  }
}

output "runbook_bucket" {
  description = "DR runbook storage bucket name"
  value       = var.dr_runbook_bucket != null ? var.dr_runbook_bucket : (length(google_storage_bucket.dr_runbooks) > 0 ? google_storage_bucket.dr_runbooks[0].name : null)
}

output "dr_configuration" {
  description = "DR configuration summary"
  value = {
    primary_region           = var.primary_region
    dr_region               = var.dr_region
    rto_minutes             = var.rto_minutes
    rpo_minutes             = var.rpo_minutes
    automated_failover      = var.enable_automated_failover
    multi_region_setup      = var.enable_multi_region_setup
    traffic_split_primary   = var.traffic_split_primary
    dr_testing_enabled      = var.enable_dr_testing
    chaos_engineering       = var.enable_chaos_engineering
  }
}

output "dr_endpoints" {
  description = "DR service endpoints"
  value = {
    primary_domain = var.domain_name
    load_balancer  = "http://${google_compute_global_address.lb_ip.address}"
    health_check   = "http://${google_compute_global_address.lb_ip.address}${var.health_check_path}"
  }
}