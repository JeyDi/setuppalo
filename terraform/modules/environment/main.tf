# Get all existing SSH keys
data "digitalocean_ssh_keys" "existing" {}

locals {
  # Find existing SSH key by public key content
  ssh_key_exists = [
    for key in data.digitalocean_ssh_keys.existing.ssh_keys :
    key.id if key.public_key == var.common_config.ssh_public_key
  ]
  # Use existing key ID or create new one
  ssh_key_id = length(local.ssh_key_exists) > 0 ? local.ssh_key_exists[0] : digitalocean_ssh_key.env_key[0].id
}

# Create SSH Key only if it doesn't exist
resource "digitalocean_ssh_key" "env_key" {
  count      = length(local.ssh_key_exists) > 0 ? 0 : 1
  name       = "${var.environment_name}-key"
  public_key = var.common_config.ssh_public_key
}

# Create Volumes
resource "digitalocean_volume" "volumes" {
  for_each = var.env_config.machines

  region                  = var.common_config.region
  name                    = "${each.key}-volume"
  size                    = each.value.volume_size
  initial_filesystem_type = "ext4"
  description            = "Block storage for ${each.key}"
}

# Create Droplets
resource "digitalocean_droplet" "machines" {
  for_each = var.env_config.machines

  image      = "ubuntu-22-04-x64"
  name       = each.key
  region     = var.common_config.region
  size       = each.value.size
  backups    = each.value.backups 
  monitoring = each.value.monitoring
  ssh_keys   = [local.ssh_key_id]
  tags       = ["terraform-managed", "environment-${var.environment_name}"]

  user_data = <<-EOF
              #!/bin/bash
              
              # Set root password
              echo "root:${var.common_config.root_password}" | chpasswd

              # Create admin user
              useradd -m -s /bin/bash ${var.common_config.admin_username}
              echo "${var.common_config.admin_username}:${var.common_config.root_password}" | chpasswd
              usermod -aG sudo ${var.common_config.admin_username}

              # Set up SSH configuration
              sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
              sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
              
              # Create SSH directory for admin user
              mkdir -p /home/${var.common_config.admin_username}/.ssh
              cp /root/.ssh/authorized_keys /home/${var.common_config.admin_username}/.ssh/
              chown -R ${var.common_config.admin_username}:${var.common_config.admin_username} /home/${var.common_config.admin_username}/.ssh
              chmod 700 /home/${var.common_config.admin_username}/.ssh
              chmod 600 /home/${var.common_config.admin_username}/.ssh/authorized_keys

              # Restart SSH service
              systemctl restart sshd

              # Create volume management script
              cat << 'SCRIPT' > /usr/local/bin/manage-data-volume.sh
              #!/bin/bash

              VOLUME_ID="scsi-0DO_Volume_${each.key}-volume"
              MOUNT_POINT="/data"
              DEVICE_PATH="/dev/disk/by-id/$VOLUME_ID"

              # Function to wait for volume
              wait_for_volume() {
                echo "Waiting for volume to become available..."
                for i in {1..30}; do
                  if [ -e "$DEVICE_PATH" ]; then
                    echo "Volume is available"
                    return 0
                  fi
                  echo "Waiting... ($i/30)"
                  sleep 2
                done
                echo "Volume not found after 60 seconds"
                return 1
              }

              # Function to mount volume
              mount_volume() {
                echo "Creating data directory..."
                mkdir -p $MOUNT_POINT

                # Check if volume is already mounted
                if mountpoint -q $MOUNT_POINT; then
                  echo "Volume is already mounted at /data"
                  return 0
                fi

                echo "Mounting volume to /data..."
                mount -o discard,defaults,noatime $DEVICE_PATH $MOUNT_POINT
                
                if [ $? -eq 0 ]; then
                  echo "Volume mounted successfully"
                  # Add to fstab if not already there
                  if ! grep -q "$DEVICE_PATH" /etc/fstab; then
                    echo "$DEVICE_PATH $MOUNT_POINT ext4 defaults,nofail,discard 0 0" | tee -a /etc/fstab
                  fi
                else
                  echo "Failed to mount volume"
                  return 1
                fi
              }

              # Function to resize filesystem
              resize_filesystem() {
                echo "Checking if resize is needed..."
                
                # Get device and filesystem size
                DEVICE_SIZE=$(blockdev --getsize64 $DEVICE_PATH)
                FS_SIZE=$(df -B1 --output=size $MOUNT_POINT | tail -n1)
                
                if [ $DEVICE_SIZE -gt $FS_SIZE ]; then
                  echo "Resizing filesystem..."
                  resize2fs $DEVICE_PATH
                  if [ $? -eq 0 ]; then
                    echo "Filesystem resized successfully"
                  else
                    echo "Failed to resize filesystem"
                    return 1
                  fi
                else
                  echo "Filesystem resize not needed"
                fi
              }

              # Function to setup data directory structure
              setup_data_directory() {
                echo "Setting up data directory structure..."
                
                # Create common subdirectories
                mkdir -p $MOUNT_POINT/backups
                mkdir -p $MOUNT_POINT/logs
                mkdir -p $MOUNT_POINT/config
                mkdir -p $MOUNT_POINT/storage
                
                # Set ownership and permissions
                chown -R ${var.common_config.admin_username}:${var.common_config.admin_username} $MOUNT_POINT
                chmod 755 $MOUNT_POINT
                
                echo "Data directory structure setup complete"
              }

              # Main execution
              wait_for_volume || exit 1
              mount_volume || exit 1
              resize_filesystem || exit 1
              setup_data_directory || exit 1
              SCRIPT

              # Make the script executable
              chmod +x /usr/local/bin/manage-data-volume.sh

              # Run the script
              /usr/local/bin/manage-data-volume.sh

              # Create a systemd service
              cat << 'SERVICE' > /etc/systemd/system/data-volume.service
              [Unit]
              Description=Mount and manage data volume
              After=cloud-init.service
              
              [Service]
              Type=oneshot
              ExecStart=/usr/local/bin/manage-data-volume.sh
              RemainAfterExit=yes
              
              [Install]
              WantedBy=multi-user.target
              SERVICE

              # Enable and start the service
              systemctl enable data-volume.service
              EOF
}

# Assign Floating IPs to machines
resource "digitalocean_floating_ip_assignment" "floating_ip_assignments" {
  for_each = {
    for name, machine in var.env_config.machines : name => machine
    if machine.floating_ip
  }

  ip_address = digitalocean_floating_ip.floating_ips[each.key].ip_address
  droplet_id = digitalocean_droplet.machines[each.key].id
}

# Create Floating IPs for machines that need them
resource "digitalocean_floating_ip" "floating_ips" {
  for_each = {
    for name, machine in var.env_config.machines : name => machine
    if machine.floating_ip
  }

  region = var.common_config.region
}

# Attach Volumes to Droplets
resource "digitalocean_volume_attachment" "attachments" {
  for_each = var.env_config.machines

  droplet_id = digitalocean_droplet.machines[each.key].id
  volume_id  = digitalocean_volume.volumes[each.key].id
}

# Add resources to the main project
resource "digitalocean_project_resources" "resources" {
  project = var.project_id
  
  resources = concat(
    [for machine in digitalocean_droplet.machines : machine.urn],
    [for volume in digitalocean_volume.volumes : volume.urn],
    [for ip in digitalocean_floating_ip.floating_ips : ip.urn]
  )
}

