# Compute Instance Templates Module

Implements standardized VM deployment with instance templates, startup scripts, OS Login, Ops Agent, metadata standards, and Shielded VM settings.

## Features

- **Instance Templates**: Standardized templates for common workloads
- **Startup Scripts**: Automated software installation and configuration
- **OS Login**: Secure SSH access management
- **Ops Agent**: Monitoring and logging agent installation
- **Metadata Standards**: Consistent instance metadata
- **Shielded VM**: Enhanced security with secure boot and vTPM

## Usage

```hcl
module "instances" {
  source = "./modules/compute/instances"
  
  project_id  = var.project_id
  region      = var.region
  network     = var.network_name
  subnetwork  = var.subnet_name
  
  templates = {
    web = {
      machine_type = "e2-medium"
      image        = "ubuntu-2004-lts"
      disk_size    = 20
      tags         = ["web", "http-server"]
    }
    app = {
      machine_type = "e2-standard-2"
      image        = "ubuntu-2004-lts"
      disk_size    = 50
      tags         = ["app"]
    }
  }
  
  enable_os_login    = true
  enable_shielded_vm = true
  
  labels = {
    environment = "prod"
    team        = "platform"
  }
}
```

## Requirements

- Compute API enabled
- OS Login API enabled
- VPC network and subnetwork
- Appropriate IAM permissions

## Outputs

- `instance_templates`: Map of instance template names
- `service_account_email`: Instance service account email
- `template_self_links`: Self links of instance templates
- `startup_scripts`: Generated startup script paths