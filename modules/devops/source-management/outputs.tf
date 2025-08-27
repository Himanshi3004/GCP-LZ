output "repository_urls" {
  description = "URLs of created repositories"
  value       = { for k, v in google_sourcerepo_repository.repositories : k => v.url }
}

output "github_triggers" {
  description = "GitHub integration trigger IDs"
  value = var.enable_github_integration ? {
    pr_triggers   = { for k, v in google_cloudbuild_trigger.github_pr_trigger : k => v.trigger_id }
    push_triggers = { for k, v in google_cloudbuild_trigger.github_push_trigger : k => v.trigger_id }
  } : {}
}

output "security_scan_triggers" {
  description = "Security scan trigger IDs"
  value       = { for k, v in google_cloudbuild_trigger.security_scan : k => v.trigger_id }
}

output "code_review_triggers" {
  description = "Code review trigger IDs"
  value       = { for k, v in google_cloudbuild_trigger.code_review_trigger : k => v.trigger_id }
}

output "branch_protection_triggers" {
  description = "Branch protection trigger IDs"
  value       = { for k, v in google_cloudbuild_trigger.branch_protection : k => v.trigger_id }
}

output "pubsub_topics" {
  description = "Pub/Sub topic names"
  value = {
    repo_events        = google_pubsub_topic.repo_events.name
    code_review_events = google_pubsub_topic.code_review_events.name
  }
}

output "service_account_email" {
  description = "Source management service account email"
  value       = google_service_account.source_management.email
}