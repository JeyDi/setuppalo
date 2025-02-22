resource "digitalocean_ssh_key" "default" {
  name       = "${var.droplet_name}-key"
  public_key = var.ssh_public_key
}

# Create Droplet
resource "digitalocean_droplet" "web" {
  image      = "ubuntu-22-04-x64"
  name       = var.droplet_name
  region     = var.region
  size       = "s-1vcpu-1gb"
  backups    = true
  monitoring = true
  ssh_keys   = [digitalocean_ssh_key.default.fingerprint]

  user_data = <<-EOF
              #!/bin/bash
              # Set root password
              echo "root:${var.root_password}" | chpasswd

              # Create admin user
              useradd -m -s /bin/bash ${var.admin_username}
              echo "${var.admin_username}:${var.root_password}" | chpasswd
              usermod -aG sudo ${var.admin_username}

              # Set up SSH configuration
              sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
              sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
              
              # Create SSH directory for admin user
              mkdir -p /home/${var.admin_username}/.ssh
              cp /root/.ssh/authorized_keys /home/${var.admin_username}/.ssh/
              chown -R ${var.admin_username}:${var.admin_username} /home/${var.admin_username}/.ssh
              chmod 700 /home/${var.admin_username}/.ssh
              chmod 600 /home/${var.admin_username}/.ssh/authorized_keys

              # Restart SSH service
              systemctl restart sshd
              EOF
}

# Create Volume
resource "digitalocean_volume" "storage" {
  region                  = var.region
  name                    = "${var.droplet_name}-volume"
  size                    = 10
  initial_filesystem_type = "ext4"
  description            = "Block storage for ${var.droplet_name}"
}

# Attach Volume to Droplet
resource "digitalocean_volume_attachment" "storage" {
  droplet_id = digitalocean_droplet.web.id
  volume_id  = digitalocean_volume.storage.id
}

# Add resources to project
resource "digitalocean_project_resources" "project_resources" {
  project = var.project_id
  resources = [
    digitalocean_droplet.web.urn,
    digitalocean_volume.storage.urn
  ]
}