# Organization policies for security and compliance

# Organization-level policies (apply to all folders)
# Restrict VM external IP addresses
resource "google_org_policy_policy" "restrict_vm_external_ips" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/compute.vmExternalIpAccess"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      deny_all = "TRUE"
    }
  }
}

# Folder-level policies for environment-specific controls
# Development environment - more relaxed policies
resource "google_org_policy_policy" "dev_vm_external_ips" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "${google_folder.environments["dev"].name}/policies/compute.vmExternalIpAccess"
  parent = google_folder.environments["dev"].name

  spec {
    rules {
      values {
        allowed_values = ["projects/*/zones/*/instances/*"]
      }
    }
  }
}

# Production environment - strict compute instance locations
resource "google_org_policy_policy" "prod_compute_locations" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "${google_folder.environments["prod"].name}/policies/gcp.resourceLocations"
  parent = google_folder.environments["prod"].name

  spec {
    rules {
      values {
        allowed_values = var.prod_allowed_regions
      }
    }
  }
}

# Security folder - additional restrictions
resource "google_org_policy_policy" "security_folder_restrictions" {
  for_each = var.enable_organization_policies ? {
    for k, v in google_folder.departments : k => v if endswith(k, "-security")
  } : {}
  
  name   = "${each.value.name}/policies/compute.requireShieldedVm"
  parent = each.value.name

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Data folder - storage restrictions
resource "google_org_policy_policy" "data_folder_storage" {
  for_each = var.enable_organization_policies ? {
    for k, v in google_folder.departments : k => v if endswith(k, "-data")
  } : {}
  
  name   = "${each.value.name}/policies/storage.uniformBucketLevelAccess"
  parent = each.value.name

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Require OS Login
resource "google_org_policy_policy" "require_os_login" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/compute.requireOsLogin"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Restrict shared VPC subnets
resource "google_org_policy_policy" "restrict_shared_vpc_subnets" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/compute.restrictSharedVpcSubnetworks"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      allow_all = "FALSE"
    }
  }
}

# Disable service account key creation
resource "google_org_policy_policy" "disable_sa_key_creation" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/iam.disableServiceAccountKeyCreation"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Restrict resource locations
resource "google_org_policy_policy" "restrict_resource_locations" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/gcp.resourceLocations"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      values {
        allowed_values = var.allowed_regions
      }
    }
  }
}

# Require Shielded VM
resource "google_org_policy_policy" "require_shielded_vm" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/compute.requireShieldedVm"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Uniform bucket level access
resource "google_org_policy_policy" "uniform_bucket_level_access" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/storage.uniformBucketLevelAccess"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Restrict VPN peer IPs
resource "google_org_policy_policy" "restrict_vpn_peer_ips" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/compute.restrictVpnPeerIPs"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      values {
        allowed_values = var.allowed_vpn_peer_ips
      }
    }
  }
}

# Restrict SQL public IP
resource "google_org_policy_policy" "restrict_sql_public_ip" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/sql.restrictPublicIp"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Disable nested virtualization
resource "google_org_policy_policy" "disable_nested_virtualization" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/compute.disableNestedVirtualization"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Additional core organization policies

# Restrict load balancer creation types
resource "google_org_policy_policy" "restrict_load_balancer_creation" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/compute.restrictLoadBalancerCreationForTypes"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      values {
        allowed_values = [
          "INTERNAL",
          "INTERNAL_MANAGED",
          "EXTERNAL_MANAGED"
        ]
      }
    }
  }
}

# Restrict protocol forwarding creation
resource "google_org_policy_policy" "restrict_protocol_forwarding" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/compute.restrictProtocolForwardingCreationForTypes"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      values {
        allowed_values = [
          "INTERNAL"
        ]
      }
    }
  }
}

# Restrict non-confidential computing
resource "google_org_policy_policy" "restrict_non_confidential_computing" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/compute.restrictNonConfidentialComputing"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Storage retention policy
resource "google_org_policy_policy" "storage_retention_policy" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/storage.retentionPolicySeconds"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      values {
        allowed_values = [
          "2592000",  # 30 days minimum
          "7776000",  # 90 days
          "31536000", # 1 year
          "94608000"  # 3 years
        ]
      }
    }
  }
}

# Disable service account key upload
resource "google_org_policy_policy" "disable_sa_key_upload" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/iam.disableServiceAccountKeyUpload"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Restrict service account key types
resource "google_org_policy_policy" "restrict_sa_key_types" {
  count  = var.enable_organization_policies ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/iam.allowedPolicyMemberDomains"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      values {
        allowed_values = [
          var.domain_name
        ]
      }
    }
  }
}