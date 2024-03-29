#!/bin/bash

# Function to display usage information
usage() {
  echo "Usage: $0 [--dry-run] [public_key]"
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
      public_key="$1"
      shift
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

# Update package list and install OpenSSH server
run_command "sudo apt update && sudo apt install openssh-server"

# Set up ssh
run_command "mkdir -p ~/.ssh"

if [ -z "$public_key" ]; then
  read -p "Enter your public key to authorize (it is not transmitted anywhere, go read the code): " public_key
fi

run_command "echo \"$public_key\" >> ~/.ssh/authorized_keys"

# Restrict permissions on the SSH directory
run_command "chmod -R go= ~/.ssh"
run_command "chown -R $USER:$USER ~/.ssh"
run_command "sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config"
run_command "sudo systemctl restart ssh"

echo "SSH setup completed successfully! To finish setting up your Jetson, disconnect from serial and connect back in over the network. Now run:"
echo
echo "wget -O - https://raw.githubusercontent.com/jacobhq/jetson-setup/main/scripts/2-setup-docker.sh | bash"
echo
echo "To set up Docker on an external drive. For more details, see the repo: https://github.com/jacobhq/jetson-setup"
echo "If this script saved you time, please consider sponsoring me: https://github.com/sponsors/jacobhq"
