# Safeguards

This page covers safe-guards for preventing destructive behaviors on NCNs.

**If you are upgrading** you should run through these safe-guards on a by-case basis:

1. Whether or not CEPH should be preserved.
2. Whether or not the RAIDs should be protected.

##### Safeguard CEPH OSDs

Edit `/var/www/ephemeral/configs/data.json` and align the following options:

```json
{
  ..
  // Disables ceph wipe:
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

pit# vi /var/www/ephemeral/configs/data.json

Quickly toggle yes or no to the file:

```bash
# set wipe-ceph-osds=no
pit# sed -i 's/wipe-ceph-osds": "yes"/wipe-ceph-osds": "no"/g' /var/www/ephemeral/configs/data.json

# set wipe-ceph-osds=yes
pit# sed -i 's/wipe-ceph-osds": "no"/wipe-ceph-osds": "yes"/g' /var/www/ephemeral/configs/data.json
```

Activate the new setting:

```
pit# systemctl restart basecamp
```

##### Safeguard RAIDS / BOOTLOADERS / SquashFS / OverlayFS

Edit `/var/www/boot/script.ipxe` and align the following options as you see them here:

- `rd.live.overlay.reset=0` will prevent any overlayFS files from being cleared.
- `metal.no-wipe=1` will guard against touching RAIDs, disks, and partitions.

pit# vi /var/www/boot/script.ipxe
