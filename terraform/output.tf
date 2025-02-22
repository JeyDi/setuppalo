output "project_details" {
  description = "Details of the project and all environments"
  value = {
    project_id   = local.project_id
    project_name = var.project_name
    environments = {
      for env, details in module.environments : env => {
        machines = details.machine_ips
      }
    }
  }
  sensitive = true
}