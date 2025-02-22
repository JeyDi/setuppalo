variable "environment_name" {
  description = "Name of the environment (dev, staging, prod)"
  type        = string
}

variable "project_id" {
  description = "ID of the main project"
  type        = string
}

variable "common_config" {
  description = "Common configuration for all environments"
  type = object({
    region         = string
    admin_username = string
    root_password  = string
    ssh_public_key = string
    volume_size    = number
  })
  sensitive = true
}

variable "env_config" {
  description = "Environment-specific configuration"
  type = object({
    description = string
    machines    = map(object({
      size        = string
      volume_size = number
      floating_ip = bool
      backups     = bool
      monitoring  = bool
      volume_backup = bool
    }))
  })
}