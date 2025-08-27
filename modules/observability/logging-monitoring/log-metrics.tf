# Enhanced Log-Based Metrics for Analysis and Alerting

# Security-focused log metrics
resource "google_logging_metric" "failed_login_attempts" {
  name   = "failed_login_attempts"
  project = var.project_id
  filter = <<-EOT
    protoPayload.serviceName="iam.googleapis.com" AND
    protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey" AND
    protoPayload.authenticationInfo.principalEmail!~".*@gserviceaccount.com" AND
    severity="ERROR"
  EOT
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    display_name = "Failed Login Attempts"
  }
  
  label_extractors = {
    "user"    = "EXTRACT(protoPayload.authenticationInfo.principalEmail)"
    "project" = "EXTRACT(resource.labels.project_id)"
  }
}

resource "google_logging_metric" "privilege_escalation_attempts" {
  name   = "privilege_escalation_attempts"
  project = var.project_id
  filter = <<-EOT
    protoPayload.serviceName="iam.googleapis.com" AND
    (protoPayload.methodName="SetIamPolicy" OR
     protoPayload.methodName="google.iam.admin.v1.CreateRole" OR
     protoPayload.methodName="google.iam.admin.v1.UpdateRole") AND
    protoPayload.request.policy.bindings.role=~".*admin.*|.*owner.*"
  EOT
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    display_name = "Privilege Escalation Attempts"
  }
  
  label_extractors = {
    "user"    = "EXTRACT(protoPayload.authenticationInfo.principalEmail)"
    "role"    = "EXTRACT(protoPayload.request.policy.bindings.role)"
    "project" = "EXTRACT(resource.labels.project_id)"
  }
}

resource "google_logging_metric" "firewall_rule_violations" {
  name   = "firewall_rule_violations"
  project = var.project_id
  filter = <<-EOT
    resource.type="gce_firewall_rule" AND
    (protoPayload.methodName="v1.compute.firewalls.insert" OR
     protoPayload.methodName="v1.compute.firewalls.patch") AND
    (protoPayload.request.allowed.ports="22" OR
     protoPayload.request.allowed.ports="3389" OR
     protoPayload.request.sourceRanges="0.0.0.0/0")
  EOT
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    display_name = "Suspicious Firewall Rule Changes"
  }
  
  label_extractors = {
    "user"    = "EXTRACT(protoPayload.authenticationInfo.principalEmail)"
    "project" = "EXTRACT(resource.labels.project_id)"
    "rule"    = "EXTRACT(protoPayload.resourceName)"
  }
}

# Network security metrics
resource "google_logging_metric" "vpc_flow_anomalies" {
  name   = "vpc_flow_anomalies"
  project = var.project_id
  filter = <<-EOT
    resource.type="vpc_flow" AND
    jsonPayload.connection.dest_port="22" AND
    jsonPayload.connection.protocol=6 AND
    NOT (jsonPayload.src_vpc.vpc_name=~".*trusted.*")
  EOT
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    display_name = "VPC Flow Anomalies"
  }
  
  label_extractors = {
    "src_ip"   = "EXTRACT(jsonPayload.connection.src_ip)"
    "dest_ip"  = "EXTRACT(jsonPayload.connection.dest_ip)"
    "project"  = "EXTRACT(resource.labels.project_id)"
  }
}

resource "google_logging_metric" "data_exfiltration_indicators" {
  name   = "data_exfiltration_indicators"
  project = var.project_id
  filter = <<-EOT
    (protoPayload.serviceName="storage.googleapis.com" AND
     protoPayload.methodName="storage.objects.get" AND
     protoPayload.request.object=~".*\\.sql$|.*\\.csv$|.*\\.json$") OR
    (resource.type="bigquery_resource" AND
     protoPayload.methodName="jobservice.jobcompleted" AND
     protoPayload.serviceData.jobCompletedEvent.job.jobConfiguration.extract)
  EOT
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    display_name = "Potential Data Exfiltration"
  }
  
  label_extractors = {
    "user"     = "EXTRACT(protoPayload.authenticationInfo.principalEmail)"
    "resource" = "EXTRACT(protoPayload.resourceName)"
    "project"  = "EXTRACT(resource.labels.project_id)"
  }
}

# Application performance metrics
resource "google_logging_metric" "application_errors" {
  name   = "application_errors"
  project = var.project_id
  filter = <<-EOT
    (resource.type="gce_instance" OR
     resource.type="k8s_container" OR
     resource.type="cloud_function" OR
     resource.type="cloud_run_revision") AND
    severity="ERROR"
  EOT
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    display_name = "Application Errors"
  }
  
  label_extractors = {
    "service"     = "EXTRACT(resource.labels.service_name)"
    "environment" = "EXTRACT(resource.labels.environment)"
    "project"     = "EXTRACT(resource.labels.project_id)"
  }
}

resource "google_logging_metric" "high_latency_requests" {
  name   = "high_latency_requests"
  project = var.project_id
  filter = <<-EOT
    resource.type="http_load_balancer" AND
    httpRequest.latency>="5s"
  EOT
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    display_name = "High Latency Requests"
  }
  
  label_extractors = {
    "backend"  = "EXTRACT(resource.labels.backend_service_name)"
    "method"   = "EXTRACT(httpRequest.requestMethod)"
    "status"   = "EXTRACT(httpRequest.status)"
  }
}

# Cost and resource utilization metrics
resource "google_logging_metric" "expensive_operations" {
  name   = "expensive_operations"
  project = var.project_id
  filter = <<-EOT
    (protoPayload.serviceName="compute.googleapis.com" AND
     protoPayload.methodName=~".*instances.insert.*" AND
     protoPayload.request.machineType=~".*n1-highmem.*|.*n1-highcpu.*") OR
    (protoPayload.serviceName="bigquery.googleapis.com" AND
     protoPayload.serviceData.jobCompletedEvent.job.jobStatistics.totalBilledBytes>1000000000)
  EOT
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    display_name = "Expensive Operations"
  }
  
  label_extractors = {
    "user"    = "EXTRACT(protoPayload.authenticationInfo.principalEmail)"
    "service" = "EXTRACT(protoPayload.serviceName)"
    "project" = "EXTRACT(resource.labels.project_id)"
  }
}

# Compliance and audit metrics
resource "google_logging_metric" "policy_violations" {
  name   = "policy_violations"
  project = var.project_id
  filter = <<-EOT
    protoPayload.serviceName="orgpolicy.googleapis.com" AND
    protoPayload.methodName="SetPolicy" AND
    severity="WARNING"
  EOT
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    display_name = "Organization Policy Violations"
  }
  
  label_extractors = {
    "user"   = "EXTRACT(protoPayload.authenticationInfo.principalEmail)"
    "policy" = "EXTRACT(protoPayload.resourceName)"
  }
}

resource "google_logging_metric" "encryption_key_usage" {
  name   = "encryption_key_usage"
  project = var.project_id
  filter = <<-EOT
    protoPayload.serviceName="cloudkms.googleapis.com" AND
    (protoPayload.methodName="Encrypt" OR
     protoPayload.methodName="Decrypt" OR
     protoPayload.methodName="CreateCryptoKeyVersion")
  EOT
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    display_name = "KMS Key Operations"
  }
  
  label_extractors = {
    "key_name" = "EXTRACT(protoPayload.resourceName)"
    "operation" = "EXTRACT(protoPayload.methodName)"
    "user"     = "EXTRACT(protoPayload.authenticationInfo.principalEmail)"
  }
}

# BigQuery views for log analysis
resource "google_bigquery_table" "security_events_view" {
  count      = var.enable_bigquery_export ? 1 : 0
  dataset_id = google_bigquery_dataset.logs[0].dataset_id
  table_id   = "security_events_view"
  project    = var.project_id
  
  view {
    query = <<-EOT
      SELECT
        timestamp,
        severity,
        protoPayload.authenticationInfo.principalEmail as user_email,
        protoPayload.serviceName as service,
        protoPayload.methodName as method,
        resource.labels.project_id as project_id,
        protoPayload.resourceName as resource_name,
        protoPayload.request as request_details
      FROM `${var.project_id}.${google_bigquery_dataset.logs[0].dataset_id}.cloudaudit_googleapis_com_*`
      WHERE
        severity IN ('WARNING', 'ERROR', 'CRITICAL') AND
        protoPayload.serviceName IN (
          'iam.googleapis.com',
          'cloudkms.googleapis.com',
          'securitycenter.googleapis.com',
          'compute.googleapis.com'
        )
      ORDER BY timestamp DESC
    EOT
    use_legacy_sql = false
  }
  
  depends_on = [google_bigquery_dataset.logs]
}

resource "google_bigquery_table" "network_analysis_view" {
  count      = var.enable_bigquery_export ? 1 : 0
  dataset_id = google_bigquery_dataset.logs[0].dataset_id
  table_id   = "network_analysis_view"
  project    = var.project_id
  
  view {
    query = <<-EOT
      SELECT
        timestamp,
        jsonPayload.connection.src_ip,
        jsonPayload.connection.dest_ip,
        jsonPayload.connection.dest_port,
        jsonPayload.connection.protocol,
        jsonPayload.bytes_sent,
        jsonPayload.packets_sent,
        resource.labels.project_id as project_id,
        resource.labels.subnetwork_name as subnet
      FROM `${var.project_id}.${google_bigquery_dataset.logs[0].dataset_id}.compute_googleapis_com_vpc_flows_*`
      WHERE
        jsonPayload.connection.dest_port IN (22, 3389, 443, 80) OR
        jsonPayload.bytes_sent > 1000000
      ORDER BY timestamp DESC
    EOT
    use_legacy_sql = false
  }
  
  depends_on = [google_bigquery_dataset.logs]
}

# Scheduled queries for automated analysis
resource "google_bigquery_data_transfer_config" "daily_security_report" {
  count                  = var.enable_bigquery_export ? 1 : 0
  display_name           = "Daily Security Report"
  project                = var.project_id
  location               = var.region
  data_source_id         = "scheduled_query"
  schedule               = "every day 08:00"
  destination_dataset_id = google_bigquery_dataset.logs[0].dataset_id
  
  params = {
    destination_table_name_template = "daily_security_summary_{run_date}"
    write_disposition               = "WRITE_TRUNCATE"
    query = <<-EOT
      SELECT
        DATE(timestamp) as report_date,
        protoPayload.serviceName as service,
        COUNT(*) as event_count,
        COUNT(DISTINCT protoPayload.authenticationInfo.principalEmail) as unique_users,
        ARRAY_AGG(DISTINCT protoPayload.methodName LIMIT 10) as top_methods
      FROM `${var.project_id}.${google_bigquery_dataset.logs[0].dataset_id}.security_events_view`
      WHERE DATE(timestamp) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
      GROUP BY report_date, service
      ORDER BY event_count DESC
    EOT
  }
  
  depends_on = [google_bigquery_table.security_events_view]
}