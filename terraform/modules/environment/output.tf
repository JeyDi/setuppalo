output "machine_ips" {
  description = "The IPs of all machines in this environment"
  value = {
    for name, machine in digitalocean_droplet.machines : name => {
      main_ip     = machine.ipv4_address
      floating_ip = try(digitalocean_floating_ip.floating_ips[name].ip_address, null)
    }
  }
}