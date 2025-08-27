import json
import base64
from google.cloud import resourcemanager_v1
from google.cloud import iam_v1
from google.cloud import bigquery
from google.cloud import logging
import functions_framework

# Initialize clients
resource_manager = resourcemanager_v1.ProjectsClient()
iam_client = iam_v1.IAMClient()
bq_client = bigquery.Client()
logging_client = logging.Client()

ORGANIZATION_ID = "${organization_id}"

@functions_framework.cloud_event
def validate_role(cloud_event):
    """Validates custom role permissions against least privilege principles."""
    
    # Decode the Pub/Sub message
    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode()
    message_data = json.loads(pubsub_message)
    
    action = message_data.get("action", "validate_roles")
    
    if action == "validate_roles":
        return validate_all_roles()
    elif action == "analyze_roles":
        return analyze_role_usage()
    else:
        return {"error": f"Unknown action: {action}"}

def validate_all_roles():
    """Validate all custom roles in the organization."""
    
    results = []
    
    try:
        # List all custom roles in the organization
        request = iam_v1.ListRolesRequest(
            parent=f"organizations/{ORGANIZATION_ID}",
            show_deleted=False
        )
        
        roles = iam_client.list_roles(request=request)
        
        for role in roles:
            if role.name.startswith(f"organizations/{ORGANIZATION_ID}/roles/"):
                validation_result = validate_single_role(role)
                results.append(validation_result)
                
        # Store results in BigQuery
        store_validation_results(results)
        
        return {"status": "success", "validated_roles": len(results)}
        
    except Exception as e:
        logging_client.logger("role-validator").log_struct({
            "severity": "ERROR",
            "message": f"Error validating roles: {str(e)}"
        })
        return {"error": str(e)}

def validate_single_role(role):
    """Validate a single custom role."""
    
    validation_result = {
        "role_name": role.name,
        "title": role.title,
        "permissions_count": len(role.included_permissions),
        "issues": [],
        "recommendations": [],
        "risk_score": 0
    }
    
    # Check for overly broad permissions
    broad_permissions = [
        "*.admin",
        "*.editor", 
        "*.owner",
        "resourcemanager.projects.setIamPolicy",
        "iam.serviceAccounts.actAs"
    ]
    
    for permission in role.included_permissions:
        # Check for broad permissions
        for broad in broad_permissions:
            if broad.replace("*", "") in permission or permission.endswith(".admin"):
                validation_result["issues"].append({
                    "type": "broad_permission",
                    "permission": permission,
                    "severity": "high"
                })
                validation_result["risk_score"] += 10
        
        # Check for unused permissions (would need usage data)
        # This is a placeholder for actual usage analysis
        if not is_permission_used(permission, role.name):
            validation_result["issues"].append({
                "type": "unused_permission",
                "permission": permission,
                "severity": "medium"
            })
            validation_result["risk_score"] += 5
    
    # Generate recommendations
    if validation_result["risk_score"] > 20:
        validation_result["recommendations"].append(
            "Consider splitting this role into more specific roles"
        )
    
    if len(role.included_permissions) > 20:
        validation_result["recommendations"].append(
            "Role has many permissions, review for least privilege"
        )
    
    return validation_result

def is_permission_used(permission, role_name):
    """Check if a permission is actually used (placeholder implementation)."""
    
    # This would query BigQuery for actual usage data
    # For now, return True to avoid false positives
    return True

def analyze_role_usage():
    """Analyze role usage patterns from audit logs."""
    
    try:
        # Query BigQuery for role usage patterns
        query = """
        SELECT 
            role_name,
            permission,
            COUNT(*) as usage_count,
            COUNT(DISTINCT principal) as unique_users,
            MAX(timestamp) as last_used
        FROM `{project_id}.role_analytics.role_usage`
        WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
        GROUP BY role_name, permission
        ORDER BY usage_count DESC
        """.format(project_id=bq_client.project)
        
        query_job = bq_client.query(query)
        results = query_job.result()
        
        analysis = {
            "total_permissions_analyzed": 0,
            "unused_permissions": [],
            "heavily_used_permissions": [],
            "recommendations": []
        }
        
        for row in results:
            analysis["total_permissions_analyzed"] += 1
            
            if row.usage_count == 0:
                analysis["unused_permissions"].append({
                    "role": row.role_name,
                    "permission": row.permission
                })
            elif row.usage_count > 1000:
                analysis["heavily_used_permissions"].append({
                    "role": row.role_name,
                    "permission": row.permission,
                    "usage_count": row.usage_count
                })
        
        # Generate recommendations
        if len(analysis["unused_permissions"]) > 0:
            analysis["recommendations"].append(
                f"Consider removing {len(analysis['unused_permissions'])} unused permissions"
            )
        
        # Log analysis results
        logging_client.logger("role-analyzer").log_struct({
            "severity": "INFO",
            "message": "Role usage analysis completed",
            "analysis": analysis
        })
        
        return analysis
        
    except Exception as e:
        logging_client.logger("role-analyzer").log_struct({
            "severity": "ERROR",
            "message": f"Error analyzing role usage: {str(e)}"
        })
        return {"error": str(e)}

def store_validation_results(results):
    """Store validation results in BigQuery."""
    
    try:
        table_id = f"{bq_client.project}.role_analytics.role_validation_results"
        
        rows_to_insert = []
        for result in results:
            rows_to_insert.append({
                "timestamp": bigquery.ScalarQueryParameter(None, "TIMESTAMP", "CURRENT_TIMESTAMP()"),
                "role_name": result["role_name"],
                "title": result["title"],
                "permissions_count": result["permissions_count"],
                "issues_count": len(result["issues"]),
                "risk_score": result["risk_score"],
                "issues": json.dumps(result["issues"]),
                "recommendations": json.dumps(result["recommendations"])
            })
        
        table = bq_client.get_table(table_id)
        errors = bq_client.insert_rows_json(table, rows_to_insert)
        
        if errors:
            raise Exception(f"BigQuery insert errors: {errors}")
            
    except Exception as e:
        logging_client.logger("role-validator").log_struct({
            "severity": "ERROR",
            "message": f"Error storing validation results: {str(e)}"
        })
        raise e