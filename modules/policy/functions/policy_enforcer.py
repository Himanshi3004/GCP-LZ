"""
Policy Enforcement Cloud Function
Validates Terraform plans against OPA policies and blocks non-compliant deployments
"""

import json
import os
import base64
import subprocess
import tempfile
from google.cloud import pubsub_v1
from google.cloud import storage
from google.cloud import bigquery
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def enforce_policies(event, context):
    """
    Main function to enforce policies on Terraform plans
    """
    try:
        # Decode the Pub/Sub message
        pubsub_message = base64.b64decode(event['data']).decode('utf-8')
        message_data = json.loads(pubsub_message)
        
        logger.info(f"Processing policy enforcement for: {message_data}")
        
        # Download policy bundle
        policy_bundle_path = download_policy_bundle()
        
        # Get Terraform plan from message
        terraform_plan = message_data.get('terraform_plan')
        if not terraform_plan:
            logger.error("No Terraform plan found in message")
            return
        
        # Validate plan against policies
        violations = validate_plan(terraform_plan, policy_bundle_path)
        
        # Process violations
        if violations:
            handle_violations(violations, message_data)
        else:
            logger.info("No policy violations found")
            publish_success_notification(message_data)
        
    except Exception as e:
        logger.error(f"Error in policy enforcement: {str(e)}")
        publish_error_notification(str(e))

def download_policy_bundle():
    """
    Download the latest policy bundle from Cloud Storage
    """
    client = storage.Client()
    bucket_name = os.environ.get('POLICY_BUNDLE_BUCKET')
    bundle_path = 'bundles/policy-bundle-latest.tar.gz'
    
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(bundle_path)
    
    # Download to temporary file
    temp_dir = tempfile.mkdtemp()
    bundle_file = os.path.join(temp_dir, 'policy-bundle.tar.gz')
    blob.download_to_filename(bundle_file)
    
    # Extract bundle
    subprocess.run(['tar', '-xzf', bundle_file, '-C', temp_dir], check=True)
    
    return os.path.join(temp_dir, 'policies')

def validate_plan(terraform_plan, policy_path):
    """
    Validate Terraform plan against OPA policies
    """
    violations = []
    
    try:
        # Create temporary file for Terraform plan
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(terraform_plan, f)
            plan_file = f.name
        
        # Run OPA evaluation
        cmd = [
            'opa', 'eval',
            '--data', policy_path,
            '--input', plan_file,
            '--format', 'json',
            'data.terraform'
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        evaluation_result = json.loads(result.stdout)
        
        # Extract violations from result
        if evaluation_result.get('result'):
            for policy_result in evaluation_result['result']:
                if 'deny' in policy_result and policy_result['deny']:
                    violations.extend(policy_result['deny'])
        
        # Clean up
        os.unlink(plan_file)
        
    except subprocess.CalledProcessError as e:
        logger.error(f"OPA evaluation failed: {e.stderr}")
        raise
    except Exception as e:
        logger.error(f"Error validating plan: {str(e)}")
        raise
    
    return violations

def handle_violations(violations, message_data):
    """
    Handle policy violations based on configuration
    """
    logger.warning(f"Found {len(violations)} policy violations")
    
    # Store violations in BigQuery
    store_violations(violations, message_data)
    
    # Check if deployment should be blocked
    block_deployment = os.environ.get('BLOCK_DEPLOYMENT', 'true').lower() == 'true'
    
    if block_deployment:
        # Publish blocking notification
        publish_violation_notification(violations, message_data, blocked=True)
        logger.info("Deployment blocked due to policy violations")
    else:
        # Publish warning notification
        publish_violation_notification(violations, message_data, blocked=False)
        logger.info("Policy violations detected but deployment not blocked")

def store_violations(violations, message_data):
    """
    Store policy violations in BigQuery for reporting
    """
    client = bigquery.Client()
    project_id = os.environ.get('PROJECT_ID')
    dataset_id = 'compliance_data'
    table_id = 'policy_violations'
    
    table_ref = client.dataset(dataset_id).table(table_id)
    table = client.get_table(table_ref)
    
    rows_to_insert = []
    for violation in violations:
        row = {
            'timestamp': message_data.get('timestamp'),
            'resource_type': extract_resource_type(violation),
            'resource_name': extract_resource_name(violation),
            'policy_name': extract_policy_name(violation),
            'violation_message': violation,
            'severity': determine_severity(violation),
            'environment': message_data.get('environment', 'unknown'),
            'remediation_status': 'pending'
        }
        rows_to_insert.append(row)
    
    errors = client.insert_rows_json(table, rows_to_insert)
    if errors:
        logger.error(f"Error inserting violations to BigQuery: {errors}")
    else:
        logger.info(f"Stored {len(rows_to_insert)} violations in BigQuery")

def publish_violation_notification(violations, message_data, blocked=True):
    """
    Publish notification about policy violations
    """
    publisher = pubsub_v1.PublisherClient()
    project_id = os.environ.get('PROJECT_ID')
    topic_name = 'policy-violations'
    topic_path = publisher.topic_path(project_id, topic_name)
    
    notification = {
        'type': 'policy_violation',
        'blocked': blocked,
        'violations': violations,
        'metadata': message_data,
        'timestamp': message_data.get('timestamp')
    }
    
    message_data_bytes = json.dumps(notification).encode('utf-8')
    future = publisher.publish(topic_path, message_data_bytes)
    logger.info(f"Published violation notification: {future.result()}")

def publish_success_notification(message_data):
    """
    Publish success notification when no violations found
    """
    publisher = pubsub_v1.PublisherClient()
    project_id = os.environ.get('PROJECT_ID')
    topic_name = 'policy-validation-success'
    topic_path = publisher.topic_path(project_id, topic_name)
    
    notification = {
        'type': 'policy_success',
        'message': 'No policy violations found',
        'metadata': message_data,
        'timestamp': message_data.get('timestamp')
    }
    
    message_data_bytes = json.dumps(notification).encode('utf-8')
    future = publisher.publish(topic_path, message_data_bytes)
    logger.info(f"Published success notification: {future.result()}")

def publish_error_notification(error_message):
    """
    Publish error notification
    """
    publisher = pubsub_v1.PublisherClient()
    project_id = os.environ.get('PROJECT_ID')
    topic_name = 'policy-validation-failure'
    topic_path = publisher.topic_path(project_id, topic_name)
    
    notification = {
        'type': 'policy_error',
        'error': error_message,
        'timestamp': None
    }
    
    message_data_bytes = json.dumps(notification).encode('utf-8')
    future = publisher.publish(topic_path, message_data_bytes)
    logger.info(f"Published error notification: {future.result()}")

# Helper functions
def extract_resource_type(violation):
    """Extract resource type from violation message"""
    # Simple extraction - can be enhanced based on violation format
    if 'google_compute_instance' in violation:
        return 'google_compute_instance'
    elif 'google_storage_bucket' in violation:
        return 'google_storage_bucket'
    elif 'google_sql_database_instance' in violation:
        return 'google_sql_database_instance'
    return 'unknown'

def extract_resource_name(violation):
    """Extract resource name from violation message"""
    # Simple extraction - can be enhanced based on violation format
    import re
    match = re.search(r'(\w+\.\w+)', violation)
    return match.group(1) if match else 'unknown'

def extract_policy_name(violation):
    """Extract policy name from violation message"""
    # This would need to be enhanced based on actual violation format
    return 'security_policy'

def determine_severity(violation):
    """Determine severity based on violation content"""
    high_severity_keywords = ['public', 'encryption', 'firewall', 'admin']
    medium_severity_keywords = ['label', 'backup', 'logging']
    
    violation_lower = violation.lower()
    
    if any(keyword in violation_lower for keyword in high_severity_keywords):
        return 'high'
    elif any(keyword in violation_lower for keyword in medium_severity_keywords):
        return 'medium'
    else:
        return 'low'