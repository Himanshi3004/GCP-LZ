# Network Security Module

This module implements comprehensive network-level security controls for GCP VPC networks including Cloud Armor, Cloud IDS, hierarchical firewall policies, VPC Flow Logs, and packet mirroring.

## Features

- **Cloud Armor**: Web Application Firewall (WAF) with OWASP protection
- **Cloud IDS**: Intrusion Detection System for network monitoring
- **Hierarchical Firewall Policies**: Organization-level firewall management
- **VPC Flow Logs**: Network traffic monitoring and analysis
- **Packet Mirroring**: Traffic inspection and analysis
- **Private Google Access**: Secure access to Google APIs

## Usage

### Basic Configuration

```hcl
module "network_security" {
  source = "./modules/networking/security"
  
  project_id   = "my-project"
  network_name = "shared-vpc"
  region       = "us-central1"
  
  enable_cloud_armor = true
  cloud_armor_policies = [
    {
      name        = "web-app-policy"
      description = "Security policy for web applications"
      rules = [
        {
          action      = "allow"
          priority    = 1000
          description = "Allow trusted IPs"
          match = {
            versioned_expr = "SRC_IPS_V1"
            config = {
              src_ip_ranges = ["203.0.113.0/24"]
            }
          }
        }
      ]
    }
  ]
  
  enable_vpc_flow_logs = true
  enable_private_google_access = true
}
```

### Advanced Configuration with IDS

```hcl
module "network_security" {
  source = "./modules/networking/security"
  
  project_id   = "my-project"
  network_name = "shared-vpc"
  region       = "us-central1"
  
  enable_cloud_ids = true
  ids_config = {
    name        = "network-ids"
    description = "Network intrusion detection"
    network     = "shared-vpc"
    zone        = "us-central1-a"
    severity    = "MEDIUM"
    threat_exceptions = ["threat-id-1", "threat-id-2"]
  }
  
  enable_hierarchical_firewall = true
  firewall_policies = [
    {
      name        = "org-security-policy"
      description = "Organization-wide security policy"
      parent      = "organizations/123456789"
      rules = [
        {
          description = "Deny all external SSH"
          direction   = "INGRESS"
          action      = "deny"
          priority    = 1000
          match = {
            layer4_configs = [
              {
                ip_protocol = "tcp"
                ports       = ["22"]
              }
            ]
            src_ip_ranges = ["0.0.0.0/0"]
            dest_ip_ranges = []
          }
        }
      ]
    }
  ]
  
  enable_packet_mirroring = true
  packet_mirroring_config = {
    name        = "security-mirroring"
    description = "Packet mirroring for security analysis"
    collector_ilb = "projects/my-project/regions/us-central1/forwardingRules/collector"
    mirrored_resources = {
      subnetworks = ["web-subnet", "app-subnet"]
      instances   = []
      tags        = ["web-server", "app-server"]
    }
    filter = {
      ip_protocols = ["tcp", "udp"]
      cidr_ranges  = ["10.0.0.0/8"]
      direction    = "BOTH"
    }
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
| project_id | The project ID where resources will be created | `string` | n/a | yes |
| network_name | Name of the VPC network | `string` | n/a | yes |
| region | The region for security resources | `string` | `"us-central1"` | no |
| enable_cloud_armor | Enable Cloud Armor security policies | `bool` | `true` | no |
| cloud_armor_policies | Cloud Armor security policies configuration | `list(object)` | `[]` | no |
| enable_cloud_ids | Enable Cloud IDS | `bool` | `false` | no |
| ids_config | Cloud IDS configuration | `object` | `null` | no |
| enable_hierarchical_firewall | Enable hierarchical firewall policies | `bool` | `true` | no |
| firewall_policies | Hierarchical firewall policies | `list(object)` | `[]` | no |
| enable_vpc_flow_logs | Enable VPC Flow Logs | `bool` | `true` | no |
| flow_logs_config | VPC Flow Logs configuration | `object` | `{...}` | no |
| enable_packet_mirroring | Enable packet mirroring | `bool` | `false` | no |
| packet_mirroring_config | Packet mirroring configuration | `object` | `null` | no |
| enable_private_google_access | Enable Private Google Access | `bool` | `true` | no |
| labels | Labels to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloud_armor_policies | Cloud Armor security policies |
| cloud_ids_endpoint | Cloud IDS endpoint information |
| firewall_policies | Hierarchical firewall policies |
| vpc_flow_logs_dataset | BigQuery dataset for VPC Flow Logs |
| packet_mirroring_policy | Packet mirroring policy information |

## Security Features

### Cloud Armor
- DDoS protection
- OWASP Top 10 protection
- Rate limiting
- Geo-based blocking
- Custom security rules

### Cloud IDS
- Network-based intrusion detection
- Threat intelligence integration
- Custom threat exceptions
- Real-time monitoring

### Hierarchical Firewall Policies
- Organization-level policy management
- Inheritance and override capabilities
- Centralized rule management
- Policy associations

### VPC Flow Logs
- Network traffic analysis
- Security monitoring
- Troubleshooting support
- BigQuery integration

### Packet Mirroring
- Traffic inspection
- Security analysis
- Compliance monitoring
- Custom filtering

## Best Practices

1. **Defense in Depth**: Implement multiple security layers
2. **Least Privilege**: Configure minimal required access
3. **Monitoring**: Enable comprehensive logging and monitoring
4. **Regular Updates**: Keep security policies updated
5. **Testing**: Regularly test security controls
6. **Documentation**: Document security configurations

## Compliance

This module supports compliance with:
- SOC 2
- ISO 27001
- PCI DSS
- GDPR
- HIPAA

## Troubleshooting

Common issues and solutions:

1. **Cloud Armor Rules**: Check rule priorities and syntax
2. **IDS Alerts**: Review threat exceptions and severity settings
3. **Flow Logs**: Verify BigQuery permissions and dataset configuration
4. **Packet Mirroring**: Check collector configuration and network connectivity

## Examples

See the `examples/` directory for complete usage examples.