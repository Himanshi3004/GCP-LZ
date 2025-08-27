# Resource naming standards and validation

locals {
  # Naming convention patterns
  naming_patterns = {
    folder = {
      environment = "${var.organization_name}-{environment}"
      department  = "{department}"
      team        = "{team}"
    }
    project = {
      standard = "${var.organization_name}-{department}-{environment}-{suffix}"
      shared   = "${var.organization_name}-shared-{environment}-{suffix}"
    }
  }
  
  # Validation rules for folder names
  folder_name_validation = {
    max_length = 30
    allowed_chars = "abcdefghijklmnopqrstuvwxyz0123456789-"
    pattern = "^[a-z][a-z0-9-]*[a-z0-9]$"
  }
  
  # Standard labels for all resources
  standard_labels = merge(var.labels, {
    managed_by = "terraform"
    module     = "organization"
    created_by = "gcp-landing-zone"
  })
  
  # Environment-specific labels
  environment_labels = {
    for env in ["dev", "staging", "prod"] : env => merge(local.standard_labels, {
      environment = env
      cost_center = "${var.organization_name}-${env}"
      backup_policy = env == "prod" ? "critical" : "standard"
    })
  }
  
  # Department-specific labels
  department_labels = {
    security = {
      compliance_scope = "organization"
      security_level   = "high"
    }
    networking = {
      network_tier = "premium"
      connectivity = "hybrid"
    }
    data = {
      data_classification = "confidential"
      retention_policy    = "7-years"
    }
    compute = {
      workload_type = "general"
      scaling_policy = "auto"
    }
    shared-services = {
      service_tier = "enterprise"
      availability = "99.9"
    }
  }
}

# Validation for folder names
resource "null_resource" "folder_name_validation" {
  for_each = merge(
    google_folder.environments,
    google_folder.departments,
    google_folder.teams
  )
  
  triggers = {
    name_length = length(each.value.display_name) <= local.folder_name_validation.max_length ? "valid" : "invalid"
    name_pattern = can(regex(local.folder_name_validation.pattern, each.value.display_name)) ? "valid" : "invalid"
  }
  
  lifecycle {
    precondition {
      condition = length(each.value.display_name) <= local.folder_name_validation.max_length
      error_message = "Folder name '${each.value.display_name}' exceeds maximum length of ${local.folder_name_validation.max_length} characters."
    }
    
    precondition {
      condition = can(regex(local.folder_name_validation.pattern, each.value.display_name))
      error_message = "Folder name '${each.value.display_name}' does not match required pattern: ${local.folder_name_validation.pattern}"
    }
  }
}

# Apply standard labels to environment folders
resource "google_folder" "environments_with_labels" {
  for_each = google_folder.environments
  
  # This is a data source to add labels - actual implementation would use folder labels when available
  lifecycle {
    ignore_changes = [display_name, parent]
  }
}

# Output naming standards for use by other modules
output "naming_standards" {
  description = "Naming standards and patterns for resources"
  value = {
    patterns = local.naming_patterns
    validation = local.folder_name_validation
    labels = {
      standard = local.standard_labels
      environment = local.environment_labels
      department = local.department_labels
    }
  }
}