package terraform.cost.governance

import rego.v1

# Cost governance policies for GCP Landing Zone

# Deny expensive machine types in non-production environments
expensive_machine_types := [
    "n1-highmem-96",
    "n1-highcpu-96",
    "n2-highmem-80",
    "n2-highcpu-80",
    "c2-standard-60"
]

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_compute_instance"
    resource.change.after.machine_type in expensive_machine_types
    resource.change.after.labels.environment != "prod"
    msg := sprintf("Instance %s uses expensive machine type %s in non-production", [resource.address, resource.change.after.machine_type])
}

# Require budget alerts for all projects
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_project"
    not has_budget_alert(resource.change.after.project_id)
    msg := sprintf("Project %s must have budget alerts configured", [resource.change.after.project_id])
}

# Deny persistent disks without lifecycle management
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_compute_disk"
    resource.change.after.size > 100
    not resource.change.after.labels.lifecycle_policy
    msg := sprintf("Large disk %s must have lifecycle policy label", [resource.address])
}

# Require committed use discounts for production workloads
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_compute_instance"
    resource.change.after.labels.environment == "prod"
    not has_commitment(resource.change.after.zone)
    msg := sprintf("Production instance %s should use committed use discounts", [resource.address])
}

# Deny oversized Cloud SQL instances in development
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_sql_database_instance"
    resource.change.after.labels.environment == "dev"
    resource.change.after.settings[0].tier in ["db-n1-highmem-64", "db-n1-standard-64"]
    msg := sprintf("Development SQL instance %s is oversized", [resource.address])
}

# Require cost center labels for billing allocation
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type in billable_resources
    not resource.change.after.labels.cost_center
    msg := sprintf("Billable resource %s must have cost_center label", [resource.address])
}

billable_resources := [
    "google_compute_instance",
    "google_storage_bucket",
    "google_sql_database_instance",
    "google_container_cluster",
    "google_cloudfunctions_function"
]

# Helper functions
has_budget_alert(project_id) if {
    budget_resource := input.resource_changes[_]
    budget_resource.type == "google_billing_budget"
    contains(budget_resource.change.after.billing_account, project_id)
}

has_commitment(zone) if {
    commitment_resource := input.resource_changes[_]
    commitment_resource.type == "google_compute_region_commitment"
    commitment_resource.change.after.region == zone
}