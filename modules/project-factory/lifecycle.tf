# Project Lifecycle Management
# Manages project lifecycle including deletion protection, archival, and cleanup

# Project liens for critical projects
resource "google_resource_manager_lien" "project_liens" {
  for_each = {
    for project_key, project in var.projects : project_key => project
    if local.project_types[project.type].deletion_protection
  }
  
  parent       = "projects/${google_project.projects[each.key].number}"
  restrictions = ["resourcemanager.projects.delete"]
  origin       = "terraform-landing-zone"
  reason       = local.project_types[each.value.type].lien_reason
}

# Project archival bucket
resource "google_storage_bucket" "project_archive" {
  count    = var.enable_project_archival ? 1 : 0
  project  = var.project_id
  name     = "${var.organization_name}-project-archive"
  location = var.default_region
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 2555  # 7 years
    }
    action {
      type = "Delete"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
  
  labels = var.labels
}

# Project ownership tracking
resource "google_storage_bucket_object" "project_metadata" {
  for_each = var.projects
  
  bucket  = var.enable_project_archival ? google_storage_bucket.project_archive[0].name : null
  name    = "projects/${each.key}/metadata.json"
  content = jsonencode({
    project_id     = google_project.projects[each.key].project_id
    project_number = google_project.projects[each.key].number
    project_type   = each.value.type
    created_date   = timestamp()
    owner          = each.value.owner
    department     = each.value.department
    budget_amount  = each.value.budget_amount
    labels         = merge(var.labels, each.value.labels)
    apis_enabled   = local.project_types[each.value.type].apis
    deletion_protection = local.project_types[each.value.type].deletion_protection
  })
  
  count = var.enable_project_archival ? 1 : 0
}

# Automated cleanup policies
resource "google_pubsub_topic" "project_lifecycle" {
  count   = var.enable_project_lifecycle_automation ? 1 : 0
  project = var.project_id
  name    = "project-lifecycle-events"
  
  labels = var.labels
}

# Cloud Function for project lifecycle management
resource "google_storage_bucket_object" "lifecycle_function_zip" {
  count  = var.enable_project_lifecycle_automation ? 1 : 0
  name   = "project-lifecycle.zip"
  bucket = google_storage_bucket.budget_function_source[0].name
  source = "${path.module}/functions/project-lifecycle.zip"
}

resource "google_cloudfunctions_function" "project_lifecycle" {
  count   = var.enable_project_lifecycle_automation ? 1 : 0
  project = var.project_id
  region  = var.default_region
  name    = "project-lifecycle-manager"
  
  source_archive_bucket = google_storage_bucket.budget_function_source[0].name
  source_archive_object = google_storage_bucket_object.lifecycle_function_zip[0].name
  
  entry_point = "handleProjectLifecycle"
  runtime     = "python39"
  
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.project_lifecycle[0].id
  }
  
  environment_variables = {
    PROJECT_ID = var.project_id
    ARCHIVE_BUCKET = var.enable_project_archival ? google_storage_bucket.project_archive[0].name : ""
  }
  
  labels = var.labels
}

# Project migration capabilities
resource "google_service_account" "project_migrator" {
  count        = var.enable_project_migration ? 1 : 0
  project      = var.project_id
  account_id   = "project-migrator"
  display_name = "Project Migration Service Account"
  description  = "Handles project migration between folders and organizations"
}

resource "google_organization_iam_member" "project_migrator_roles" {
  for_each = var.enable_project_migration ? toset([
    "roles/resourcemanager.projectMover",
    "roles/resourcemanager.folderAdmin",
    "roles/billing.projectManager"
  ]) : toset([])
  
  org_id = var.organization_id
  role   = each.value
  member = "serviceAccount:${google_service_account.project_migrator[0].email}"
}

# Project cleanup scheduler
resource "google_cloud_scheduler_job" "project_cleanup" {
  count    = var.enable_automated_cleanup ? 1 : 0
  project  = var.project_id
  region   = var.default_region
  name     = "project-cleanup-scheduler"
  
  description = "Automated project cleanup based on policies"
  schedule    = "0 2 * * 0"  # Weekly on Sunday at 2 AM
  time_zone   = "UTC"
  
  pubsub_target {
    topic_name = google_pubsub_topic.project_lifecycle[0].id
    data       = base64encode(jsonencode({
      action = "cleanup"
      dry_run = var.cleanup_dry_run
    }))
  }
}