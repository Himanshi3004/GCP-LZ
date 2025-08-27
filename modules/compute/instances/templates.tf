resource "google_compute_instance_template" "templates" {
  for_each = var.templates
  
  name_prefix  = "${each.key}-template-"
  project      = var.project_id
  machine_type = each.value.machine_type
  
  disk {
    source_image = lookup(each.value, "custom_image", null) != null ? each.value.custom_image : "projects/${var.hardened_image_project}/global/images/family/${each.value.image}"
    auto_delete  = true
    boot         = true
    disk_size_gb = each.value.disk_size
    disk_type    = lookup(each.value, "disk_type", "pd-ssd")
    
    disk_encryption_key {
      kms_key_self_link = var.disk_encryption_key
    }
  }
  
  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    
    dynamic "access_config" {
      for_each = lookup(each.value, "enable_external_ip", false) ? [1] : []
      content {}
    }
  }
  
  service_account {
    email  = google_service_account.instance.email
    scopes = var.instance_scopes
  }
  
  metadata = merge({
    enable-oslogin                = var.enable_os_login ? "TRUE" : "FALSE"
    block-project-ssh-keys        = var.block_project_ssh_keys ? "TRUE" : "FALSE"
    enable-guest-attributes       = "TRUE"
    startup-script               = templatefile("${path.module}/scripts/startup-${each.key}.sh", {
      project_id = var.project_id
      environment = var.environment
    })
  }, lookup(each.value, "metadata", {}))
  
  shielded_instance_config {
    enable_secure_boot          = var.enable_shielded_vm
    enable_vtpm                 = var.enable_shielded_vm
    enable_integrity_monitoring = var.enable_shielded_vm
  }
  
  confidential_instance_config {
    enable_confidential_compute = lookup(each.value, "enable_confidential_compute", var.enable_confidential_compute)
  }
  
  tags   = concat(each.value.tags, var.default_tags)
  labels = merge(var.labels, lookup(each.value, "labels", {}))
  
  lifecycle {
    create_before_destroy = true
  }
}