# Reinstall LiveCD

Setup a re-install of LiveCD on a node using the previous configuration.

1. (`pit#`) Backup to the data partition:

    ```bash
    mkdir -pv /var/www/ephemeral/backup
    pushd /var/www/ephemeral/backup
    tar -czvf "dnsmasq-data-$(date  '+%Y-%m-%d_%H-%M-%S').tar.gz" /etc/dnsmasq.*
    tar -czvf "network-data-$(date  '+%Y-%m-%d_%H-%M-%S').tar.gz" /etc/sysconfig/network/*
    cp -pv /etc/hosts ./
    popd
    umount -v /var/www/ephemeral
    ```

1. Unplug the USB device.

   The USB device should now contain all the information already loaded, as well as the backups of
   the initialized files.

1. (`external#`) Plug the device into a new machine, or make a backup on the booted NCN. Make a snapshot of the USB device.

    ```bash
    mount -v -L PITDATA /mnt
    tar -czvf --exclude *.squashfs \
    "install-data-$(date  '+%Y-%m-%d_%H-%M-%S').tar.gz" /mnt/
    umount -v /mnt
    ```

1. Follow the directions in [Boot the LiveCD USB](Boot_LiveCD_USB.md), and then return here and move onto the next step.

   The new tarball file can be stored anywhere, and can be used to reinitialize the LiveCD.

1. (`external#`) Delete the existing content on the USB device and create a new LiveCD on that same USB device.

   Once the install-data partition is created, it can be remounted and can be used to restore the backup.

    ```bash
    mount -v /dev/disk/by-label/PITDATA /mnt
    tar -xzvf $(ls -ltR *.tar.gz | head -n 1)
    ls -R /mnt
    ```

   The tarball should have extracted everything into the install-data partition.

1. Retrieve the SquashFS artifacts.

   The artifacts can be retrieved at the following locations:

   * `/mnt/var/www/ephemeral/k8s/`
   * `/mnt/var/www/ephemeral/ceph/`

1. Attach the USB device to a Cray non-compute node (NCN) and reboot into the USB device.

1. (`pit#`) Once booted into the USB device, restore network configuration and DNSMasq, and ensure the pods are started.

   > **STOP AND INSPECT ANY FAILURE IN ANY OF THESE COMMANDS**

   ```bash
   tar -xzvf /var/www/ephemeral/backup/dnsmasq*.tar.gz
   tar -xzvf /var/www/ephemeral/backup/network*.tar.gz
   systemctl restart wicked wickedd-nanny
   systemctl restart dnsmasq
   systemctl start basecamp nexus
   ```

The LiveCD is now re-installed with the previous configuration.
