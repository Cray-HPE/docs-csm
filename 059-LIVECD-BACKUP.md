# LiveCD Re-Installs

This page will go over how to setup a re-install on a node.


1. Backup to the data partition:

    ```bash
    pit:~ # mkdir -pv /var/www/ephemeral/backup
    pit:~ # pushd /var/www/ephemeral/backup
    pit:~ # tar -czvf "dnsmasq-data-$(date  '+%Y-%m-%d_%H-%M-%S').tar.gz" /etc/dnsmasq.*
    pit:~ # tar -czvf "network-data-$(date  '+%Y-%m-%d_%H-%M-%S').tar.gz" /etc/sysconfig/network/*
    pit:~ # cp -pv /etc/hosts ./
    pit:~ # popd
    pit:~ # umount /var/www/ephemeral
    ``` 
    Now the USB stick can be unplugged, it contains all the information we already loaded plus backups
    of initialized files.

2. Plug the stick into a new machine, or make a backup on the booted NCN. Make a snapshot of
 the USB stick.

    ```bash
    mylinuxpc> mount /dev/disk/by-label/PITDATA /mnt
    mylinuxpc> tar -czvf --exclude *.squashfs "install-data-$(date  '+%Y-%m-%d_%H-%M-%S').tar.gz" /mnt/
    mylinuxpc> umount /dev/disk/by-label/PITDATA
    ```

3. The new tar.gz file you made can be stored anywhere, and can be used to reinit the liveCD. Follow
the directions in [005-LIVECD-CREATION](002-CSM-INSTALL.md) and then return here and move onto the
next step.

4. Now you can create a newer LiveCD on the same USB stick, clobbering whats there. Once created
 the install-data partition can be remounted and you can restore/extract the backup:

    ```bash
    mylinuxpc> mount /dev/disk/by-label/PITDATA /mnt
    mylinuxpc> tar -xzvf $(ls -ltR *.tar.gz | head -n 1)
    mylinuxpc> ls -R /mnt
    ``` 

5. The tarball should've extracted everything into the install-data partition. You will need to re-fetch
 your squashFS artifacts, they can be fetched into (respecitvely):
 - `/mnt/var/www/ephemeral/k8s/`
 - `/mnt/var/www/ephemeral/ceph/`

Once fetched, attach the USB to a CRAY non-compute node and reboot into the USB stick.

6. Once booted into the USB stick; restore network config, dnsmasq, and ensure pods are started.

    ```bash
    # STOP AND INSPECT ANY FAILURE IN ANY OF THESE COMMANDS
    # DO NOT PASS GO ; DO NOT COLLECT $200
    pit:~ # tar -xzvf /var/www/ephemeral/backup/dnsmasq*.tar.gz
    pit:~ # tar -xzvf /var/www/ephemeral/backup/network*.tar.gz
    pit:~ # systemctl restart wicked wickedd-nanny
    pit:~ # systemctl restart dnsmasq
    pit:~ # systemctl start basecamp nexus
    ```

7. You now have a revitalized LiveCD with previous configuration.
