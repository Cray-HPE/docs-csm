<h2 id="storage-prerequisite-steps">Storage Prerequisite Steps</h2>

These steps should be taken to prepare each storage node being upgraded.

1. Ensure the `wipe-ceph-osds` global flag is set to `no`.
   Run this command from the stable node (ncn-m001, for example) that has `csi` installed:

   ```bash
   ncn-m001# csi handoff bss-update-cloud-init --set meta-data.wipe-ceph-osds=no --limit Global
   ```

2. If this is the first storage node (ncn-s001), edit the set of scripts run as part of the cloud-init `runcmd`.  **Skip to step 3 if the node being upgraded is a node other than `ncn-s001`**.

     ```bash
     ncn-m001# csi handoff bss-update-cloud-init --set user-data.runcmd=[\
     \"/srv/cray/scripts/metal/install-bootloader.sh\",\
     \"/srv/cray/scripts/metal/set-host-records.sh\",\
     \"/srv/cray/scripts/metal/set-dhcp-to-static.sh\",\
     \"/srv/cray/scripts/metal/set-dns-config.sh\",\
     \"/srv/cray/scripts/metal/ntp-upgrade-config.sh\",\
     \"/srv/cray/scripts/metal/set-bmc-bbs.sh\",\
     \"/srv/cray/scripts/metal/disable-cloud-init.sh\",\
     \"/srv/cray/scripts/common/update_ca_certs.py\"\
     ] --limit $UPGRADE_XNAME
     ```

3. Backup the `/var/lib/ceph`, `/etc/ceph`, and `/var/lib/containers` directories for the storage node being upgraded ($UPGRADE_NCN).

   - Create a tar file on the storage node being upgraded:

   ```bash
   ncn-s001# tar -zcvf /tmp/$(hostname)-ceph.tgz /var/lib/ceph /var/lib/containers /etc/ceph
   ```

   - Copy the file to the $STABLE_NCN (execute from the stable ncn node):

   ```bash
   ncn-m001# scp $UPGRADE_NCN:/tmp/${UPGRADE_NCN}-ceph.tgz .
   ```

4. Proceed with the common upgrade steps:
   - [Common Upgrade Steps](../common/upgrade-steps.md)
