resource "local_file" "startup_web" {
  filename = "${path.module}/scripts/startup-web.sh"
  content = templatefile("${path.module}/templates/startup-web.tpl", {
    project_id = var.project_id
  })
}

resource "local_file" "startup_app" {
  filename = "${path.module}/scripts/startup-app.sh"
  content = templatefile("${path.module}/templates/startup-app.tpl", {
    project_id = var.project_id
  })
}

resource "local_file" "startup_db" {
  filename = "${path.module}/scripts/startup-db.sh"
  content = templatefile("${path.module}/templates/startup-db.tpl", {
    project_id = var.project_id
  })
}