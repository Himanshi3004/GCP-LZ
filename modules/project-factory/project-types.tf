# Project Type Definitions
# Defines different project types with their specific configurations

locals {
  project_types = {
    shared-vpc-host = {
      apis = [
        "compute.googleapis.com",
        "servicenetworking.googleapis.com",
        "dns.googleapis.com",
        "cloudresourcemanager.googleapis.com"
      ]
      default_roles = [
        "roles/compute.networkAdmin",
        "roles/dns.admin",
        "roles/servicenetworking.networksAdmin"
      ]
      budget_multiplier = 2.0
      deletion_protection = true
      essential_contacts = ["network-team@${var.domain_name}"]
      lien_reason = "Critical shared VPC host project"
      labels = {
        type = "shared-vpc-host"
        tier = "infrastructure"
        criticality = "critical"
        backup_required = "true"
      }
    }
    
    application = {
      apis = [
        "compute.googleapis.com",
        "container.googleapis.com",
        "run.googleapis.com",
        "cloudfunctions.googleapis.com",
        "monitoring.googleapis.com",
        "logging.googleapis.com"
      ]
      default_roles = [
        "roles/compute.instanceAdmin.v1",
        "roles/container.developer",
        "roles/run.developer"
      ]
      budget_multiplier = 1.0
      deletion_protection = false
      essential_contacts = ["app-team@${var.domain_name}"]
      lien_reason = null
      labels = {
        type = "application"
        tier = "workload"
        criticality = "medium"
        backup_required = "true"
      }
    }
    
    data = {
      apis = [
        "bigquery.googleapis.com",
        "storage.googleapis.com",
        "dataflow.googleapis.com",
        "pubsub.googleapis.com",
        "datacatalog.googleapis.com",
        "dlp.googleapis.com"
      ]
      default_roles = [
        "roles/bigquery.dataEditor",
        "roles/storage.admin",
        "roles/dataflow.developer"
      ]
      budget_multiplier = 1.5
      deletion_protection = true
      essential_contacts = ["data-team@${var.domain_name}"]
      lien_reason = "Critical data processing project"
      labels = {
        type = "data"
        tier = "platform"
        criticality = "high"
        backup_required = "true"
      }
    }
    
    security = {
      apis = [
        "securitycenter.googleapis.com",
        "cloudasset.googleapis.com",
        "cloudkms.googleapis.com",
        "dlp.googleapis.com",
        "binaryauthorization.googleapis.com"
      ]
      default_roles = [
        "roles/securitycenter.admin",
        "roles/cloudkms.admin",
        "roles/dlp.admin"
      ]
      budget_multiplier = 1.2
      deletion_protection = true
      essential_contacts = ["security-team@${var.domain_name}"]
      lien_reason = "Critical security monitoring project"
      labels = {
        type = "security"
        tier = "platform"
        criticality = "critical"
        backup_required = "true"
      }
    }
    
    tooling = {
      apis = [
        "cloudbuild.googleapis.com",
        "sourcerepo.googleapis.com",
        "containerregistry.googleapis.com",
        "artifactregistry.googleapis.com",
        "cloudresourcemanager.googleapis.com"
      ]
      default_roles = [
        "roles/cloudbuild.builds.editor",
        "roles/source.admin",
        "roles/artifactregistry.admin"
      ]
      budget_multiplier = 0.8
      deletion_protection = false
      essential_contacts = ["devops-team@${var.domain_name}"]
      lien_reason = null
      labels = {
        type = "tooling"
        tier = "platform"
        criticality = "medium"
        backup_required = "false"
      }
    }
  }
}

# Project type validation
locals {
  valid_project_types = keys(local.project_types)
  
  # Validate project types in projects variable
  invalid_types = [
    for project_key, project in var.projects : project_key
    if !contains(local.valid_project_types, project.type)
  ]
}

# Error if invalid project types are specified
resource "null_resource" "validate_project_types" {
  count = length(local.invalid_types) > 0 ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo 'Error: Invalid project types found: ${join(", ", local.invalid_types)}. Valid types: ${join(", ", local.valid_project_types)}' && exit 1"
  }
}