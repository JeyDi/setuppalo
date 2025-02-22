output "droplet_ip" {
  description = "The public IP of the droplet"
  value       = digitalocean_droplet.web.ipv4_address
}

output "droplet_id" {
  description = "The ID of the droplet"
  value       = digitalocean_droplet.web.id
}

output "volume_id" {
  description = "The ID of the attached volume"
  value       = digitalocean_volume.storage.id
}