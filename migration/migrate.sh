#!/bin/bash

set -e

# Migration script for GCP Landing Zone
PROJECT_ID=$1
ENVIRONMENT=$2

if [ -z "$PROJECT_ID" ] || [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 PROJECT_ID ENVIRONMENT"
    exit 1
fi

echo "Starting migration for project: $PROJECT_ID to environment: $ENVIRONMENT"

# Create backup of current state
echo "Creating backup..."
mkdir -p backups
terraform state pull > "backups/terraform-state-backup-$(date +%Y%m%d_%H%M%S).json"

# Set environment variables
export TF_VAR_project_id=$PROJECT_ID
export TF_VAR_environment=$ENVIRONMENT

# Phase 1: Foundation
echo "Phase 1: Migrating foundation components..."
terraform apply -target=module.organization -auto-approve
terraform apply -target=module.project_factory -auto-approve

# Phase 2: IAM
echo "Phase 2: Migrating IAM components..."
terraform apply -target=module.iam -auto-approve
terraform apply -target=module.identity_federation -auto-approve

# Phase 3: Networking
echo "Phase 3: Migrating networking components..."
terraform apply -target=module.shared_vpc -auto-approve
terraform apply -target=module.hybrid_connectivity -auto-approve
terraform apply -target=module.network_security -auto-approve

# Phase 4: Security
echo "Phase 4: Migrating security components..."
terraform apply -target=module.security_command_center -auto-approve
terraform apply -target=module.data_protection -auto-approve
terraform apply -target=module.compliance -auto-approve

# Phase 5: Observability
echo "Phase 5: Migrating observability components..."
terraform apply -target=module.logging_monitoring -auto-approve
terraform apply -target=module.cloud_operations -auto-approve
terraform apply -target=module.cost_management -auto-approve

# Phase 6: Compute
echo "Phase 6: Migrating compute components..."
terraform apply -target=module.gke -auto-approve
terraform apply -target=module.compute_instances -auto-approve
terraform apply -target=module.serverless -auto-approve

# Phase 7: Data
echo "Phase 7: Migrating data components..."
terraform apply -target=module.data_lake -auto-approve
terraform apply -target=module.data_warehouse -auto-approve
terraform apply -target=module.data_governance -auto-approve

# Phase 8: CI/CD
echo "Phase 8: Migrating CI/CD components..."
terraform apply -target=module.cicd_pipeline -auto-approve
terraform apply -target=module.policy -auto-approve

# Phase 9: Backup & DR
echo "Phase 9: Migrating backup and DR components..."
terraform apply -target=module.backup -auto-approve
terraform apply -target=module.disaster_recovery -auto-approve

# Final validation
echo "Running final validation..."
terraform plan

echo "Migration completed successfully!"
echo "Backup saved to: backups/"