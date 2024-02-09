#!/bin/bash

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

echo "This script sets up an existing SSH key on device. It *does not* share or transmit your keys."

# Prompt user for SSH key type
# read -p "Enter SSH key type (e.g., rsa, ecdsa, ed25519): " key_type
read -p "Enter your SSH public key: " public_key
read -p "Enter your SSH private key: " private_key

run_command 'mkdir -p ~/.ssh'
run_command "echo '$public_key' >> ~/.ssh/id_ed25519.pub"
run_command "echo '$private_key' > ~/.ssh/id_ed25519"

# Set correct permissions on the SSH directory and files
run_command 'chmod 700 ~/.ssh'
run_command 'chmod 600 ~/.ssh/id_ed25519'
run_command 'chmod 644 ~/.ssh/id_ed25519.pub'

echo "SSH keys setup completed successfully!"
echo "If this script saved you time, please consider sponsoring me: https://github.com/sponsors/jacobhq"
