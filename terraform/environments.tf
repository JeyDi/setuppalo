locals {
  # Common configuration for all environments
  common = {
    region         = "ams3"
    admin_username = var.admin_username
    root_password  = var.root_password
    ssh_public_key = file(var.ssh_key_path)
    volume_size    = 10
  }

  # Environment-specific configurations
  environments = {
    development = {
      description = "Development Environment"
      machines = {
        dev-main = {
          size        = "s-1vcpu-1gb"
          volume_size = 60
          floating_ip = true
          backups     = true
          monitoring  = true
          volume_backup = true
        }
        }
      }
    }
}