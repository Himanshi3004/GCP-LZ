package terraform.compliance

# CIS GCP Benchmark compliance rules

# CIS 1.1 - Ensure that corporate login credentials are used
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "google_project_iam_member"
    startswith(resource.change.after.member, "user:")
    not endswith(resource.change.after.member, "@netskope.com")
    msg := sprintf("IAM member %s must use corporate domain", [resource.address])
}

# CIS 1.4 - Ensure that there are only GCP-managed service account keys
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "google_service_account_key"
    msg := sprintf("Service account key %s should not be created manually", [resource.address])
}

# CIS 2.2 - Ensure that Cloud SQL database instances do not have public IPs
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "google_sql_database_instance"
    resource.change.after.settings[0].ip_configuration[0].ipv4_enabled == true
    msg := sprintf("Cloud SQL instance %s should not have public IP", [resource.address])
}

# CIS 3.1 - Ensure that the default network does not exist in a project
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "google_compute_network"
    resource.change.after.name == "default"
    msg := sprintf("Default network %s should be deleted", [resource.address])
}

# CIS 3.6 - Ensure that SSH access is restricted from the internet
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "google_compute_firewall"
    resource.change.after.allow[_].ports[_] == "22"
    resource.change.after.source_ranges[_] == "0.0.0.0/0"
    msg := sprintf("Firewall rule %s allows SSH from internet", [resource.address])
}

# CIS 4.1 - Ensure that instances are not configured to use the default service account
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "google_compute_instance"
    endswith(resource.change.after.service_account[0].email, "-compute@developer.gserviceaccount.com")
    msg := sprintf("Instance %s should not use default service account", [resource.address])
}

# CIS 4.2 - Ensure that instances are not configured to use the default service account with full access to all Cloud APIs
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "google_compute_instance"
    resource.change.after.service_account[0].scopes[_] == "https://www.googleapis.com/auth/cloud-platform"
    msg := sprintf("Instance %s should not have full API access", [resource.address])
}