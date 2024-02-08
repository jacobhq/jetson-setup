##!/bin/bash

# Function to display usage information
usage() {
  echo "Usage: $0 [--dry-run]"
  exit 1
}

# Default values
dry_run=false

# Parse command line options
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run )
      dry_run=true
      ;;
    * )
      usage
      ;;
  esac
  shift
done

# Function to run commands
run_command() {
  if [ "$dry_run" = true ]; then
    echo "[Dry Run] $1"
  else
    eval "$1"
  fi
}

# Upgrade and install necessary packages
run_command "sudo DEBIAN_FRONTEND=noninteractive apt update -y"
run_command "sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y"
run_command "sudo DEBIAN_FRONTEND=noninteractive apt install -y nano git python3-pip"

# Add the current user to the docker group
run_command "sudo usermod -aG docker $USER"

# Uncomment the following section for drive setup
# run_command "sudo parted /dev/sda <<EOF"
# run_command "print"
# run_command "rm 1"
# run_command "mkpart primary ext4 0GB 120GB"
# run_command "mkpart primary ext4 120GB 240GB"
# run_command "quit"
# run_command "EOF"

# Setup drive in docker
run_command "sudo mkdir -p /mnt/docker"
run_command "sudo mount -t ext4 -o defaults /dev/sda1 /mnt/docker"
part_uuid=$(run_command "sudo blkid -o value -s UUID /dev/sda1")

# Add entry to /etc/fstab
run_command "echo 'UUID=$part_uuid /mnt/docker ext4 defaults 0' | sudo tee -a /etc/fstab"

# Change ownership but do not copy docker data
run_command "sudo chown $USER:$USER -R /mnt/docker"
# Uncomment the following line for copying docker data
# run_command "sudo cp -r /var/lib/docker /mnt/docker"

# Configure Docker daemon
run_command "sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
   \"runtimes\":{
      \"nvidia\":{
         \"path\":\"nvidia-container-runtime\",
         \"runtimeArgs\":[
            
         ]
      }
   },
   \"default-runtime\":\"nvidia\",
   \"data-root\":\"/mnt/docker\"
}
EOF"

# Restart Docker service
run_command "sudo systemctl restart docker"

# Remove old docker data
run_command "sudo rm -rf /var/lib/docker"

echo "Jetson setup completed successfully. Happy coding!"
echo
echo "If this script saved you time, please consider sponsoring me: https://github.com/sponsors/jacobhq"
