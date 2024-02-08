#!/bin/bash

# Upgrade and install necessary packages
sudo DEBIAN_FRONTEND=noninteractive apt update -y
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt install -y nano git python3-pip

# Add the current user to the docker group
sudo usermod -aG docker $USER

# Don not set up a new drive
# sudo parted /dev/sda <<EOF
# print
# rm 1
# mkpart primary ext4 0GB 120GB
# mkpart primary ext4 120GB 240GB
# quit
# EOF

# Setup drive in docker
sudo mkdir -p /mnt/docker
sudo mount -t ext4 -o defaults /dev/sda1 /mnt/docker
part_uuid=$(sudo blkid -o value -s UUID /dev/sda1)

# Add entry to /etc/fstab
echo "UUID=$part_uuid /mnt/docker ext4 defaults 0" | sudo tee -a /etc/fstab

# Change ownership but do not copy docker data
sudo chown $USER:$USER -R /mnt/docker
# sudo cp -r /var/lib/docker /mnt/docker

# Configure Docker daemon
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
   "runtimes":{
      "nvidia":{
         "path":"nvidia-container-runtime",
         "runtimeArgs":[
            
         ]
      }
   },
   "default-runtime":"nvidia",
   "data-root":"/mnt/docker"
}
EOF

# Restart Docker service
sudo systemctl restart docker

# Remove old docker data
sudo rm -rf /var/lib/docker

echo "Jetson setup completed successfully. Happy coding!"
echo
echo "If this script saved you time, please consider sponsoring me: https://github.com/sponsors/jacobhq"
