resource "google_sourcerepo_repository" "repositories" {
  for_each = var.repositories
  
  name    = each.key
  project = var.project_id
  
  pubsub_configs {
    topic                 = google_pubsub_topic.repo_events.id
    message_format        = "JSON"
    service_account_email = google_service_account.source_management.email
  }
}

resource "google_sourcerepo_repository_iam_member" "repo_access" {
  for_each = var.repositories
  
  project    = var.project_id
  repository = google_sourcerepo_repository.repositories[each.key].name
  role       = "roles/source.writer"
  member     = "serviceAccount:${google_service_account.source_management.email}"
}

resource "google_pubsub_topic" "repo_events" {
  name    = "source-repo-events"
  project = var.project_id
  
  labels = var.labels
}

resource "google_pubsub_subscription" "repo_events_sub" {
  name    = "source-repo-events-sub"
  topic   = google_pubsub_topic.repo_events.name
  project = var.project_id
  
  message_retention_duration = "604800s"
  retain_acked_messages      = false
  ack_deadline_seconds       = 20
  
  labels = var.labels
}