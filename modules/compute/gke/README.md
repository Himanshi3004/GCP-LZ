# GKE Platform Module

Implements Kubernetes platform setup with GKE clusters supporting both Autopilot and Standard modes, multi-region deployment, Workload Identity, Binary Authorization, Pod Security Standards, and GKE backup.

## Features

- **GKE Clusters**: Autopilot and Standard mode support
- **Multi-region**: Regional cluster deployment
- **Workload Identity**: Secure pod-to-GCP service authentication
- **Binary Authorization**: Container image security verification
- **Pod Security**: Network policies and security standards
- **GKE Backup**: Automated cluster and workload backup

## Usage

```hcl
module "gke" {
  source = "./modules/compute/gke"
  
  project_id    = var.project_id
  region        = var.region
  network       = var.network_name
  subnetwork    = var.subnet_name
  cluster_name  = "main-cluster"
  
  enable_autopilot           = true
  enable_workload_identity   = true
  enable_binary_authorization = true
  
  node_count   = 3
  machine_type = "e2-standard-4"
  
  labels = {
    environment = "prod"
    team        = "platform"
  }
}
```

## Requirements

- Container API enabled
- Compute API enabled
- Binary Authorization API enabled
- VPC network with secondary ranges for pods and services

## Outputs

- `cluster_name`: GKE cluster name
- `cluster_endpoint`: Cluster endpoint (sensitive)
- `cluster_ca_certificate`: CA certificate (sensitive)
- `service_account_email`: GKE service account email
- `workload_identity_sa_email`: Workload Identity service account email
- `backup_plan_name`: GKE backup plan name