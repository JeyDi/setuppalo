variable "region" {
  description = "Digital Ocean region"
  type        = string
}

variable "droplet_name" {
  description = "Name of the droplet"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the droplet"
  type        = string
}

variable "root_password" {
  description = "Root user password"
  type        = string
}

variable "ssh_public_key" {
  description = "Content of the SSH public key"
  type        = string
}

variable "project_id" {
  description = "ID of the Digital Ocean project"
  type        = string
}