# Customize PCIe Hardware

This page will assist an admin with changing the kernel parameters for NCNs that have extra disks.

> **`NOTE:`** If a system's hardware is Plan of Record (PoR), then this page is not needed.

For any procedure below, it is assumed that the extra disks are going to be utilized. If they are undesired, then the only action item to do is to yank/remove/pull the disks from the NCN.

## Procedure

### Masters & Workers

Add the kernel parameter `metal.disks=X` where `X` is the number of extra disks on the NCN. This parameter may be added to the PIT's boot scripts or to Boot Script Service (BSS).

- For the PIT:

   - Edit the scripts for the master(s) and/or worker(s) in `/var/www/ncn-*` with this kernel parameter (the snippet below uses workers with 1 extra disk as an example):

      ```bash
      pit# for script in /var/www/ncn-w*/script.ipxe; do
          sed -i 's/append/append metal.disks=3/' $script; done
      ```

   - Update BSS with the kernel parameter (the snippet below requires the xname of the NCN to limit the operation too):

      ```bash
      ncn-m001# csi handoff bss-update-param --limit x3000c0s3b0n0 --kernel metal.disk=3
      ```

### Storage

There is nothing to do here. If there are extra disks they will be consumed by the CEPH installer.
