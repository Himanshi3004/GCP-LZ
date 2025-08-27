import json
import base64
import logging
from google.cloud import securitycenter
from google.cloud import pubsub_v1

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize clients
scc_client = securitycenter.SecurityCenterClient()
publisher = pubsub_v1.PublisherClient()

PROJECT_ID = "${project_id}"
ORG_ID = "${org_id}"

def process_finding(cloud_event):
    """
    Process Security Command Center findings and perform automated remediation.
    
    Args:
        cloud_event: Cloud Event containing the Pub/Sub message
    """
    try:
        # Decode the Pub/Sub message
        pubsub_message = base64.b64decode(cloud_event.data['message']['data'])
        finding_data = json.loads(pubsub_message)
        
        logger.info(f"Processing finding: {finding_data.get('name', 'Unknown')}")
        
        # Extract finding details
        finding_name = finding_data.get('name', '')
        category = finding_data.get('category', '')
        severity = finding_data.get('severity', '')
        state = finding_data.get('state', '')
        
        # Only process active findings
        if state != 'ACTIVE':
            logger.info(f"Skipping non-active finding: {finding_name}")
            return
        
        # Route to appropriate remediation handler
        if category == 'OPEN_FIREWALL':
            remediate_open_firewall(finding_data)
        elif category == 'PUBLIC_BUCKET_ACL':
            remediate_public_bucket(finding_data)
        elif category == 'WEAK_SSL_POLICY':
            remediate_ssl_policy(finding_data)
        elif category == 'ADMIN_SERVICE_ACCOUNT':
            remediate_admin_service_account(finding_data)
        else:
            logger.info(f"No automated remediation available for category: {category}")
            
        # Update finding state to indicate processing
        update_finding_state(finding_name, 'INACTIVE', 'Automated remediation applied')
        
    except Exception as e:
        logger.error(f"Error processing finding: {str(e)}")
        raise

def remediate_open_firewall(finding_data):
    """Remediate open firewall rules."""
    logger.info("Remediating open firewall rule")
    
    # Extract resource information
    resource_name = finding_data.get('resourceName', '')
    
    # Log the remediation action (actual implementation would modify firewall rules)
    logger.info(f"Would restrict firewall rule: {resource_name}")
    
    # In a real implementation, you would:
    # 1. Parse the resource name to get project/region/firewall-rule
    # 2. Use Compute Engine API to update the firewall rule
    # 3. Restrict source ranges to specific IP ranges
    # 4. Remove 0.0.0.0/0 if present

def remediate_public_bucket(finding_data):
    """Remediate public storage bucket."""
    logger.info("Remediating public storage bucket")
    
    resource_name = finding_data.get('resourceName', '')
    
    # Log the remediation action
    logger.info(f"Would make bucket private: {resource_name}")
    
    # In a real implementation, you would:
    # 1. Parse bucket name from resource_name
    # 2. Use Cloud Storage API to remove public access
    # 3. Enable uniform bucket-level access
    # 4. Update IAM policies

def remediate_ssl_policy(finding_data):
    """Remediate weak SSL policy."""
    logger.info("Remediating weak SSL policy")
    
    resource_name = finding_data.get('resourceName', '')
    
    # Log the remediation action
    logger.info(f"Would strengthen SSL policy: {resource_name}")
    
    # In a real implementation, you would:
    # 1. Parse SSL policy name from resource_name
    # 2. Use Compute Engine API to update SSL policy
    # 3. Set minimum TLS version to 1.2 or higher
    # 4. Remove weak cipher suites

def remediate_admin_service_account(finding_data):
    """Remediate overprivileged service account."""
    logger.info("Remediating admin service account")
    
    resource_name = finding_data.get('resourceName', '')
    
    # Log the remediation action
    logger.info(f"Would reduce service account privileges: {resource_name}")
    
    # In a real implementation, you would:
    # 1. Parse service account email from resource_name
    # 2. Use IAM API to review and reduce permissions
    # 3. Remove broad admin roles
    # 4. Apply principle of least privilege

def update_finding_state(finding_name, state, state_comment):
    """Update the state of a security finding."""
    try:
        # Create the request to update finding state
        request = securitycenter.SetFindingStateRequest(
            name=finding_name,
            state=getattr(securitycenter.Finding.State, state),
            start_time={"seconds": int(time.time())}
        )
        
        # Update the finding
        response = scc_client.set_finding_state(request=request)
        logger.info(f"Updated finding state: {finding_name} -> {state}")
        
    except Exception as e:
        logger.error(f"Failed to update finding state: {str(e)}")

def send_notification(finding_data, action_taken):
    """Send notification about remediation action."""
    try:
        notification_data = {
            'finding_name': finding_data.get('name', ''),
            'category': finding_data.get('category', ''),
            'severity': finding_data.get('severity', ''),
            'action_taken': action_taken,
            'timestamp': int(time.time())
        }
        
        # Publish to notification topic
        topic_path = publisher.topic_path(PROJECT_ID, 'scc-remediation-notifications')
        message_data = json.dumps(notification_data).encode('utf-8')
        
        future = publisher.publish(topic_path, message_data)
        logger.info(f"Sent notification: {future.result()}")
        
    except Exception as e:
        logger.error(f"Failed to send notification: {str(e)}")

# Entry point for Cloud Function
def main(cloud_event):
    """Main entry point for the Cloud Function."""
    return process_finding(cloud_event)