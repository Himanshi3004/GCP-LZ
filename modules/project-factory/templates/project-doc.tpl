# Project: ${project_name}

## Overview
- **Project ID**: `${project_id}`
- **Project Number**: `${project_number}`
- **Department**: ${department}
- **Type**: ${project_type.labels.type}
- **Tier**: ${project_type.labels.tier}
- **Criticality**: ${project_type.labels.criticality}

## Configuration
- **Budget Amount**: $${budget_amount}
- **Budget Multiplier**: ${project_type.budget_multiplier}
- **Deletion Protection**: ${project_type.deletion_protection}
- **Backup Required**: ${project_type.labels.backup_required}

## APIs Enabled
%{ for api in apis ~}
- ${api}
%{ endfor ~}

## Default IAM Roles
%{ for role in project_type.default_roles ~}
- ${role}
%{ endfor ~}

## Essential Contacts
%{ for contact in project_type.essential_contacts ~}
- ${contact}
%{ endfor ~}

## Labels
%{ for key, value in labels ~}
- **${key}**: ${value}
%{ endfor ~}

## Notes
%{ if project_type.lien_reason != null ~}
- **Lien Reason**: ${project_type.lien_reason}
%{ endif ~}

---
*Generated automatically by Terraform Landing Zone*
*Last updated: ${timestamp()}*