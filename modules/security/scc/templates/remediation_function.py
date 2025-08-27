import json
import base64
import logging
from google.cloud import securitycenter
from google.cloud import compute_v1
from google.cloud import storage
from google.cloud import bigquery
import os

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def remediate_finding(cloud_event):
    """Main function to process SCC findings and apply remediation"""
    
    # Decode Pub/Sub message
    pubsub_message = base64.b64decode(cloud_event.data['message']['data']).decode('utf-8')
    finding_data = json.loads(pubsub_message)
    
    project_id = os.environ.get('PROJECT_ID')
    org_id = os.environ.get('ORG_ID')
    
    # Initialize clients
    scc_client = securitycenter.SecurityCenterClient()
    
    try:
        # Parse finding information
        finding_name = finding_data.get('name', '')
        category = finding_data.get('category', '')
        resource_name = finding_data.get('resourceName', '')
        severity = finding_data.get('severity', 'LOW')
        
        logger.info(f"Processing finding: {finding_name}")
        
        # Apply remediation based on finding category
        remediation_result = apply_remediation(
            category, resource_name, finding_data, project_id
        )
        
        # Log remediation action
        log_remediation_action(
            finding_name, resource_name, category, 
            remediation_result, project_id
        )
        
        # Update finding status
        if remediation_result['success']:
            update_finding_status(scc_client, finding_name, 'RESOLVED')
        
        return {'status': 'success', 'action': remediation_result}
        
    except Exception as e:
        logger.error(f"Error processing finding: {str(e)}")
        log_remediation_action(
            finding_name, resource_name, category,
            {'success': False, 'error': str(e)}, project_id
        )
        return {'status': 'error', 'message': str(e)}

def apply_remediation(category, resource_name, finding_data, project_id):
    """Apply specific remediation based on finding category"""
    
    if 'COMPUTE' in category.upper():
        return remediate_compute_finding(resource_name, finding_data, project_id)
    elif 'STORAGE' in category.upper():
        return remediate_storage_finding(resource_name, finding_data, project_id)
    elif 'IAM' in category.upper():
        return remediate_iam_finding(resource_name, finding_data, project_id)
    else:
        return {'success': False, 'action': 'no_remediation_available'}

def remediate_compute_finding(resource_name, finding_data, project_id):
    """Remediate compute-related security findings"""
    
    try:
        compute_client = compute_v1.InstancesClient()
        
        # Extract instance details from resource name
        parts = resource_name.split('/')
        zone = parts[-3]
        instance_name = parts[-1]
        
        # Get instance details
        instance = compute_client.get(
            project=project_id, zone=zone, instance=instance_name
        )
        
        # Apply security hardening
        actions_taken = []
        
        # Enable OS Login if not enabled
        if not has_os_login_enabled(instance):
            enable_os_login(compute_client, project_id, zone, instance_name)
            actions_taken.append('enabled_os_login')
        
        # Enable Shielded VM if not enabled
        if not has_shielded_vm_enabled(instance):
            enable_shielded_vm(compute_client, project_id, zone, instance_name)
            actions_taken.append('enabled_shielded_vm')
        
        return {
            'success': True,
            'actions': actions_taken,
            'resource': resource_name
        }
        
    except Exception as e:
        logger.error(f"Error remediating compute finding: {str(e)}")
        return {'success': False, 'error': str(e)}

def remediate_storage_finding(resource_name, finding_data, project_id):
    """Remediate storage-related security findings"""
    
    try:
        storage_client = storage.Client(project=project_id)
        
        # Extract bucket name from resource name
        bucket_name = resource_name.split('/')[-1]
        bucket = storage_client.bucket(bucket_name)
        
        actions_taken = []
        
        # Enable uniform bucket-level access
        if not bucket.iam_configuration.uniform_bucket_level_access_enabled:
            bucket.iam_configuration.uniform_bucket_level_access_enabled = True
            bucket.patch()
            actions_taken.append('enabled_uniform_bucket_access')
        
        # Set appropriate lifecycle policies
        if not bucket.lifecycle_rules:
            bucket.add_lifecycle_delete_rule(age=365)
            bucket.patch()
            actions_taken.append('added_lifecycle_policy')
        
        return {
            'success': True,
            'actions': actions_taken,
            'resource': resource_name
        }
        
    except Exception as e:
        logger.error(f"Error remediating storage finding: {str(e)}")
        return {'success': False, 'error': str(e)}

def remediate_iam_finding(resource_name, finding_data, project_id):
    """Remediate IAM-related security findings"""
    
    try:
        # This would implement IAM remediation logic
        # For now, return a placeholder
        return {
            'success': True,
            'actions': ['iam_review_required'],
            'resource': resource_name
        }
        
    except Exception as e:
        logger.error(f"Error remediating IAM finding: {str(e)}")
        return {'success': False, 'error': str(e)}

def has_os_login_enabled(instance):
    """Check if OS Login is enabled on instance"""
    metadata = instance.metadata
    if metadata and metadata.items:
        for item in metadata.items:
            if item.key == 'enable-oslogin' and item.value == 'TRUE':
                return True
    return False

def enable_os_login(compute_client, project_id, zone, instance_name):
    """Enable OS Login on compute instance"""
    # Implementation would go here
    pass

def has_shielded_vm_enabled(instance):
    """Check if Shielded VM is enabled"""
    return instance.shielded_instance_config is not None

def enable_shielded_vm(compute_client, project_id, zone, instance_name):
    """Enable Shielded VM features"""
    # Implementation would go here
    pass

def log_remediation_action(finding_id, resource_name, action, result, project_id):
    """Log remediation action to BigQuery"""
    
    try:
        client = bigquery.Client(project=project_id)
        table_id = f"{project_id}.scc_remediation_audit.remediation_log"
        
        rows_to_insert = [{
            'timestamp': bigquery.ScalarQueryParameter(None, 'TIMESTAMP', None),
            'finding_id': finding_id,
            'resource_name': resource_name,
            'remediation_action': action,
            'status': 'SUCCESS' if result.get('success') else 'FAILED',
            'details': json.dumps(result)
        }]
        
        errors = client.insert_rows_json(table_id, rows_to_insert)
        if errors:
            logger.error(f"Error inserting audit log: {errors}")
            
    except Exception as e:
        logger.error(f"Error logging remediation action: {str(e)}")

def update_finding_status(scc_client, finding_name, status):
    """Update SCC finding status"""
    
    try:
        finding = scc_client.get_finding(name=finding_name)
        finding.state = status
        
        update_mask = {'paths': ['state']}
        scc_client.update_finding(finding=finding, update_mask=update_mask)
        
        logger.info(f"Updated finding {finding_name} status to {status}")
        
    except Exception as e:
        logger.error(f"Error updating finding status: {str(e)}")