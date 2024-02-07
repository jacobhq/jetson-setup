# Setting up your Jetson Nano
I've found myself having to setup my Jetson relatively frequently, so I compiled a list of steps I use.

## Step by step
1. Download and flash Jetson Linux using Balena Etcher[^1]. Use flash from URL button:
  
   ```
   https://developer.nvidia.com/jetson-nano-sd-card-image
   ```
2. Insert SD card into Jetson module (below heatsink)
3. Bridge **pin J48** (located between power port and HDMI+DP ports)[^2].
4. Plug in your Jetson using a [5V 4A DC powersupply](https://www.amazon.co.uk/gp/product/B0BGC3F6QS?ref=ppx_pt2_dt_b_prod_image), and allow to boot.
5. Plug the Jetson into your computer via the micro USB, and locate COM port using Device Manager > Ports (COM and LPT).
6. Use PuTTY (connection type: serial) to ssh into the COM port you found, with a speed of `115200`.
7. Configure your Jetson in the terminal window
8. Before you do anything, you want to unplug yourself, so enable SSH asap:

   ```
   sudo apt update && sudo apt install openssh-server
   ```
9. Use SSH public key authentication, where `public_key_string` is your SSH **public** key, and `jacob` is your username[^4]:
   ```
   mkdir -p ~/.ssh
   ```
   ```
   echo public_key_string >> ~/.ssh/authorized_keys
   ```
   ```
   chmod -R go= ~/.ssh
   ```
   ```
   chown -R jacob:jacob ~/.ssh
   ```
10. [Optional] Diable password auth[^5]:
    ```
    sudo nano /etc/ssh/sshd_config
    ```
    Change `PasswordAuthentication` from `yes` to `no`, and restart SSH.
    ```
    PasswordAuthentication no
    ```
    ```
    sudo systemctl restart ssh
    ```
11. Disconnect from serial with `Ctrl+D` or the `logout` command, and unplug your computer from your Jetson
12. SSH in over the network, where `jetson` is the hostname, and `jacob` is the usernaame. eg:
    ```
    ssh jacob@jetson.local
    ```
    or, if your username on your jetson is the same as your computer:
    ```
    ssh jetson.local
    ```
13. Now update your Jetson (takes about 10-15min), and install nice-to-haves (git and python3-pip are needed for [jetson-containers](#continuation-set-up-jetson-containers-docker-with-external-drive-wip)):
    ```
    sudo apt upgrade && sudo apt install nano git python3-pip
    ```
Congrats, your jetson is ready to use!

## Continuation: set up jetson-containers, docker with external drive [WIP]
SD cards are very slow, use an external SSD instead!

1. Plug in an SSD (all data on it will be ereased)
2. [Optional] Run `lsblk` to find your drive if you don't already know it
3. Assuming no other drives are plugged in, run, where `a` is your drive:
   ```
   sudo parted /dev/sda
   ```
4. In the resulting shell, erease the disk, remove each partition with rm, where 1 is the partition number:
   ```
   print
   ```
   ```
   rm 1
   ```
   ```
   quit
   ```
5. Create two partitions (I like to split the disk in half, half for docker, half for models):
   ```
   sudo parted /dev/sda
   ```
   ```
   mkpart primary ext4 0GB 120GB
   ```
   ```
   mkpart primary ext4 120GB 240GB
   ```
   ```
   quit
   ```
7. Now mount your partitions 

[^1]: See NVIDIA's [official getting started guide](https://developer.nvidia.com/embedded/learn/get-started-jetson-nano-devkit#write)
[^2]: Instructions from NVIDIA's [setup in headless mode](https://developer.nvidia.com/embedded/learn/get-started-jetson-nano-devkit#setup)
[^3]: See Linuxize's [How to Enable SSH on Ubuntu 18.04](https://linuxize.com/post/how-to-enable-ssh-on-ubuntu-18-04/)
[^4]: See DigitalOcean's [How to Set Up SSH Keys on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-1804)
[^5]: Again, see DigitalOcean's [How to Set Up SSH Keys on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-1804)
