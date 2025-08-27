# Hybrid Connectivity Module

This module provides hybrid connectivity options for connecting GCP VPC networks to on-premises infrastructure using Cloud VPN and Cloud Interconnect.

## Features

- **HA VPN**: High-availability VPN tunnels for secure connectivity
- **Cloud Interconnect**: Dedicated or Partner Interconnect support
- **BGP Routing**: Dynamic routing with BGP sessions
- **Redundancy**: Multiple tunnels and paths for high availability
- **Custom Routes**: Configurable route advertisement

## Usage

### VPN Configuration

```hcl
module "hybrid_connectivity" {
  source = "./modules/networking/hybrid-connectivity"
  
  project_id   = "my-project"
  network_name = "shared-vpc"
  region       = "us-central1"
  
  enable_vpn = true
  vpn_config = {
    peer_ip                   = "203.0.113.1"
    shared_secret            = "my-shared-secret"
    peer_asn                 = 65001
    cloud_asn                = 64512
    advertised_route_priority = 100
    ike_version              = 2
  }
  
  custom_routes = [
    {
      dest_range    = "10.0.0.0/8"
      priority      = 100
      next_hop_type = "VPN_TUNNEL"
      description   = "On-premises network"
    }
  ]
}
```

### Interconnect Configuration

```hcl
module "hybrid_connectivity" {
  source = "./modules/networking/hybrid-connectivity"
  
  project_id   = "my-project"
  network_name = "shared-vpc"
  region       = "us-central1"
  
  enable_interconnect = true
  interconnect_config = {
    interconnect_name    = "my-interconnect"
    type                = "DEDICATED"
    link_type           = "LINK_TYPE_ETHERNET_10G_LR"
    location            = "las-zone1-770"
    requested_link_count = 1
  }
  
  bgp_sessions = [
    {
      name                      = "primary-session"
      peer_ip_address          = "169.254.100.2"
      peer_asn                 = 65000
      advertised_route_priority = 100
      interface_name           = "interconnect-interface"
    }
  ]
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
| region | The region for the hybrid connectivity resources | `string` | `"us-central1"` | no |
| enable_interconnect | Enable Cloud Interconnect | `bool` | `false` | no |
| interconnect_config | Configuration for Cloud Interconnect | `object` | `null` | no |
| enable_vpn | Enable Cloud VPN | `bool` | `true` | no |
| vpn_config | Configuration for Cloud VPN | `object` | `null` | no |
| bgp_sessions | BGP session configurations | `list(object)` | `[]` | no |
| custom_routes | Custom routes to advertise | `list(object)` | `[]` | no |
| labels | Labels to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| router_id | The ID of the Cloud Router |
| router_name | The name of the Cloud Router |
| vpn_gateway_id | The ID of the HA VPN Gateway |
| vpn_tunnels | VPN tunnel information |
| interconnect_attachment_id | The ID of the Interconnect Attachment |
| bgp_sessions | BGP session information |

## Architecture

### VPN Architecture
- HA VPN Gateway with two interfaces for redundancy
- Two VPN tunnels for high availability
- BGP sessions for dynamic routing
- Automatic failover between tunnels

### Interconnect Architecture
- Dedicated or Partner Interconnect support
- VLAN attachment for network isolation
- BGP peering for route exchange
- Multiple attachment support for redundancy

## Security Considerations

1. **Shared Secrets**: Store VPN shared secrets securely
2. **BGP Authentication**: Consider BGP MD5 authentication
3. **Route Filtering**: Implement route filtering policies
4. **Monitoring**: Monitor tunnel status and BGP sessions
5. **Encryption**: VPN tunnels provide encryption in transit

## Best Practices

1. **Redundancy**: Always configure multiple tunnels/attachments
2. **Route Priorities**: Set appropriate route priorities for failover
3. **Monitoring**: Monitor tunnel health and BGP session status
4. **Documentation**: Document IP addressing and routing policies
5. **Testing**: Regularly test failover scenarios

## Troubleshooting

Common issues and solutions:

1. **Tunnel Down**: Check shared secret and peer configuration
2. **BGP Not Established**: Verify ASN numbers and IP addressing
3. **Route Not Advertised**: Check BGP configuration and filters
4. **Connectivity Issues**: Verify firewall rules and routing

## Examples

See the `examples/` directory for complete usage examples.