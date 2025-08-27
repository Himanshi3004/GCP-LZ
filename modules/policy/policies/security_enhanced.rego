package terraform.security.enhanced

import rego.v1

# Enhanced security policies for GCP Landing Zone

# Deny resources without proper security labels
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type in ["google_compute_instance", "google_storage_bucket", "google_sql_database_instance"]
    not resource.change.after.labels.security_classification
    msg := sprintf("Resource %s must have security_classification label", [resource.address])
}

# Require encryption at rest for all storage resources
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_storage_bucket"
    not resource.change.after.encryption[0].default_kms_key_name
    msg := sprintf("Storage bucket %s must use customer-managed encryption keys", [resource.address])
}

# Deny unencrypted Cloud SQL instances
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_sql_database_instance"
    not resource.change.after.encryption_key_name
    msg := sprintf("Cloud SQL instance %s must use customer-managed encryption", [resource.address])
}

# Require private clusters for GKE
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_container_cluster"
    not resource.change.after.private_cluster_config[0].enable_private_nodes
    msg := sprintf("GKE cluster %s must be private", [resource.address])
}

# Deny GKE clusters without network policy
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_container_cluster"
    not resource.change.after.network_policy[0].enabled
    msg := sprintf("GKE cluster %s must have network policy enabled", [resource.address])
}

# Require Binary Authorization for GKE
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_container_cluster"
    not resource.change.after.binary_authorization[0].enabled
    msg := sprintf("GKE cluster %s must have Binary Authorization enabled", [resource.address])
}

# Deny compute instances without OS Login
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_compute_instance"
    not resource.change.after.metadata["enable-oslogin"] == "TRUE"
    msg := sprintf("Compute instance %s must have OS Login enabled", [resource.address])
}

# Require Shielded VM for compute instances
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_compute_instance"
    not resource.change.after.shielded_instance_config[0].enable_secure_boot
    msg := sprintf("Compute instance %s must have Shielded VM enabled", [resource.address])
}

# Deny Cloud Functions without VPC connector in production
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_cloudfunctions_function"
    resource.change.after.labels.environment == "prod"
    not resource.change.after.vpc_connector
    msg := sprintf("Production Cloud Function %s must use VPC connector", [resource.address])
}

# Require IAM conditions for sensitive roles
sensitive_roles := [
    "roles/owner",
    "roles/editor",
    "roles/iam.securityAdmin",
    "roles/resourcemanager.organizationAdmin"
]

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_project_iam_member"
    resource.change.after.role in sensitive_roles
    not resource.change.after.condition
    msg := sprintf("IAM binding %s for sensitive role must have conditions", [resource.address])
}

# Deny service accounts with overly broad permissions
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_project_iam_member"
    startswith(resource.change.after.member, "serviceAccount:")
    resource.change.after.role in ["roles/owner", "roles/editor"]
    msg := sprintf("Service account %s should not have broad permissions", [resource.address])
}

# Require audit logging for critical resources
critical_services := [
    "cloudsql.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com"
]

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_project_service"
    resource.change.after.service in critical_services
    not has_audit_config(resource.change.after.project)
    msg := sprintf("Project %s must have audit logging enabled for critical services", [resource.change.after.project])
}

# Helper function to check audit configuration
has_audit_config(project_id) if {
    audit_resource := input.resource_changes[_]
    audit_resource.type == "google_project_iam_audit_config"
    audit_resource.change.after.project == project_id
}