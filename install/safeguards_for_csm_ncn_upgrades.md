# Safeguards for CSM

This page covers safe-guards for preventing destructive behaviors on management nodes.

**If reinstalling or upgrading**, run through these safe-guards on a by-case basis:

1. Whether or not CEPH should be preserved.
2. Whether or not the RAIDs should be protected.

### Safeguard CEPH OSDs

1. Edit `/var/www/ephemeral/configs/data.json` and align the following options:

   ```json
   {
     ..
     // Disables Ceph wipe:
     "wipe-ceph-osds": "no"
     ..
   }
   ```

   ```json
   {
     ..
     // Restores default behavior:
     "wipe-ceph-osds": "yes"
     ..
   }
   ```
   ```bash
   pit# vi /var/www/ephemeral/configs/data.json
   ```

1. Quickly toggle yes or no to the file:

   ```bash
   # set wipe-ceph-osds=no
   pit# sed -i 's/wipe-ceph-osds": "yes"/wipe-ceph-osds": "no"/g' /var/www/ephemeral/configs/data.json

   # set wipe-ceph-osds=yes
   pit# sed -i 's/wipe-ceph-osds": "no"/wipe-ceph-osds": "yes"/g' /var/www/ephemeral/configs/data.json
   ```

1. Activate the new setting:

   ```bash
   pit# systemctl restart basecamp
   ```

### Safeguard RAIDS / BOOTLOADERS / SquashFS / OverlayFS

1. Edit `/var/www/boot/script.ipxe` and align the following options as follows:

- `rd.live.overlay.reset=0` will prevent any overlayFS files from being cleared.
- `metal.no-wipe=1` will guard against touching RAIDs, disks, and partitions.

   ```bash
   pit# vi /var/www/boot/script.ipxe
   ```

