package terraform.security

# Deny resources without proper labels
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "google_compute_instance"
    not resource.change.after.labels.environment
    msg := sprintf("Compute instance %s must have environment label", [resource.address])
}

# Require encryption for storage buckets
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "google_storage_bucket"
    not resource.change.after.encryption
    msg := sprintf("Storage bucket %s must have encryption enabled", [resource.address])
}

# Deny public IP addresses in production
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "google_compute_instance"
    resource.change.after.labels.environment == "prod"
    resource.change.after.network_interface[_].access_config
    msg := sprintf("Production instance %s cannot have public IP", [resource.address])
}

# Require VPC firewall rules to be restrictive
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "google_compute_firewall"
    resource.change.after.source_ranges[_] == "0.0.0.0/0"
    resource.change.after.direction == "INGRESS"
    msg := sprintf("Firewall rule %s cannot allow traffic from 0.0.0.0/0", [resource.address])
}

# Require Cloud SQL instances to have backup enabled
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "google_sql_database_instance"
    not resource.change.after.settings[0].backup_configuration[0].enabled
    msg := sprintf("Cloud SQL instance %s must have backup enabled", [resource.address])
}