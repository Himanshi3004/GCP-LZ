# GCP Landing Zone - Architecture Diagram

## High-Level Architecture Overview

```mermaid
graph TB
    subgraph "GCP Organization"
        ORG[Organization<br/>example.com]
        
        subgraph "Folder Hierarchy"
            DEV_FOLDER[Development Folder]
            STG_FOLDER[Staging Folder]
            PROD_FOLDER[Production Folder]
        end
        
        ORG --> DEV_FOLDER
        ORG --> STG_FOLDER
        ORG --> PROD_FOLDER
    end
    
    subgraph "Management Layer"
        MGMT_PROJECT[Management Project<br/>company-mgmt-{env}]
        ORG_POLICIES[Organization Policies]
        AUDIT_LOGS[Audit Logging]
        BILLING[Billing Export]
    end
    
    subgraph "Security Layer"
        SCC[Security Command Center]
        KMS[Cloud KMS]
        IAM_FOUNDATION[IAM Foundation]
        VPC_SC[VPC Service Controls]
        COMPLIANCE[Compliance Controls]
    end
    
    subgraph "Networking Layer"
        SHARED_VPC[Shared VPC Host]
        SUBNETS[Subnets & Secondary Ranges]
        CLOUD_NAT[Cloud NAT]
        FIREWALL[Firewall Rules]
        HYBRID[Hybrid Connectivity]
    end
    
    subgraph "Compute Layer"
        GKE[GKE Clusters]
        INSTANCES[Compute Instances]
        SERVERLESS[Cloud Run/Functions]
    end
    
    subgraph "Data Layer"
        DATA_LAKE[Data Lake<br/>Storage + Dataflow]
        DATA_WAREHOUSE[BigQuery Warehouse]
        DATA_GOV[Data Governance<br/>Catalog + DLP]
    end
    
    subgraph "Observability Layer"
        LOGGING[Cloud Logging]
        MONITORING[Cloud Monitoring]
        OPERATIONS[Cloud Operations]
    end
    
    subgraph "DevOps Layer"
        CICD[CI/CD Pipelines]
        POLICY_CODE[Policy as Code]
        BACKUP[Backup Strategy]
        DR[Disaster Recovery]
    end
    
    %% Connections
    ORG --> MGMT_PROJECT
    MGMT_PROJECT --> SCC
    MGMT_PROJECT --> AUDIT_LOGS
    SHARED_VPC --> GKE
    SHARED_VPC --> INSTANCES
    SHARED_VPC --> SERVERLESS
    SCC --> COMPLIANCE
    IAM_FOUNDATION --> GKE
    DATA_LAKE --> DATA_WAREHOUSE
    DATA_GOV --> DATA_LAKE
    LOGGING --> MONITORING
    CICD --> POLICY_CODE
    
    %% Styling
    classDef orgLevel fill:#e1f5fe
    classDef mgmtLevel fill:#f3e5f5
    classDef secLevel fill:#ffebee
    classDef netLevel fill:#e8f5e8
    classDef compLevel fill:#fff3e0
    classDef dataLevel fill:#f1f8e9
    classDef obsLevel fill:#fce4ec
    classDef devopsLevel fill:#e0f2f1
    
    class ORG,DEV_FOLDER,STG_FOLDER,PROD_FOLDER orgLevel
    class MGMT_PROJECT,ORG_POLICIES,AUDIT_LOGS,BILLING mgmtLevel
    class SCC,KMS,IAM_FOUNDATION,VPC_SC,COMPLIANCE secLevel
    class SHARED_VPC,SUBNETS,CLOUD_NAT,FIREWALL,HYBRID netLevel
    class GKE,INSTANCES,SERVERLESS compLevel
    class DATA_LAKE,DATA_WAREHOUSE,DATA_GOV dataLevel
    class LOGGING,MONITORING,OPERATIONS obsLevel
    class CICD,POLICY_CODE,BACKUP,DR devopsLevel
```

## Detailed Module Architecture

```mermaid
graph LR
    subgraph "Root Module (main.tf)"
        ROOT[Root Configuration]
    end
    
    subgraph "Foundation Modules"
        ORG_MOD[organization/]
        PROJ_FACTORY[project-factory/]
        IAM_MOD[iam/]
    end
    
    subgraph "Networking Modules"
        SHARED_VPC_MOD[networking/shared-vpc/]
        HYBRID_MOD[networking/hybrid-connectivity/]
        NET_SEC_MOD[networking/security/]
    end
    
    subgraph "Security Modules"
        SCC_MOD[security/scc/]
        DATA_PROT_MOD[security/data-protection/]
        COMP_MOD[security/compliance/]
    end
    
    subgraph "Compute Modules"
        GKE_MOD[compute/gke/]
        INST_MOD[compute/instances/]
        SERVERLESS_MOD[compute/serverless/]
    end
    
    subgraph "Data Modules"
        LAKE_MOD[data/lake/]
        WAREHOUSE_MOD[data/warehouse/]
        GOV_MOD[data/governance/]
    end
    
    subgraph "Observability Modules"
        LOG_MON_MOD[observability/logging-monitoring/]
        OPS_MOD[observability/operations/]
    end
    
    subgraph "DevOps Modules"
        CICD_MOD[devops/cicd-pipeline/]
        SOURCE_MOD[devops/source-management/]
    end
    
    subgraph "Support Modules"
        COST_MOD[cost-management/]
        BACKUP_MOD[backup/]
        DR_MOD[disaster-recovery/]
        POLICY_MOD[policy/]
        ID_FED_MOD[identity-federation/]
    end
    
    %% Dependencies
    ROOT --> ORG_MOD
    ORG_MOD --> PROJ_FACTORY
    PROJ_FACTORY --> IAM_MOD
    IAM_MOD --> SHARED_VPC_MOD
    SHARED_VPC_MOD --> HYBRID_MOD
    SHARED_VPC_MOD --> NET_SEC_MOD
    PROJ_FACTORY --> SCC_MOD
    SCC_MOD --> DATA_PROT_MOD
    SCC_MOD --> COMP_MOD
    SHARED_VPC_MOD --> GKE_MOD
    SHARED_VPC_MOD --> INST_MOD
    PROJ_FACTORY --> SERVERLESS_MOD
    PROJ_FACTORY --> LAKE_MOD
    LAKE_MOD --> WAREHOUSE_MOD
    PROJ_FACTORY --> GOV_MOD
    ORG_MOD --> LOG_MON_MOD
    PROJ_FACTORY --> OPS_MOD
    PROJ_FACTORY --> CICD_MOD
    PROJ_FACTORY --> COST_MOD
    PROJ_FACTORY --> BACKUP_MOD
    PROJ_FACTORY --> DR_MOD
    ORG_MOD --> POLICY_MOD
    IAM_MOD --> ID_FED_MOD
```

## Network Architecture Detail

```mermaid
graph TB
    subgraph "Shared VPC Host Project"
        VPC[VPC Network<br/>company-{env}-shared-vpc]
        
        subgraph "Subnets"
            MAIN_SUBNET[Main Subnet<br/>10.0.0.0/24]
            GKE_PODS[GKE Pods<br/>10.1.0.0/16]
            GKE_SERVICES[GKE Services<br/>10.2.0.0/20]
        end
        
        subgraph "Network Services"
            CLOUD_NAT_SVC[Cloud NAT]
            CLOUD_ROUTER[Cloud Router]
            FIREWALL_RULES[Firewall Rules]
        end
        
        subgraph "Security Services"
            CLOUD_ARMOR[Cloud Armor]
            CLOUD_IDS[Cloud IDS]
            VPC_FLOW_LOGS[VPC Flow Logs]
        end
        
        subgraph "Hybrid Connectivity"
            VPN_GATEWAY[VPN Gateway]
            INTERCONNECT[Cloud Interconnect]
        end
    end
    
    subgraph "Service Projects"
        DEV_PROJ[Development Projects]
        STG_PROJ[Staging Projects]
        PROD_PROJ[Production Projects]
    end
    
    VPC --> MAIN_SUBNET
    MAIN_SUBNET --> GKE_PODS
    MAIN_SUBNET --> GKE_SERVICES
    VPC --> CLOUD_NAT_SVC
    VPC --> FIREWALL_RULES
    VPC --> CLOUD_ARMOR
    VPC --> VPN_GATEWAY
    VPC --> INTERCONNECT
    
    VPC -.-> DEV_PROJ
    VPC -.-> STG_PROJ
    VPC -.-> PROD_PROJ
```

## Security Architecture Detail

```mermaid
graph TB
    subgraph "Organization Level Security"
        ORG_POLICIES_SEC[Organization Policies]
        AUDIT_LOGGING_SEC[Audit Logging]
        SCC_ORG[Security Command Center]
    end
    
    subgraph "Identity & Access Management"
        CUSTOM_ROLES[Custom Roles]
        SERVICE_ACCOUNTS[Service Accounts]
        WORKLOAD_IDENTITY[Workload Identity]
        ID_FEDERATION[Identity Federation]
    end
    
    subgraph "Data Protection"
        KMS_KEYS[Cloud KMS Keys]
        DLP_POLICIES[DLP Policies]
        HSM[Cloud HSM]
        BINARY_AUTH[Binary Authorization]
    end
    
    subgraph "Network Security"
        VPC_SC_SEC[VPC Service Controls]
        PRIVATE_CONNECT[Private Service Connect]
        CLOUD_ARMOR_SEC[Cloud Armor]
        CLOUD_IDS_SEC[Cloud IDS]
    end
    
    subgraph "Compliance Controls"
        ACCESS_CONTEXT[Access Context Manager]
        ASSURED_WORKLOADS[Assured Workloads]
        COMPLIANCE_MONITORING[Compliance Monitoring]
    end
    
    ORG_POLICIES_SEC --> CUSTOM_ROLES
    SCC_ORG --> DLP_POLICIES
    SERVICE_ACCOUNTS --> WORKLOAD_IDENTITY
    KMS_KEYS --> BINARY_AUTH
    VPC_SC_SEC --> PRIVATE_CONNECT
    ACCESS_CONTEXT --> ASSURED_WORKLOADS
```

## Data Architecture Detail

```mermaid
graph LR
    subgraph "Data Ingestion"
        PUBSUB[Cloud Pub/Sub]
        STORAGE_INGESTION[Cloud Storage]
        STREAMING[Streaming Data]
    end
    
    subgraph "Data Processing"
        DATAFLOW[Cloud Dataflow]
        COMPOSER[Cloud Composer]
        DATAPROC[Cloud Dataproc]
    end
    
    subgraph "Data Lake"
        RAW_STORAGE[Raw Data<br/>Cloud Storage]
        PROCESSED_STORAGE[Processed Data<br/>Cloud Storage]
        METADATA[Data Catalog]
    end
    
    subgraph "Data Warehouse"
        BIGQUERY[BigQuery]
        BI_ENGINE[BI Engine]
        ML_MODELS[ML Models]
    end
    
    subgraph "Data Governance"
        DLP_GOV[DLP Policies]
        LINEAGE[Data Lineage]
        AUDIT_GOV[Audit Logging]
    end
    
    PUBSUB --> DATAFLOW
    STORAGE_INGESTION --> DATAFLOW
    STREAMING --> DATAFLOW
    DATAFLOW --> RAW_STORAGE
    COMPOSER --> DATAPROC
    RAW_STORAGE --> PROCESSED_STORAGE
    PROCESSED_STORAGE --> BIGQUERY
    BIGQUERY --> BI_ENGINE
    BIGQUERY --> ML_MODELS
    METADATA --> DLP_GOV
    DLP_GOV --> LINEAGE
    LINEAGE --> AUDIT_GOV
```

## Environment Strategy

```mermaid
graph TB
    subgraph "Development Environment"
        DEV_FOLDER_ENV[Development Folder]
        DEV_PROJECTS[Development Projects]
        DEV_POLICIES[Relaxed Policies]
        DEV_BUDGET[Development Budget]
    end
    
    subgraph "Staging Environment"
        STG_FOLDER_ENV[Staging Folder]
        STG_PROJECTS[Staging Projects]
        STG_POLICIES[Moderate Policies]
        STG_BUDGET[Staging Budget]
    end
    
    subgraph "Production Environment"
        PROD_FOLDER_ENV[Production Folder]
        PROD_PROJECTS[Production Projects]
        PROD_POLICIES[Strict Policies]
        PROD_BUDGET[Production Budget]
    end
    
    subgraph "Shared Services"
        SHARED_NETWORKING[Shared VPC]
        SHARED_SECURITY[Security Controls]
        SHARED_MONITORING[Monitoring]
    end
    
    DEV_FOLDER_ENV --> DEV_PROJECTS
    STG_FOLDER_ENV --> STG_PROJECTS
    PROD_FOLDER_ENV --> PROD_PROJECTS
    
    DEV_PROJECTS -.-> SHARED_NETWORKING
    STG_PROJECTS -.-> SHARED_NETWORKING
    PROD_PROJECTS -.-> SHARED_NETWORKING
    
    SHARED_SECURITY --> DEV_POLICIES
    SHARED_SECURITY --> STG_POLICIES
    SHARED_SECURITY --> PROD_POLICIES
```

## Key Architecture Principles

1. **Hub-and-Spoke Design**: Centralized shared services with distributed workloads
2. **Environment Isolation**: Clear separation between dev/staging/production
3. **Security by Default**: Zero-trust architecture with least privilege access
4. **Scalable Foundation**: Support for 1000+ projects and workloads
5. **Compliance Ready**: Built-in controls for SOC2, ISO27001, PCI-DSS
6. **Cost Optimized**: Resource tagging, budgets, and quota management
7. **Automated Operations**: Infrastructure as Code with CI/CD pipelines
8. **Disaster Recovery**: Multi-region backup and failover capabilities

## Module Dependencies

The architecture follows a strict dependency hierarchy:
1. **Foundation**: Organization → Project Factory → IAM
2. **Networking**: Shared VPC → Hybrid Connectivity → Security
3. **Compute**: Networking → GKE/Instances/Serverless
4. **Data**: Projects → Lake → Warehouse → Governance
5. **Security**: Projects → SCC → Data Protection → Compliance
6. **Operations**: Foundation → Logging → Monitoring → Operations