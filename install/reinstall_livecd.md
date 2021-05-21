# Reinstall LiveCD

Setup a re-install of LiveCD on a node using the previous configuration.

1. Backup to the data partition:

    ```bash
    pit# mkdir -pv /var/www/ephemeral/backup
    pit# pushd /var/www/ephemeral/backup
    pit# tar -czvf "dnsmasq-data-$(date  '+%Y-%m-%d_%H-%M-%S').tar.gz" /etc/dnsmasq.*
    pit# tar -czvf "network-data-$(date  '+%Y-%m-%d_%H-%M-%S').tar.gz" /etc/sysconfig/network/*
    pit# cp -pv /etc/hosts ./
    pit# popd
    pit# umount /var/www/ephemeral
    ``` 

1. Unplug the USB device.

   The USB device should now contain all the information already loaded, as well as the backups of
   the initialized files.

1. Plug the device into a new machine, or make a backup on the booted NCN. Make a snapshot of the USB device.

    ```bash
    mylinuxpc> mount /dev/disk/by-label/PITDATA /mnt
    mylinuxpc> tar -czvf --exclude *.squashfs \
    "install-data-$(date  '+%Y-%m-%d_%H-%M-%S').tar.gz" /mnt/
    mylinuxpc> umount /dev/disk/by-label/PITDATA
    ```

1. Follow the steps in the "Boot LiveCD" procedure in the HPE Cray EX System Installation and Configuration
Guide S-8000.
The new tar.gz file can be stored anywhere, and can be used to reinitialize the LiveCD.

1. The new tar.gz file you made can be stored anywhere, and can be used to reinit the liveCD. Follow
the directions in [bootstrap_livecd_usb.md](bootstrap_livecd_usb.md) and then return here and move onto the
next step.

1. Delete the existing content on the USB device and create a new LiveCD on that same USB device.

   Once the install-data partition is created, it can be remounted and can be used to restore the backup.

    ```bash
    mylinuxpc> mount /dev/disk/by-label/PITDATA /mnt
    mylinuxpc> tar -xzvf $(ls -ltR *.tar.gz | head -n 1)
    mylinuxpc> ls -R /mnt
    ``` 

   The tarball should have extracted everything into the install-data partition. 

1. Retrieve the SquashFS artifacts.
   The artifacts can be retrieved at the following locations:

   * `/mnt/var/www/ephemeral/k8s/`
   * `/mnt/var/www/ephemeral/ceph/`

1. Attach the USB to a Cray non-compute node and reboot into the USB device.

1. Once booted into the USB device, restore network configuration, dnsmasq, and ensure the pods are started.

   > STOP AND INSPECT ANY FAILURE IN ANY OF THESE COMMANDS

   ```bash
   pit# tar -xzvf /var/www/ephemeral/backup/dnsmasq*.tar.gz
   pit# tar -xzvf /var/www/ephemeral/backup/network*.tar.gz
   pit# systemctl restart wicked wickedd-nanny
   pit# systemctl restart dnsmasq
   pit# systemctl start basecamp nexus
   ```

1. The LiveCD is now re-installed with the previous configuration.
