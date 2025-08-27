output "projects" {
  description = "Created projects with their details"
  value = {
    for k, v in google_project.projects : k => {
      project_id     = v.project_id
      project_number = v.number
      name           = v.name
      folder_id      = v.folder_id
      labels         = v.labels
    }
  }
}

output "service_accounts" {
  description = "Service accounts created for projects"
  value = {
    for k, v in google_service_account.project_sa : k => {
      email        = v.email
      unique_id    = v.unique_id
      display_name = v.display_name
    }
  }
  sensitive = true
}

output "budgets" {
  description = "Budget configurations"
  value = {
    for k, v in google_billing_budget.project_budgets : k => {
      name         = v.display_name
      amount       = v.amount[0].specified_amount[0].units
      thresholds   = [for rule in v.threshold_rules : rule.threshold_percent]
    }
  }
}

output "forecast_budgets" {
  description = "Forecast budget configurations"
  value = var.enable_forecast_alerts ? {
    for k, v in google_billing_budget.forecast_budgets : k => {
      name         = v.display_name
      amount       = v.amount[0].specified_amount[0].units
      threshold    = v.threshold_rules[0].threshold_percent
    }
  } : {}
}

output "project_types" {
  description = "Project type configurations used"
  value = {
    for k, v in var.projects : k => {
      type_config = local.project_types[k]
      department  = v.department
    }
  }
}

output "essential_contacts" {
  description = "Essential contacts configured for projects"
  value = {
    for k, v in google_essential_contacts_contact.project_contacts : k => {
      project = v.parent
      email   = v.email
    }
  }
  sensitive = true
}

output "project_liens" {
  description = "Project liens for deletion protection"
  value = {
    for k, v in google_resource_manager_lien.project_liens : k => {
      project      = v.parent
      restrictions = v.restrictions
      reason       = v.reason
    }
  }
}