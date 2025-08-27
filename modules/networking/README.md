# Networking Module

This module provides comprehensive networking capabilities for the GCP Landing Zone, implementing production-ready shared VPC, network security, and hybrid connectivity features.

## Architecture Overview

The networking module implements a hub-and-spoke architecture with the following components:

- **Shared VPC**: Centralized network management with host and service projects
- **Enhanced Subnets**: Comprehensive subnet configuration with flow logs and IAM
- **Private Service Connect**: Secure connectivity to Google APIs and internal services
- **Network Security**: Cloud Armor, Cloud IDS, and comprehensive firewall rules
- **Hybrid Connectivity**: HA VPN and Cloud Interconnect for on-premises integration

## Module Structure

```
networking/
├── shared-vpc/           # Shared VPC implementation
│   ├── main.tf
│   ├── vpc.tf
│   ├── subnets.tf       # Enhanced subnet configuration
│   ├── firewall-rules.tf # Comprehensive firewall rules
│   ├── cloud-nat.tf
│   ├── private-service-connect.tf # PSC implementation
│   ├── variables.tf
│   └── outputs.tf
├── security/            # Network security components
│   ├── main.tf
│   ├── cloud-armor.tf   # DDoS and WAF protection
│   ├── cloud-ids.tf     # Intrusion detection
│   ├── flow-logs.tf     # VPC flow logs analysis
│   ├── firewall-policies.tf
│   ├── packet-mirroring.tf
│   ├── variables.tf
│   └── outputs.tf
├── hybrid-connectivity/ # On-premises connectivity
│   ├── main.tf
│   ├── cloud-router.tf
│   ├── vpn.tf          # HA VPN implementation
│   ├── interconnect.tf # Cloud Interconnect
│   ├── variables.tf
│   ├── outputs.tf
│   └── scripts/
│       └── vpn-connectivity-test.sh
└── README.md
```

## Features Implemented

### ✅ Task 4.1: Complete Shared VPC Implementation

#### 4.1.1 Enhanced Subnet Configuration
- **Comprehensive subnet planning** with environment and workload classification
- **Private Google Access** configuration per subnet
- **Flow logs per subnet** with configurable sampling and metadata
- **Subnet IAM policies** for granular access control
- **Subnet allocation documentation** with automated tracking
- **Purpose-specific subnets** (general, PSC, GKE, etc.)

#### 4.1.2 Complete Firewall Rules
- **Hierarchical firewall policies** with organization-level controls
- **Security group abstractions** (web-tier, app-tier, db-tier)
- **Comprehensive logging** with metadata inclusion
- **Firewall insights** for rule optimization
- **Default deny-all** with explicit allow rules
- **IAP integration** for secure SSH/RDP access

#### 4.1.3 Private Service Connect
- **Google APIs endpoints** with DNS integration
- **Internal service publishing** with consumer controls
- **PSC consumer endpoints** for service consumption
- **DNS zones and records** for PSC endpoints
- **Connection monitoring** and alerting
- **Cost optimization** with targeted filtering

### ✅ Task 4.2: Network Security Implementation

#### 4.2.1 Cloud Armor Policies
- **DDoS protection** with adaptive protection
- **WAF rules** implementing OWASP Top 10 protection
- **Rate limiting** with multiple threshold configurations
- **Geographic restrictions** with country-based blocking
- **Custom security rules** with expression-based matching
- **Edge security policies** for CDN protection

#### 4.2.2 Cloud IDS Configuration
- **Multiple IDS endpoints** for strategic subnet monitoring
- **Threat detection rules** with custom signatures
- **Alert integration** with Security Command Center
- **Packet mirroring policies** with traffic filtering
- **Performance monitoring** and health checks
- **Automated alert processing** with Cloud Functions

#### 4.2.3 VPC Flow Logs Analysis
- **BigQuery export** with cost optimization filters
- **Anomaly detection** with scheduled queries
- **Network insight dashboards** with traffic visualization
- **Security event analysis** with automated alerting
- **Bandwidth analysis** with trend monitoring
- **Long-term archival** with lifecycle policies

### ✅ Task 4.3: Hybrid Connectivity Completion

#### 4.3.1 HA VPN Implementation
- **Complete VPN gateway configuration** with redundancy
- **BGP session configuration** with advanced routing
- **Route-based VPN** with policy-based routing
- **VPN monitoring** with comprehensive dashboards
- **Automated failover procedures** with Cloud Functions
- **Connection testing** with automated validation

#### 4.3.2 Interconnect Configuration (Structure Ready)
- **VLAN attachments** configuration structure
- **BGP for Interconnect** with traffic engineering
- **Redundant connections** planning
- **Monitoring and alerting** framework

## Usage Examples

### Basic Shared VPC Setup

```hcl
module "shared_vpc" {
  source = "./modules/networking/shared-vpc"
  
  host_project_id     = "my-host-project"
  service_project_ids = ["service-project-1", "service-project-2"]
  network_name        = "shared-vpc"
  
  subnets = [
    {
      name                     = "web-subnet"
      ip_cidr_range           = "10.0.1.0/24"
      region                  = "us-central1"
      description             = "Web tier subnet"
      private_ip_google_access = true
      environment             = "prod"
      workload_type           = "web"
      subnet_users            = ["group:web-developers@company.com"]
      
      secondary_ip_ranges = [
        {
          range_name    = "pods"
          ip_cidr_range = "10.1.0.0/16"
        },
        {
          range_name    = "services"
          ip_cidr_range = "10.2.0.0/16"
        }
      ]
    }
  ]
  
  enable_private_service_connect = true
  enable_security_groups         = true
}
```

### Network Security Configuration

```hcl
module "network_security" {
  source = "./modules/networking/security"
  
  project_id   = var.project_id
  network_name = module.shared_vpc.network_name
  
  enable_cloud_armor = true
  cloud_armor_policies = [
    {
      name        = "web-security-policy"
      description = "Security policy for web applications"
      
      trusted_ip_ranges    = ["203.0.113.0/24"]
      rate_limit_requests  = 100
      rate_limit_interval  = 60
      
      geo_restrictions = [
        {
          action       = "deny(403)"
          priority     = 500
          country_code = "CN"
        }
      ]
      
      rules = [
        {
          action      = "allow"
          priority    = 1000
          description = "Allow trusted sources"
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
  
  enable_cloud_ids = true
  ids_endpoints = {
    "main" = {
      name              = "main-ids-endpoint"
      zone              = "us-central1-a"
      region            = "us-central1"
      description       = "Main IDS endpoint"
      severity          = "MEDIUM"
      threat_exceptions = []
      monitored_subnets = ["web-subnet", "app-subnet"]
      
      filter = {
        ip_protocols = ["tcp", "udp"]
        direction    = "BOTH"
      }
    }
  }
  
  enable_vpc_flow_logs = true
  create_flow_analysis_views = true
  enable_anomaly_detection   = true
}
```

### HA VPN Configuration

```hcl
module "hybrid_connectivity" {
  source = "./modules/networking/hybrid-connectivity"
  
  project_id   = var.project_id
  network_name = module.shared_vpc.network_name
  region       = "us-central1"
  
  enable_vpn = true
  
  vpn_gateways = {
    "onprem" = {
      redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
      description     = "On-premises VPN gateway"
      interfaces = [
        {
          id         = 0
          ip_address = "203.0.113.12"
        }
      ]
    }
  }
  
  vpn_tunnels = {
    "tunnel1" = {
      gateway_key                     = "onprem"
      shared_secret                   = var.vpn_shared_secret
      vpn_gateway_interface          = 0
      peer_external_gateway_interface = 0
      ike_version                    = 2
      interface_ip_range             = "169.254.1.1/30"
      peer_ip_address                = "169.254.1.2"
      peer_asn                       = 65001
      advertised_route_priority      = 100
      advertise_mode                 = "CUSTOM"
      advertised_groups              = ["ALL_SUBNETS"]
      local_traffic_selector         = ["0.0.0.0/0"]
      remote_traffic_selector        = ["0.0.0.0/0"]
    },
    "tunnel2" = {
      gateway_key                     = "onprem"
      shared_secret                   = var.vpn_shared_secret
      vpn_gateway_interface          = 1
      peer_external_gateway_interface = 0
      ike_version                    = 2
      interface_ip_range             = "169.254.2.1/30"
      peer_ip_address                = "169.254.2.2"
      peer_asn                       = 65001
      advertised_route_priority      = 110
      advertise_mode                 = "CUSTOM"
      advertised_groups              = ["ALL_SUBNETS"]
      local_traffic_selector         = ["0.0.0.0/0"]
      remote_traffic_selector        = ["0.0.0.0/0"]
    }
  }
  
  enable_vpn_monitoring = true
  enable_connection_testing = true
}
```

## Security Features

### Network Segmentation
- **Zero-trust architecture** with default deny-all rules
- **Micro-segmentation** with security group abstractions
- **Least privilege access** with subnet-level IAM

### Threat Protection
- **DDoS mitigation** with Cloud Armor adaptive protection
- **Intrusion detection** with Cloud IDS multi-endpoint monitoring
- **WAF protection** with OWASP Top 10 coverage

### Monitoring and Alerting
- **Real-time threat detection** with automated response
- **Network traffic analysis** with anomaly detection
- **Comprehensive dashboards** with security metrics

## Cost Optimization

### Flow Logs Optimization
- **Intelligent filtering** to reduce ingestion costs
- **Sampling configuration** for cost-effective monitoring
- **Lifecycle policies** for long-term storage

### Resource Efficiency
- **Shared VPC model** for centralized management
- **Right-sized NAT gateways** with regional deployment
- **Optimized firewall rules** with priority-based processing

## Compliance and Governance

### Audit and Compliance
- **Comprehensive logging** with metadata inclusion
- **Audit trail** for all network changes
- **Compliance reporting** with automated analysis

### Policy Enforcement
- **Organization policies** for network controls
- **Hierarchical firewall policies** for consistent security
- **Automated policy validation** with testing framework

## Monitoring and Operations

### Health Monitoring
- **VPN tunnel health** with automated failover
- **IDS endpoint monitoring** with performance metrics
- **PSC connection tracking** with availability alerts

### Operational Dashboards
- **Network overview** with traffic visualization
- **Security events** with threat intelligence
- **Performance metrics** with SLA tracking

## Troubleshooting

### Common Issues

1. **VPN Connectivity Issues**
   - Check BGP session status
   - Verify firewall rules
   - Review route advertisements
   - Use connectivity test script

2. **PSC Connection Problems**
   - Validate DNS resolution
   - Check service attachment configuration
   - Verify consumer endpoint setup

3. **Flow Logs Missing**
   - Confirm subnet configuration
   - Check BigQuery permissions
   - Verify log sink configuration

### Debugging Tools

- **VPN connectivity test script** for automated validation
- **Flow logs analysis queries** for traffic investigation
- **IDS alert processing** for threat analysis

## Best Practices

### Network Design
- Use /24 subnets for most workloads
- Reserve /16 ranges for GKE secondary ranges
- Plan IP space for future growth

### Security Configuration
- Enable all security features in production
- Use custom Cloud Armor rules for application-specific threats
- Configure IDS in strategic network locations

### Monitoring Setup
- Enable comprehensive logging with cost optimization
- Set up alerting for critical network events
- Use dashboards for operational visibility

## Migration and Upgrades

### From Basic to Enhanced
1. Update subnet configurations with new variables
2. Enable security features incrementally
3. Test connectivity after each change
4. Update monitoring and alerting

### Version Compatibility
- Terraform >= 1.5
- Google Provider >= 4.84.0
- Compatible with existing shared VPC setups

---

**Last Updated**: 2025-01-28
**Module Version**: 2.0.0
**Terraform Compatibility**: >= 1.5