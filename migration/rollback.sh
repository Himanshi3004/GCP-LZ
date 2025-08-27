#!/bin/bash

set -e

# Rollback script for failed migrations
BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 BACKUP_FILE"
    echo "Available backups:"
    ls -la backups/
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "WARNING: This will rollback Terraform state to a previous backup."
echo "Current state will be lost. Are you sure? (yes/no)"
read -r confirmation

if [ "$confirmation" != "yes" ]; then
    echo "Rollback cancelled"
    exit 0
fi

# Create backup of current state before rollback
echo "Creating backup of current state..."
terraform state pull > "backups/pre-rollback-backup-$(date +%Y%m%d_%H%M%S).json"

# Restore state from backup
echo "Restoring state from backup: $BACKUP_FILE"
terraform state push "$BACKUP_FILE"

# Verify state
echo "Verifying restored state..."
terraform plan

echo "Rollback completed successfully!"
echo "Please review the Terraform plan output above."