# Setting up your Jetson Nano
I've found myself having to setup my Jetson relatively frequently, so I compiled a list of steps I use.

## Use the scripts
These scripts assume and have an external drive plugged in at `/dev/sda` with an existing docker cache on partition `/dev/sda1`. These scripts:
- **do not** transmit telementary or collect any data
- **do not** touch your SSH config
- **do not** adjust partitions on your external drive
- **do** add the public key you specify to `~/.ssh/authorized_keys`
- **do** edit your `/etc/fstab` to mount your drive on boot
- **do** DELETE `/var/lib/docker`, and edits docker config to point to external drive

I encourage you to read [`scripts/1-setup-ssh.sh`](https://github.com/jacobhq/jetson-setup/blob/main/scripts/1-setup-ssh.sh) and [`scripts/2-setup-docker.sh`](https://github.com/jacobhq/jetson-setup/blob/main/scripts/2-setup-docker.sh) before you run them, or do a dry run first, so you understand _exactly_ what they do!

<details>
  <summary>
    <b>Dry run</b>
  </summary>
  
  ```
  wget -qO- https://raw.githubusercontent.com/jacobhq/jetson-setup/main/scripts/1-setup-ssh.sh | bash -s -- --dry-run
  ```
  
  ```
  wget -qO- https://raw.githubusercontent.com/jacobhq/jetson-setup/main/scripts/2-setup-docker.sh | bash -s -- --dry-run
  ```

</details>

Run the first script in the serial console:
```
wget -qO- https://raw.githubusercontent.com/jacobhq/jetson-setup/main/scripts/1-setup-ssh.sh | bash
```

Then disconnect from the serial console, and connect via SSH over the network before you run the second script:
```
wget -qO- https://raw.githubusercontent.com/jacobhq/jetson-setup/main/scripts/2-setup-docker.sh | bash
```

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
12. SSH in over the network, where `jetson` is the hostname, and `jacob` is the username. eg:
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

1. Add yourself to the `docker` group:
   ```
   sudo usermod -aG docker $USER
   ```
2. Plug in an SSD (all data on it will be ereased)
3. [Optional] Run `lsblk` to find your drive if you don't already know it
4. Assuming no other drives are plugged in, run, where `a` is your drive:
   ```
   sudo parted /dev/sda
   ```
5. In the resulting shell, erease the disk, remove each partition with rm, where 1 is the partition number:
   ```
   print
   ```
   ```
   rm 1
   ```
   ```
   quit
   ```
6. Create two partitions (I like to split the disk in half, half for docker, half for models):
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
7. Now sort out docker:
   
    1. Create docker directory:
       ```
       sudo mkdir -p /mnt/docker
       ```
    2. Mount partition[^6]:
       ```
       sudo mount -t ext4 -o defaults /dev/sda1 /mnt/docker
       ```
    3. Find out UUID of partition `/dev/sda1`:
       ```
       sudo blkid -o list
       ```
    4. Edit `/etc/fstab` to mount on boot, where `part_uuid` is the UUID of your partition from step 3:
       ```
       sudo nano /etc/fstab
       ```
       Add a new line with this:
       ```
       UUID=part_uuid /mnt/docker ext4 defaults 0
       ```
    6. Set permissions (docker will change these but whatevs):
       ```
       sudo chown jacob:jacob -R /mnt/docker
       ```
    7. Copy the existing Docker cache from `/var/lib/docker` to `/mnt/docker`[^7]:
       ```
       sudo cp -r /var/lib/docker /mnt/docker
       ```
    8. Edit `/etc/docker/daemon.json`:
       ```
       sudo nano /etc/docker/daemon.json
       ```
       To look like this:
       ```json
       {
         "runtimes": {
           "nvidia": {
             "path": "nvidia-container-runtime",
             "runtimeArgs": []
          }
        },
        "default-runtime": "nvidia",
        "data-root": "/mnt/docker"
       }
       ```
    10. Restart docker:
        ```
        sudo systemctl restart docker
        ```
    11. Check it worked:
        ```
        sudo docker info | grep 'Docker Root Dir'
        ```
        You should sse `Docker Root Dir: /mnt/docker`
        
    13. Delete `/var/lib/docker`
        ```
        sudo rm -rf /var/lib/docker
        ```
  8. Over half way there! Now let's sort out the `data` directory used by `jetson-containers`:

## Closing notes
I worked hard to collate and perfect this process - if it helped you, please consider [sponsoring me]() through GitHub Sponsors! Or, just star the repo to help with my morale!

<br />

[^1]: See NVIDIA's [official getting started guide](https://developer.nvidia.com/embedded/learn/get-started-jetson-nano-devkit#write)
[^2]: Instructions from NVIDIA's [setup in headless mode](https://developer.nvidia.com/embedded/learn/get-started-jetson-nano-devkit#setup)
[^3]: See Linuxize's [How to Enable SSH on Ubuntu 18.04](https://linuxize.com/post/how-to-enable-ssh-on-ubuntu-18-04/)
[^4]: See DigitalOcean's [How to Set Up SSH Keys on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-1804)
[^5]: Again, see DigitalOcean's [How to Set Up SSH Keys on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-1804)
[^6]: See Gordon Lesti's [Mount ext4 USB flash drive to Raspberry Pi](https://gordonlesti.com/mount-ext4-usb-flash-drive-to-raspberry-pi/)
[^7]: See @dusty-nv's [jetson-containers' `setup.md`](https://github.com/dusty-nv/jetson-containers/blob/master/docs/setup.md#relocating-docker-data-root)
[^8]: Again, see Gordon Lesti's [Mount ext4 USB flash drive to Raspberry Pi](https://gordonlesti.com/mount-ext4-usb-flash-drive-to-raspberry-pi/)
