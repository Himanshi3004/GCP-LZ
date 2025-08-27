# Shared VPC Module

This module creates a Shared VPC network with hub-and-spoke topology for centralized networking in GCP.

## Features

- **Shared VPC Host Project**: Centralized network management
- **Service Project Attachment**: Automatic attachment of service projects
- **Subnet Management**: Configurable subnets with secondary IP ranges for GKE
- **Firewall Rules**: Default security rules with custom rule support
- **Cloud NAT**: Outbound internet connectivity for private instances
- **Private Service Connect**: Secure access to Google APIs
- **VPC Flow Logs**: Network monitoring and troubleshooting

## Usage

```hcl
module "shared_vpc" {
  source = "./modules/networking/shared-vpc"
  
  host_project_id     = "my-host-project"
  service_project_ids = ["service-project-1", "service-project-2"]
  network_name        = "shared-vpc"
  
  subnets = [
    {
      name                     = "subnet-us-central1"
      ip_cidr_range           = "10.0.0.0/24"
      region                  = "us-central1"
      description             = "Main subnet for us-central1"
      private_ip_google_access = true
      secondary_ip_ranges = [
        {
          range_name    = "gke-pods"
          ip_cidr_range = "10.1.0.0/16"
        },
        {
          range_name    = "gke-services"
          ip_cidr_range = "10.2.0.0/20"
        }
      ]
    }
  ]
  
  firewall_rules = [
    {
      name        = "allow-web-traffic"
      description = "Allow HTTP and HTTPS traffic"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["0.0.0.0/0"]
      target_tags = ["web-server"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["80", "443"]
        }
      ]
    }
  ]
  
  enable_cloud_nat = true
  nat_regions      = ["us-central1", "us-east1"]
  
  enable_private_service_connect = true
  
  labels = {
    environment = "production"
    team        = "platform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| google | >= 4.84.0 |

## Providers

| Name | Version |
|------|---------|
| google | >= 4.84.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| host_project_id | The project ID of the shared VPC host project | `string` | n/a | yes |
| service_project_ids | List of service project IDs to attach to the shared VPC | `list(string)` | `[]` | no |
| network_name | Name of the VPC network | `string` | `"shared-vpc"` | no |
| subnets | List of subnets to create | `list(object)` | `[]` | no |
| firewall_rules | List of firewall rules to create | `list(object)` | `[]` | no |
| enable_cloud_nat | Enable Cloud NAT for the network | `bool` | `true` | no |
| nat_regions | List of regions where Cloud NAT should be created | `list(string)` | `["us-central1"]` | no |
| enable_private_service_connect | Enable Private Service Connect | `bool` | `true` | no |
| labels | Labels to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| network_id | The ID of the VPC network |
| network_name | The name of the VPC network |
| network_self_link | The self link of the VPC network |
| subnets | Map of subnet names to subnet details |
| subnet_ids | List of subnet IDs |
| subnet_self_links | List of subnet self links |
| router_ids | Map of region to router ID |
| nat_ips | Map of region to NAT IP addresses |
| private_service_connect_ip | Private Service Connect IP address |

## Security Features

- **Default Deny**: All ingress traffic is denied by default
- **Internal Communication**: Allows communication within VPC subnets
- **IAP Access**: SSH and RDP access through Identity-Aware Proxy
- **VPC Flow Logs**: Enabled on all subnets for monitoring
- **Private Google Access**: Enabled by default on subnets
- **Private Service Connect**: Secure access to Google APIs

## Best Practices

1. **CIDR Planning**: Plan IP ranges carefully to avoid conflicts
2. **Secondary Ranges**: Use secondary IP ranges for GKE clusters
3. **Firewall Rules**: Follow least privilege principle
4. **Network Tags**: Use consistent tagging strategy
5. **Monitoring**: Enable VPC Flow Logs for troubleshooting
6. **Private Access**: Use Private Google Access for security

## Examples

See the `examples/` directory for complete usage examples.