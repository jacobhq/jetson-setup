#!/bin/bash

# Function to display usage information
usage() {
  echo "Usage: $0 [--dry-run] <public_key> <private_key>"
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

if [ "$#" -ne 2 ]; then
  usage
fi

public_key="$1"
private_key="$2"

echo "This script sets up an existing SSH key on the device. It *does not* share or transmit your keys."

run_command 'mkdir -p ~/.ssh'
run_command "echo \"$public_key\" > ~/.ssh/id_ed25519.pub"
run_command "echo \"$private_key\" > ~/.ssh/id_ed25519"

# Set correct permissions on the SSH directory and files
run_command 'chmod 700 ~/.ssh'
run_command 'chmod 600 ~/.ssh/id_ed25519'
run_command 'chmod 644 ~/.ssh/id_ed25519.pub'

echo "SSH keys setup completed successfully!"
echo "If this script saved you time, please consider sponsoring me: https://github.com/sponsors/jacobhq"
