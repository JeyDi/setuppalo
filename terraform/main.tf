terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "digitalocean" {
  token = var.do_token
}

# Try to get existing project
data "digitalocean_projects" "all" {}

locals {
  existing_project = [
    for project in data.digitalocean_projects.all.projects :
    project if project.name == var.project_name
  ]
  project_exists = length(local.existing_project) > 0
  project_id     = local.project_exists ? local.existing_project[0].id : digitalocean_project.main_project[0].id
}

# Create new project only if the data source fails
resource "digitalocean_project" "main_project" {
    count       = local.project_exists ? 0 : 1
    name        = var.project_name
    description = var.project_description
    purpose     = var.project_purpose
    environment = var.project_environment
}

# Create environments
module "environments" {
  for_each = local.environments
  source   = "./modules/environment"

  environment_name = each.key
  project_id      = local.project_id  # Use the determined project ID
  common_config   = local.common
  env_config      = each.value
}

# # Create Project
# resource "digitalocean_project" "project" {
#   name        = var.project_name
#   description = var.project_description
#   purpose     = "Web Application"
#   environment = var.project_environment
# }

# module "environments" {
#   for_each = local.environments
#   source   = "./modules/environment"

#   environment_name = each.key
#   common_config   = local.common
#   env_config      = each.value
# }

# module "droplet" {
#   source = "./modules/droplet"
#   region        = "ams3"
#   droplet_name  = "test-server"
#   admin_username = var.admin_username
#   root_password = var.root_password
#   ssh_public_key = file("../ssh_keys/server.pub")
#   project_id    = digitalocean_project.project.id
# }