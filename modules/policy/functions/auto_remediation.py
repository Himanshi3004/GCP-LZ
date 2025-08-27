"""
Auto-Remediation Cloud Function
Automatically remediates common policy violations
"""

import json
import os
import base64
from google.cloud import compute_v1
from google.cloud import storage
from google.cloud import sql_v1
from google.cloud import pubsub_v1
from google.cloud import bigquery
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def remediate_violations(event, context):
    """
    Main function to remediate policy violations
    """
    try:
        # Decode the Pub/Sub message
        pubsub_message = base64.b64decode(event['data']).decode('utf-8')
        message_data = json.loads(pubsub_message)
        
        logger.info(f"Processing auto-remediation for: {message_data}")
        
        violations = message_data.get('violations', [])
        if not violations:
            logger.info("No violations to remediate")
            return
        
        remediation_results = []
        
        for violation in violations:
            try:
                result = remediate_single_violation(violation, message_data)
                remediation_results.append(result)
            except Exception as e:
                logger.error(f"Failed to remediate violation {violation}: {str(e)}")
                remediation_results.append({
                    'violation': violation,
                    'status': 'failed',
                    'error': str(e)
                })
        
        # Update remediation status in BigQuery
        update_remediation_status(remediation_results)
        
        # Send notification about remediation results
        send_remediation_notification(remediation_results, message_data)
        
    except Exception as e:
        logger.error(f"Error in auto-remediation: {str(e)}")

def remediate_single_violation(violation, message_data):
    """
    Remediate a single policy violation
    """
    violation_type = classify_violation(violation)
    resource_info = extract_resource_info(violation)
    
    logger.info(f"Remediating {violation_type} for resource {resource_info}")
    
    remediation_functions = {
        'missing_labels': remediate_missing_labels,
        'public_ip': remediate_public_ip,
        'unencrypted_storage': remediate_unencrypted_storage,
        'open_firewall': remediate_open_firewall,
        'sql_public_ip': remediate_sql_public_ip,
        'missing_backup': remediate_missing_backup
    }
    
    if violation_type in remediation_functions:
        return remediation_functions[violation_type](resource_info, violation)
    else:
        logger.warning(f"No remediation available for violation type: {violation_type}")
        return {
            'violation': violation,
            'status': 'no_remediation_available',
            'message': f"No automatic remediation for {violation_type}"
        }

def remediate_missing_labels(resource_info, violation):
    """
    Add missing required labels to resources
    """
    try:
        resource_type = resource_info.get('type')
        resource_name = resource_info.get('name')
        project_id = os.environ.get('PROJECT_ID')
        
        required_labels = {
            'security_classification': 'internal',
            'environment': 'dev',
            'cost_center': 'engineering',
            'owner': 'platform-team'
        }
        
        if resource_type == 'google_compute_instance':
            client = compute_v1.InstancesClient()
            zone = resource_info.get('zone', 'us-central1-a')
            
            # Get current instance
            instance = client.get(project=project_id, zone=zone, instance=resource_name)
            
            # Update labels
            current_labels = instance.labels or {}
            updated_labels = {**current_labels, **required_labels}
            
            # Apply labels
            client.set_labels(
                project=project_id,
                zone=zone,
                instance=resource_name,
                instances_set_labels_request_resource={
                    'labels': updated_labels,
                    'label_fingerprint': instance.label_fingerprint
                }
            )
            
            return {
                'violation': violation,
                'status': 'remediated',
                'action': 'added_required_labels',
                'resource': f"{resource_type}.{resource_name}"
            }
            
        elif resource_type == 'google_storage_bucket':
            client = storage.Client()
            bucket = client.bucket(resource_name)
            
            # Update bucket labels
            current_labels = bucket.labels or {}
            updated_labels = {**current_labels, **required_labels}
            bucket.labels = updated_labels
            bucket.patch()
            
            return {
                'violation': violation,
                'status': 'remediated',
                'action': 'added_required_labels',
                'resource': f"{resource_type}.{resource_name}"
            }
        
    except Exception as e:
        logger.error(f"Failed to remediate missing labels: {str(e)}")
        return {
            'violation': violation,
            'status': 'failed',
            'error': str(e)
        }

def remediate_public_ip(resource_info, violation):
    """
    Remove public IP from compute instances in production
    """
    try:
        resource_name = resource_info.get('name')
        project_id = os.environ.get('PROJECT_ID')
        zone = resource_info.get('zone', 'us-central1-a')
        
        client = compute_v1.InstancesClient()
        
        # Get instance details
        instance = client.get(project=project_id, zone=zone, instance=resource_name)
        
        # Check if instance has public IP
        for interface in instance.network_interfaces:
            if interface.access_configs:
                # Remove access config (public IP)
                client.delete_access_config(
                    project=project_id,
                    zone=zone,
                    instance=resource_name,
                    access_config='External NAT',
                    network_interface=interface.name
                )
                
                return {
                    'violation': violation,
                    'status': 'remediated',
                    'action': 'removed_public_ip',
                    'resource': f"google_compute_instance.{resource_name}"
                }
        
        return {
            'violation': violation,
            'status': 'no_action_needed',
            'message': 'No public IP found'
        }
        
    except Exception as e:
        logger.error(f"Failed to remediate public IP: {str(e)}")
        return {
            'violation': violation,
            'status': 'failed',
            'error': str(e)
        }

def remediate_open_firewall(resource_info, violation):
    """
    Restrict overly permissive firewall rules
    """
    try:
        resource_name = resource_info.get('name')
        project_id = os.environ.get('PROJECT_ID')
        
        client = compute_v1.FirewallsClient()
        
        # Get firewall rule
        firewall = client.get(project=project_id, firewall=resource_name)
        
        # Check if rule allows 0.0.0.0/0
        if '0.0.0.0/0' in firewall.source_ranges:
            # Replace with more restrictive range
            restricted_ranges = ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16']
            
            # Update firewall rule
            firewall.source_ranges = restricted_ranges
            
            client.update(
                project=project_id,
                firewall=resource_name,
                firewall_resource=firewall
            )
            
            return {
                'violation': violation,
                'status': 'remediated',
                'action': 'restricted_source_ranges',
                'resource': f"google_compute_firewall.{resource_name}"
            }
        
        return {
            'violation': violation,
            'status': 'no_action_needed',
            'message': 'Firewall rule already restricted'
        }
        
    except Exception as e:
        logger.error(f"Failed to remediate firewall rule: {str(e)}")
        return {
            'violation': violation,
            'status': 'failed',
            'error': str(e)
        }

def remediate_sql_public_ip(resource_info, violation):
    """
    Disable public IP for Cloud SQL instances
    """
    try:
        resource_name = resource_info.get('name')
        project_id = os.environ.get('PROJECT_ID')
        
        client = sql_v1.SqlInstancesServiceClient()
        
        # Get instance
        instance = client.get(project=project_id, instance=resource_name)
        
        # Update IP configuration to disable public IP
        if instance.settings.ip_configuration.ipv4_enabled:
            instance.settings.ip_configuration.ipv4_enabled = False
            
            # Update instance
            operation = client.update(
                project=project_id,
                instance=resource_name,
                body=instance
            )
            
            return {
                'violation': violation,
                'status': 'remediated',
                'action': 'disabled_public_ip',
                'resource': f"google_sql_database_instance.{resource_name}"
            }
        
        return {
            'violation': violation,
            'status': 'no_action_needed',
            'message': 'Public IP already disabled'
        }
        
    except Exception as e:
        logger.error(f"Failed to remediate SQL public IP: {str(e)}")
        return {
            'violation': violation,
            'status': 'failed',
            'error': str(e)
        }

def remediate_unencrypted_storage(resource_info, violation):
    """
    Enable encryption for storage buckets
    """
    try:
        resource_name = resource_info.get('name')
        project_id = os.environ.get('PROJECT_ID')
        
        client = storage.Client()
        bucket = client.bucket(resource_name)
        
        # Set default KMS key (this would need to be configured)
        default_kms_key = f"projects/{project_id}/locations/us/keyRings/default/cryptoKeys/bucket-key"
        
        # Update bucket encryption
        bucket.default_kms_key_name = default_kms_key
        bucket.patch()
        
        return {
            'violation': violation,
            'status': 'remediated',
            'action': 'enabled_cmek_encryption',
            'resource': f"google_storage_bucket.{resource_name}"
        }
        
    except Exception as e:
        logger.error(f"Failed to remediate storage encryption: {str(e)}")
        return {
            'violation': violation,
            'status': 'failed',
            'error': str(e)
        }

def remediate_missing_backup(resource_info, violation):
    """
    Enable backup for Cloud SQL instances
    """
    try:
        resource_name = resource_info.get('name')
        project_id = os.environ.get('PROJECT_ID')
        
        client = sql_v1.SqlInstancesServiceClient()
        
        # Get instance
        instance = client.get(project=project_id, instance=resource_name)
        
        # Enable backup configuration
        if not instance.settings.backup_configuration.enabled:
            instance.settings.backup_configuration.enabled = True
            instance.settings.backup_configuration.start_time = "02:00"
            
            # Update instance
            operation = client.update(
                project=project_id,
                instance=resource_name,
                body=instance
            )
            
            return {
                'violation': violation,
                'status': 'remediated',
                'action': 'enabled_backup',
                'resource': f"google_sql_database_instance.{resource_name}"
            }
        
        return {
            'violation': violation,
            'status': 'no_action_needed',
            'message': 'Backup already enabled'
        }
        
    except Exception as e:
        logger.error(f"Failed to remediate backup: {str(e)}")
        return {
            'violation': violation,
            'status': 'failed',
            'error': str(e)
        }

def classify_violation(violation):
    """
    Classify the type of violation for appropriate remediation
    """
    violation_lower = violation.lower()
    
    if 'label' in violation_lower:
        return 'missing_labels'
    elif 'public ip' in violation_lower and 'production' in violation_lower:
        return 'public_ip'
    elif 'encryption' in violation_lower and 'bucket' in violation_lower:
        return 'unencrypted_storage'
    elif 'firewall' in violation_lower and '0.0.0.0/0' in violation_lower:
        return 'open_firewall'
    elif 'sql' in violation_lower and 'public ip' in violation_lower:
        return 'sql_public_ip'
    elif 'backup' in violation_lower:
        return 'missing_backup'
    else:
        return 'unknown'

def extract_resource_info(violation):
    """
    Extract resource information from violation message
    """
    import re
    
    # Extract resource type and name
    resource_match = re.search(r'(google_\w+)\.(\w+)', violation)
    if resource_match:
        return {
            'type': resource_match.group(1),
            'name': resource_match.group(2)
        }
    
    return {'type': 'unknown', 'name': 'unknown'}

def update_remediation_status(remediation_results):
    """
    Update remediation status in BigQuery
    """
    try:
        client = bigquery.Client()
        project_id = os.environ.get('PROJECT_ID')
        dataset_id = 'compliance_data'
        table_id = 'policy_violations'
        
        for result in remediation_results:
            if result['status'] == 'remediated':
                # Update the violation record
                query = f"""
                UPDATE `{project_id}.{dataset_id}.{table_id}`
                SET remediation_status = 'remediated',
                    remediation_timestamp = CURRENT_TIMESTAMP()
                WHERE violation_message = @violation_message
                """
                
                job_config = bigquery.QueryJobConfig(
                    query_parameters=[
                        bigquery.ScalarQueryParameter("violation_message", "STRING", result['violation'])
                    ]
                )
                
                client.query(query, job_config=job_config)
        
        logger.info(f"Updated remediation status for {len(remediation_results)} violations")
        
    except Exception as e:
        logger.error(f"Failed to update remediation status: {str(e)}")

def send_remediation_notification(remediation_results, message_data):
    """
    Send notification about remediation results
    """
    try:
        publisher = pubsub_v1.PublisherClient()
        project_id = os.environ.get('PROJECT_ID')
        topic_name = 'compliance-notifications'
        topic_path = publisher.topic_path(project_id, topic_name)
        
        notification = {
            'type': 'auto_remediation_complete',
            'results': remediation_results,
            'metadata': message_data,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        message_data_bytes = json.dumps(notification).encode('utf-8')
        future = publisher.publish(topic_path, message_data_bytes)
        logger.info(f"Published remediation notification: {future.result()}")
        
    except Exception as e:
        logger.error(f"Failed to send remediation notification: {str(e)}")