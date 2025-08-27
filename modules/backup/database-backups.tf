# Enhanced SQL backup configuration
resource "google_sql_database_instance" "backup_config" {
  for_each = var.sql_instances
  
  name             = each.key
  database_version = each.value.database_version
  region          = each.value.region != null ? each.value.region : var.region
  project         = var.project_id
  
  settings {
    tier = each.value.tier
    
    backup_configuration {
      enabled                        = true
      start_time                    = "02:00"
      point_in_time_recovery_enabled = true
      
      backup_retention_settings {
        retained_backups = var.backup_retention_days
        retention_unit   = "COUNT"
      }
      
      transaction_log_retention_days = 7
      location = var.enable_cross_region_backup ? var.backup_regions[0] : var.region
      
      binary_log_enabled = contains(["MYSQL_5_7", "MYSQL_8_0"], each.value.database_version)
    }
    
    # Enhanced database flags for backup optimization
    dynamic "database_flags" {
      for_each = contains(["POSTGRES_13", "POSTGRES_14", "POSTGRES_15"], each.value.database_version) ? [
        { name = "log_checkpoints", value = "on" },
        { name = "log_connections", value = "on" },
        { name = "log_disconnections", value = "on" },
        { name = "log_statement", value = "all" }
      ] : []
      
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }
    
    dynamic "database_flags" {
      for_each = contains(["MYSQL_5_7", "MYSQL_8_0"], each.value.database_version) ? [
        { name = "general_log", value = "on" },
        { name = "slow_query_log", value = "on" },
        { name = "log_output", value = "FILE" }
      ] : []
      
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }
    
    insights_config {
      query_insights_enabled  = true
      record_application_tags = true
      record_client_address   = true
    }
  }
  
  deletion_protection = true
}

# Manual backup trigger for immediate backups
resource "google_cloud_scheduler_job" "manual_sql_backup" {
  for_each = var.sql_instances
  
  name        = "${each.key}-manual-backup"
  project     = var.project_id
  region      = var.region
  description = "Manual SQL backup trigger for ${each.key}"
  schedule    = "0 0 1 1 *"  # Disabled by default
  paused      = true
  
  http_target {
    http_method = "POST"
    uri         = "https://sqladmin.googleapis.com/sql/v1beta4/projects/${var.project_id}/instances/${each.key}/backupRuns"
    
    headers = {
      "Content-Type" = "application/json"
    }
    
    body = base64encode(jsonencode({
      type = "ON_DEMAND"
    }))
    
    oauth_token {
      service_account_email = google_service_account.backup_sa.email
    }
  }
}

# SQL backup monitoring
resource "google_monitoring_alert_policy" "sql_backup_failure" {
  count = var.enable_backup_monitoring ? 1 : 0
  
  display_name = "SQL Backup Failure"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "SQL backup failed"
    
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/backup/success\""
      comparison      = "COMPARISON_EQUAL"
      threshold_value = 0
      duration        = "3600s"  # Alert if no successful backup in 1 hour
      
      aggregations {
        alignment_period   = "3600s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }
  
  notification_channels = var.backup_notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# SQL backup age monitoring
resource "google_monitoring_alert_policy" "sql_backup_age" {
  count = var.enable_backup_monitoring ? 1 : 0
  
  display_name = "SQL Backup Age Alert"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "SQL backup is too old"
    
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/backup/age\""
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = var.backup_sla_hours * 3600  # Convert hours to seconds
      duration        = "300s"
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = var.backup_notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# Cross-region SQL replica for disaster recovery
resource "google_sql_database_instance" "cross_region_replica" {
  for_each = var.enable_cross_region_backup ? var.sql_instances : {}
  
  name                 = "${each.key}-replica"
  database_version     = each.value.database_version
  region              = var.backup_regions[1]  # Secondary region
  project             = var.project_id
  master_instance_name = google_sql_database_instance.backup_config[each.key].name
  
  replica_configuration {
    failover_target = true
  }
  
  settings {
    tier = each.value.tier
    
    backup_configuration {
      enabled    = true
      start_time = "03:00"
      
      backup_retention_settings {
        retained_backups = var.backup_retention_days
        retention_unit   = "COUNT"
      }
    }
    
    availability_type = "REGIONAL"
  }
  
  deletion_protection = true
}