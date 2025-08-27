output "instance_templates" {
  description = "Map of instance template names"
  value       = { for k, v in google_compute_instance_template.templates : k => v.name }
}

output "service_account_email" {
  description = "Email of the instance service account"
  value       = google_service_account.instance.email
}

output "template_self_links" {
  description = "Self links of instance templates"
  value       = { for k, v in google_compute_instance_template.templates : k => v.self_link }
}

output "startup_scripts" {
  description = "Generated startup scripts"
  value = {
    web = local_file.startup_web.filename
    app = local_file.startup_app.filename
    db  = local_file.startup_db.filename
  }
}