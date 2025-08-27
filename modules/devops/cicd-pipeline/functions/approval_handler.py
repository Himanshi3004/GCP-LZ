import json
import base64
import logging
from google.cloud import clouddeploy_v1
from google.cloud import pubsub_v1

def handle_approval(event, context):
    """
    Cloud Function to handle deployment approval requests.
    Triggered by Pub/Sub messages from approval requests topic.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)
    
    try:
        # Decode the Pub/Sub message
        if 'data' in event:
            message_data = base64.b64decode(event['data']).decode('utf-8')
            approval_request = json.loads(message_data)
        else:
            logger.error("No data in event")
            return
        
        # Extract approval request details
        project_id = approval_request.get('project_id')
        location = approval_request.get('location')
        delivery_pipeline = approval_request.get('delivery_pipeline')
        release_name = approval_request.get('release_name')
        rollout_id = approval_request.get('rollout_id')
        approver_email = approval_request.get('approver_email')
        action = approval_request.get('action', 'approve')  # approve or reject
        
        if not all([project_id, location, delivery_pipeline, release_name, rollout_id]):
            logger.error("Missing required fields in approval request")
            return
        
        # Initialize Cloud Deploy client
        client = clouddeploy_v1.CloudDeployClient()
        
        # Construct the rollout name
        rollout_name = f"projects/{project_id}/locations/{location}/deliveryPipelines/{delivery_pipeline}/releases/{release_name}/rollouts/{rollout_id}"
        
        if action == 'approve':
            # Approve the rollout
            request = clouddeploy_v1.ApproveRolloutRequest(
                name=rollout_name,
                approved=True
            )
            
            operation = client.approve_rollout(request=request)
            logger.info(f"Approved rollout {rollout_id} by {approver_email}")
            
            # Publish approval event
            publish_event({
                'event_type': 'approval_granted',
                'rollout_id': rollout_id,
                'approver': approver_email,
                'timestamp': context.timestamp
            })
            
        elif action == 'reject':
            # Reject the rollout
            request = clouddeploy_v1.ApproveRolloutRequest(
                name=rollout_name,
                approved=False
            )
            
            operation = client.approve_rollout(request=request)
            logger.info(f"Rejected rollout {rollout_id} by {approver_email}")
            
            # Publish rejection event
            publish_event({
                'event_type': 'approval_rejected',
                'rollout_id': rollout_id,
                'approver': approver_email,
                'timestamp': context.timestamp
            })
        
        else:
            logger.error(f"Unknown action: {action}")
            return
            
    except Exception as e:
        logger.error(f"Error processing approval request: {str(e)}")
        raise

def publish_event(event_data):
    """Publish deployment event to Pub/Sub topic"""
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(
        event_data.get('project_id', 'default-project'),
        'deployment-events'
    )
    
    message_data = json.dumps(event_data).encode('utf-8')
    future = publisher.publish(topic_path, message_data)
    future.result()  # Wait for publish to complete