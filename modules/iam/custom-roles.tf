# Custom Role Definitions
# Implements least-privilege custom roles for different functions

# Viewer-plus roles (viewer + specific permissions)
resource "google_organization_iam_custom_role" "viewer_plus_compute" {
  org_id      = var.organization_id
  role_id     = "viewerPlusCompute"
  title       = "Viewer Plus Compute"
  description = "Viewer role with additional compute permissions"
  
  permissions = [
    # Base viewer permissions
    "resourcemanager.projects.get",
    "resourcemanager.projects.list",
    
    # Additional compute permissions
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.start",
    "compute.instances.stop",
    "compute.instances.reset",
    "compute.disks.get",
    "compute.disks.list",
    "compute.snapshots.get",
    "compute.snapshots.list"
  ]
  
  stage = "GA"
}

resource "google_organization_iam_custom_role" "viewer_plus_storage" {
  org_id      = var.organization_id
  role_id     = "viewerPlusStorage"
  title       = "Viewer Plus Storage"
  description = "Viewer role with additional storage permissions"
  
  permissions = [
    # Base viewer permissions
    "resourcemanager.projects.get",
    "resourcemanager.projects.list",
    
    # Additional storage permissions
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.create",
    "storage.objects.update"
  ]
  
  stage = "GA"
}

# Deployment-specific roles
resource "google_organization_iam_custom_role" "deployment_manager" {
  org_id      = var.organization_id
  role_id     = "deploymentManager"
  title       = "Deployment Manager"
  description = "Role for managing deployments across projects"
  
  permissions = [
    # Project management
    "resourcemanager.projects.get",
    "resourcemanager.projects.list",
    "resourcemanager.projects.update",
    
    # Deployment permissions
    "deploymentmanager.deployments.create",
    "deploymentmanager.deployments.delete",
    "deploymentmanager.deployments.get",
    "deploymentmanager.deployments.list",
    "deploymentmanager.deployments.update",
    
    # Service account management
    "iam.serviceAccounts.create",
    "iam.serviceAccounts.delete",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.list",
    "iam.serviceAccounts.update",
    "iam.serviceAccounts.actAs",
    
    # Resource creation
    "compute.instances.create",
    "compute.instances.delete",
    "compute.disks.create",
    "compute.networks.create",
    "storage.buckets.create"
  ]
  
  stage = "GA"
}

resource "google_organization_iam_custom_role" "network_operator" {
  org_id      = var.organization_id
  role_id     = "networkOperator"
  title       = "Network Operator"
  description = "Role for network operations and troubleshooting"
  
  permissions = [
    # Network viewing
    "compute.networks.get",
    "compute.networks.list",
    "compute.subnetworks.get",
    "compute.subnetworks.list",
    "compute.firewalls.get",
    "compute.firewalls.list",
    
    # Network operations
    "compute.firewalls.create",
    "compute.firewalls.update",
    "compute.firewalls.delete",
    "compute.routes.create",
    "compute.routes.delete",
    "compute.routes.get",
    "compute.routes.list",
    
    # VPN operations
    "compute.vpnGateways.get",
    "compute.vpnGateways.list",
    "compute.vpnTunnels.get",
    "compute.vpnTunnels.list",
    
    # Monitoring
    "monitoring.timeSeries.list",
    "logging.logEntries.list"
  ]
  
  stage = "GA"
}

# Break-glass emergency roles
resource "google_organization_iam_custom_role" "emergency_access" {
  org_id      = var.organization_id
  role_id     = "emergencyAccess"
  title       = "Emergency Access"
  description = "Break-glass role for emergency situations"
  
  permissions = [
    # Full project access
    "resourcemanager.projects.get",
    "resourcemanager.projects.list",
    "resourcemanager.projects.update",
    "resourcemanager.projects.setIamPolicy",
    
    # Compute emergency access
    "compute.instances.start",
    "compute.instances.stop",
    "compute.instances.reset",
    "compute.instances.setMetadata",
    "compute.instances.setServiceAccount",
    
    # Network emergency access
    "compute.firewalls.create",
    "compute.firewalls.update",
    "compute.firewalls.delete",
    
    # Storage emergency access
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.create",
    
    # IAM emergency access
    "iam.serviceAccounts.actAs",
    "iam.roles.get",
    "iam.roles.list"
  ]
  
  stage = "GA"
}

# Security-specific roles
resource "google_organization_iam_custom_role" "security_analyst" {
  org_id      = var.organization_id
  role_id     = "securityAnalyst"
  title       = "Security Analyst"
  description = "Role for security analysis and investigation"
  
  permissions = [
    # Security Center
    "securitycenter.findings.list",
    "securitycenter.findings.group",
    "securitycenter.findings.update",
    "securitycenter.assets.list",
    "securitycenter.assets.group",
    
    # Cloud Asset Inventory
    "cloudasset.assets.searchAllResources",
    "cloudasset.assets.searchAllIamPolicies",
    
    # Logging and monitoring
    "logging.logEntries.list",
    "monitoring.timeSeries.list",
    
    # IAM analysis
    "iam.serviceAccounts.list",
    "iam.roles.list",
    "resourcemanager.projects.getIamPolicy"
  ]
  
  stage = "GA"
}

# Data-specific roles
resource "google_organization_iam_custom_role" "data_engineer" {
  org_id      = var.organization_id
  role_id     = "dataEngineer"
  title       = "Data Engineer"
  description = "Role for data engineering tasks"
  
  permissions = [
    # BigQuery
    "bigquery.datasets.create",
    "bigquery.datasets.get",
    "bigquery.datasets.update",
    "bigquery.tables.create",
    "bigquery.tables.get",
    "bigquery.tables.list",
    "bigquery.tables.update",
    "bigquery.jobs.create",
    
    # Dataflow
    "dataflow.jobs.create",
    "dataflow.jobs.get",
    "dataflow.jobs.list",
    "dataflow.jobs.update",
    
    # Pub/Sub
    "pubsub.topics.create",
    "pubsub.topics.get",
    "pubsub.topics.list",
    "pubsub.subscriptions.create",
    "pubsub.subscriptions.get",
    "pubsub.subscriptions.list",
    
    # Storage
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list"
  ]
  
  stage = "GA"
}

# Role versioning tracking
resource "google_storage_bucket_object" "role_versions" {
  for_each = {
    viewer_plus_compute = google_organization_iam_custom_role.viewer_plus_compute
    viewer_plus_storage = google_organization_iam_custom_role.viewer_plus_storage
    deployment_manager  = google_organization_iam_custom_role.deployment_manager
    network_operator    = google_organization_iam_custom_role.network_operator
    emergency_access    = google_organization_iam_custom_role.emergency_access
    security_analyst    = google_organization_iam_custom_role.security_analyst
    data_engineer      = google_organization_iam_custom_role.data_engineer
  }
  
  bucket  = var.role_versions_bucket
  name    = "roles/${each.key}/version-${formatdate("YYYY-MM-DD-hhmm", timestamp())}.json"
  content = jsonencode({
    role_id     = each.value.role_id
    title       = each.value.title
    description = each.value.description
    permissions = each.value.permissions
    stage       = each.value.stage
    created     = timestamp()
  })
}