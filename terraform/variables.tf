variable "do_token" {
  description = "Digital Ocean API token"
  type        = string
  sensitive   = true
}

variable "admin_username" {
  description = "Admin username for all droplets"
  type        = string
  sensitive   = true
}

variable "root_password" {
  description = "Root password for all droplets"
  type        = string
  sensitive   = true
}

variable "ssh_key_path" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "../ssh_keys/server.pub"
}

variable "project_name" {
  description = "Name of the Digital Ocean project"
  type        = string
  default     = "Personal"
}

variable "project_description" {
  description = "Description of the Digital Ocean project"
  type        = string
  default     = "Personal project"
}

variable "project_purpose" {
  description = "Purpose of the Digital Ocean project"
  type        = string
  default     = "Web Application"
}

variable "project_environment" {
  description = "Digital ocean project environment description"
  type        = string
  default     = "Development"
  validation {
    condition     = contains(["Development", "Staging", "Production"], var.project_environment)
    error_message = "Environment must be one of: Development, Staging, Production."
  }
}

# variable "do_token" {
#   description = "Digital Ocean API token"
#   type        = string
#   sensitive   = true
# }

# variable "admin_username" {
#   description = "Admin username for the droplet"
#   type        = string
#   sensitive   = true
# }

# variable "root_password" {
#   description = "Root user password"
#   type        = string
#   sensitive   = true
# }

# variable "project_name" {
#   description = "Name of the Digital Ocean project"
#   type        = string
#   default     = "Personal"
# }

# variable "project_description" {
#   description = "Description of the Digital Ocean project"
#   type        = string
#   default     = "Managed by Terraform"
# }

# variable "project_environment" {
#   description = "Environment of the project"
#   type        = string
#   default     = "Development"
#   validation {
#     condition     = contains(["Development", "Staging", "Production"], var.project_environment)
#     error_message = "Environment must be one of: Development, Staging, Production."
#   }
# }