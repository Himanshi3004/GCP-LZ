# GCP Landing Zone - Network Topology Diagram

## Network Architecture Overview

```mermaid
graph TB
    subgraph "On-Premises Network"
        ONPREM[On-Premises<br/>192.168.0.0/16]
        ONPREM_ROUTER[Corporate Router]
    end
    
    subgraph "GCP Organization - Shared VPC Architecture"
        subgraph "Host Project: netskope-network-{env}"
            VPC_HOST[Shared VPC Host<br/>netskope-{env}-shared-vpc]
            
            subgraph "us-central1 Region"
                SUBNET_MAIN[Main Subnet<br/>10.0.0.0/24<br/>us-central1]
                
                subgraph "Secondary IP Ranges"
                    GKE_PODS_RANGE[GKE Pods<br/>10.1.0.0/16<br/>gke-pods]
                    GKE_SVC_RANGE[GKE Services<br/>10.2.0.0/20<br/>gke-services]
                end
            end
            
            subgraph "us-east1 Region (DR)"
                SUBNET_DR[DR Subnet<br/>10.10.0.0/24<br/>us-east1]
            end
            
            subgraph "Network Services"
                CLOUD_ROUTER[Cloud Router<br/>ASN: 65001]
                CLOUD_NAT[Cloud NAT<br/>External IP Pool]
                VPN_GATEWAY[VPN Gateway<br/>35.x.x.x]
                INTERCONNECT_ATTACH[Interconnect Attachment<br/>Dedicated/Partner]
            end
            
            subgraph "Security Controls"
                FIREWALL_POLICIES[Hierarchical Firewall Policies]
                CLOUD_ARMOR_POLICY[Cloud Armor Policies]
                VPC_SC_PERIMETER[VPC Service Controls Perimeter]
            end
        end
        
        subgraph "Service Projects"
            subgraph "Development Environment"
                DEV_PROJ1[netskope-app-dev-001]
                DEV_PROJ2[netskope-data-dev-001]
                DEV_GKE[GKE Cluster<br/>dev-cluster]
            end
            
            subgraph "Staging Environment"
                STG_PROJ1[netskope-app-stg-001]
                STG_PROJ2[netskope-data-stg-001]
                STG_GKE[GKE Cluster<br/>staging-cluster]
            end
            
            subgraph "Production Environment"
                PROD_PROJ1[netskope-app-prd-001]
                PROD_PROJ2[netskope-data-prd-001]
                PROD_GKE[GKE Cluster<br/>prod-cluster]
            end
        end
    end
    
    subgraph "External Connectivity"
        INTERNET[Internet<br/>0.0.0.0/0]
        GOOGLE_APIS[Google APIs<br/>Private Google Access]
        PEERED_NETWORKS[Peered Networks<br/>Partner/Customer VPCs]
    end
    
    %% Connections
    ONPREM_ROUTER -.->|VPN Tunnel<br/>IPSec| VPN_GATEWAY
    ONPREM_ROUTER -.->|Dedicated Interconnect<br/>10Gbps| INTERCONNECT_ATTACH
    
    VPC_HOST --> SUBNET_MAIN
    VPC_HOST --> SUBNET_DR
    SUBNET_MAIN --> GKE_PODS_RANGE
    SUBNET_MAIN --> GKE_SVC_RANGE
    
    CLOUD_ROUTER --> VPN_GATEWAY
    CLOUD_ROUTER --> INTERCONNECT_ATTACH
    SUBNET_MAIN --> CLOUD_NAT
    
    VPC_HOST -.->|Shared VPC Attachment| DEV_PROJ1
    VPC_HOST -.->|Shared VPC Attachment| DEV_PROJ2
    VPC_HOST -.->|Shared VPC Attachment| STG_PROJ1
    VPC_HOST -.->|Shared VPC Attachment| STG_PROJ2
    VPC_HOST -.->|Shared VPC Attachment| PROD_PROJ1
    VPC_HOST -.->|Shared VPC Attachment| PROD_PROJ2
    
    DEV_GKE --> GKE_PODS_RANGE
    STG_GKE --> GKE_PODS_RANGE
    PROD_GKE --> GKE_PODS_RANGE
    
    CLOUD_NAT --> INTERNET
    SUBNET_MAIN -.->|Private Google Access| GOOGLE_APIS
    VPC_HOST -.->|VPC Peering| PEERED_NETWORKS
    
    %% Security Controls
    FIREWALL_POLICIES --> VPC_HOST
    CLOUD_ARMOR_POLICY --> VPC_HOST
    VPC_SC_PERIMETER --> VPC_HOST
    
    %% Styling
    classDef onprem fill:#ffebcd
    classDef vpc fill:#e1f5fe
    classDef subnet fill:#e8f5e8
    classDef service fill:#fff3e0
    classDef security fill:#ffebee
    classDef external fill:#f3e5f5
    
    class ONPREM,ONPREM_ROUTER onprem
    class VPC_HOST,CLOUD_ROUTER,CLOUD_NAT,VPN_GATEWAY,INTERCONNECT_ATTACH vpc
    class SUBNET_MAIN,SUBNET_DR,GKE_PODS_RANGE,GKE_SVC_RANGE subnet
    class DEV_PROJ1,DEV_PROJ2,STG_PROJ1,STG_PROJ2,PROD_PROJ1,PROD_PROJ2,DEV_GKE,STG_GKE,PROD_GKE service
    class FIREWALL_POLICIES,CLOUD_ARMOR_POLICY,VPC_SC_PERIMETER security
    class INTERNET,GOOGLE_APIS,PEERED_NETWORKS external
```

## Detailed IP Address Allocation

```mermaid
graph TB
    subgraph "IP Address Space Planning"
        subgraph "Primary Subnets"
            MAIN_IP[Main Subnet<br/>10.0.0.0/24<br/>254 IPs available]
            DR_IP[DR Subnet<br/>10.10.0.0/24<br/>254 IPs available]
        end
        
        subgraph "GKE Secondary Ranges"
            POD_IP[Pod IP Range<br/>10.1.0.0/16<br/>65,534 IPs<br/>~4,000 nodes max]
            SVC_IP[Service IP Range<br/>10.2.0.0/20<br/>4,094 IPs<br/>~4,000 services max]
        end
        
        subgraph "Reserved Ranges"
            MGMT_IP[Management<br/>10.100.0.0/24]
            MONITORING_IP[Monitoring<br/>10.101.0.0/24]
            BACKUP_IP[Backup Services<br/>10.102.0.0/24]
        end
        
        subgraph "Future Expansion"
            EXPANSION_1[Region 2<br/>10.20.0.0/24]
            EXPANSION_2[Region 3<br/>10.30.0.0/24]
            EXPANSION_3[Additional GKE<br/>10.3.0.0/16]
        end
    end
```

## Firewall Rules Architecture

```mermaid
graph TB
    subgraph "Hierarchical Firewall Policies"
        subgraph "Organization Level"
            ORG_DENY_ALL[Deny All External<br/>Priority: 65534]
            ORG_ALLOW_HEALTH[Allow Health Checks<br/>Priority: 1000]
        end
        
        subgraph "Folder Level (Environment)"
            DEV_ALLOW_SSH[Dev: Allow SSH<br/>Priority: 2000]
            PROD_RESTRICT_SSH[Prod: Restrict SSH<br/>Priority: 2000]
        end
        
        subgraph "Project Level"
            APP_ALLOW_HTTP[Allow HTTP/HTTPS<br/>Priority: 3000]
            DB_ALLOW_INTERNAL[Allow DB Internal<br/>Priority: 3000]
            GKE_ALLOW_NODEPORT[Allow GKE NodePort<br/>Priority: 3000]
        end
        
        subgraph "Network Tags"
            WEB_TIER[web-tier]
            APP_TIER[app-tier]
            DB_TIER[db-tier]
            GKE_NODE[gke-node]
        end
    end
    
    ORG_DENY_ALL --> DEV_ALLOW_SSH
    ORG_DENY_ALL --> PROD_RESTRICT_SSH
    DEV_ALLOW_SSH --> APP_ALLOW_HTTP
    PROD_RESTRICT_SSH --> APP_ALLOW_HTTP
    APP_ALLOW_HTTP --> WEB_TIER
    DB_ALLOW_INTERNAL --> DB_TIER
    GKE_ALLOW_NODEPORT --> GKE_NODE
```

## Load Balancer Architecture

```mermaid
graph TB
    subgraph "External Load Balancing"
        GLB[Global Load Balancer<br/>Anycast IP]
        SSL_CERT[SSL Certificates<br/>Google Managed]
        CLOUD_CDN[Cloud CDN<br/>Global Edge Cache]
    end
    
    subgraph "Regional Load Balancing"
        RLB_US_CENTRAL[Regional LB<br/>us-central1]
        RLB_US_EAST[Regional LB<br/>us-east1]
    end
    
    subgraph "Internal Load Balancing"
        ILB_APP[Internal LB<br/>Application Tier]
        ILB_DB[Internal LB<br/>Database Tier]
    end
    
    subgraph "Backend Services"
        subgraph "us-central1"
            GKE_BACKEND_1[GKE Service<br/>app-service]
            VM_BACKEND_1[VM Instance Group<br/>web-servers]
        end
        
        subgraph "us-east1"
            GKE_BACKEND_2[GKE Service<br/>app-service-dr]
            VM_BACKEND_2[VM Instance Group<br/>web-servers-dr]
        end
    end
    
    GLB --> SSL_CERT
    GLB --> CLOUD_CDN
    GLB --> RLB_US_CENTRAL
    GLB --> RLB_US_EAST
    
    RLB_US_CENTRAL --> GKE_BACKEND_1
    RLB_US_CENTRAL --> VM_BACKEND_1
    RLB_US_EAST --> GKE_BACKEND_2
    RLB_US_EAST --> VM_BACKEND_2
    
    ILB_APP --> GKE_BACKEND_1
    ILB_DB --> VM_BACKEND_1
```

## Network Security Controls

```mermaid
graph TB
    subgraph "Defense in Depth"
        subgraph "Perimeter Security"
            CLOUD_ARMOR[Cloud Armor<br/>WAF + DDoS Protection]
            CLOUD_IDS[Cloud IDS<br/>Intrusion Detection]
            VPC_SC[VPC Service Controls<br/>Data Exfiltration Protection]
        end
        
        subgraph "Network Segmentation"
            MICRO_SEGMENTATION[Micro-segmentation<br/>Firewall Rules]
            NETWORK_TAGS[Network Tags<br/>Granular Control]
            PRIVATE_CLUSTERS[Private GKE Clusters<br/>No Public IPs]
        end
        
        subgraph "Traffic Analysis"
            VPC_FLOW_LOGS[VPC Flow Logs<br/>Network Monitoring]
            PACKET_MIRRORING[Packet Mirroring<br/>Deep Inspection]
            NETWORK_INTELLIGENCE[Network Intelligence<br/>Anomaly Detection]
        end
        
        subgraph "Access Control"
            PRIVATE_GOOGLE_ACCESS[Private Google Access<br/>No Internet for APIs]
            PRIVATE_SERVICE_CONNECT[Private Service Connect<br/>Secure Service Access]
            AUTHORIZED_NETWORKS[Authorized Networks<br/>IP Whitelisting]
        end
    end
```

## Hybrid Connectivity Details

```mermaid
graph LR
    subgraph "On-Premises"
        CORP_DC[Corporate Data Center<br/>192.168.0.0/16]
        BRANCH_OFFICE[Branch Offices<br/>172.16.0.0/12]
        REMOTE_USERS[Remote Users<br/>VPN Clients]
    end
    
    subgraph "Connectivity Options"
        subgraph "VPN Connections"
            CLASSIC_VPN[Classic VPN<br/>Static Routing]
            HA_VPN[HA VPN<br/>Dynamic Routing<br/>99.99% SLA]
        end
        
        subgraph "Dedicated Connectivity"
            DEDICATED_INTERCONNECT[Dedicated Interconnect<br/>10Gbps - 200Gbps]
            PARTNER_INTERCONNECT[Partner Interconnect<br/>50Mbps - 50Gbps]
        end
    end
    
    subgraph "GCP Network"
        CLOUD_ROUTER_HYBRID[Cloud Router<br/>BGP Routing<br/>ASN: 65001]
        VPC_NETWORK[Shared VPC<br/>10.0.0.0/8]
    end
    
    CORP_DC --> HA_VPN
    BRANCH_OFFICE --> CLASSIC_VPN
    CORP_DC --> DEDICATED_INTERCONNECT
    BRANCH_OFFICE --> PARTNER_INTERCONNECT
    
    HA_VPN --> CLOUD_ROUTER_HYBRID
    CLASSIC_VPN --> CLOUD_ROUTER_HYBRID
    DEDICATED_INTERCONNECT --> CLOUD_ROUTER_HYBRID
    PARTNER_INTERCONNECT --> CLOUD_ROUTER_HYBRID
    
    CLOUD_ROUTER_HYBRID --> VPC_NETWORK
```

## Key Network Design Principles

1. **Hub-and-Spoke**: Centralized shared VPC with service project attachments
2. **Private by Default**: No public IPs for compute resources
3. **Hierarchical Security**: Organization → Folder → Project level controls
4. **Scalable IP Planning**: /16 ranges for future growth
5. **Multi-Region**: Primary (us-central1) + DR (us-east1)
6. **Zero Trust**: Micro-segmentation with network tags
7. **Hybrid Ready**: VPN and Interconnect for on-premises connectivity
8. **Monitoring**: Comprehensive flow logs and packet analysis