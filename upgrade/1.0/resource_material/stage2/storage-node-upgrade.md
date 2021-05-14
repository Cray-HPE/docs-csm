<h2 id="storage-node-upgrade">Upgrade Storage Node Steps</h2>

These steps should be run for a storage node after the common upgrade steps are complete.

1. Once the storage node has been rebuilt with its new image, log into the node and checkout the upgrade scripts:

   ```bash
   ncn# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm
   ```
2. Run NTP setup
```bash
ncn-s001# /srv/cray/scripts/metal/ntp-upgrade-config.sh
```

2. Restore the `/var/lib/ceph`, `/etc/ceph`, and `/var/lib/containers` directories for the storage node being upgraded ($UPGRADE_NCN).

   - Copy the backup file from the stable ncn to the newly build node:

   ```bash
   ncn# scp ./${UPGRADE_NCN}-ceph.tgz $UPGRADE_NCN:/
   ```

   - Extract the file on the node:

   ```bash
   ncn# cd /
   ncn# tar -xvf ./$(hostname)-ceph.tgz
   ncn# rm /$(hostname)-ceph.tgz
   ```

3. Watch the status of the cluster.  Run this command from a separate terminal window on the stable ncn:

   ```bash
   watch "ceph orch ps | grep $UPGRADE_NCN; echo ''; ceph osd tree"
   ```

4. Grab the ceph ssh key -- run these commands from the stable ncn:

   ```bash
   ceph cephadm get-pub-key > ~/ceph.pub
   ```

5. Add the ceph public key to the upgraded node -- run this command from the stable node.

   ```bash
   ncn# ssh-copy-id -f -i ~/ceph.pub root@$UPGRADE_NCN
   ```

6. Add the host back into the ceph cluster.  Run this command from the stable ncn.

   ```bash
   ncn# ceph orch host add $UPGRADE_NCN
   ```

7. Start the `mon` daemon.  This command can be run from the stable node.

   ```bash
   ncn# ceph orch daemon redeploy mon.$UPGRADE_NCN
   ```

   > **`NOTE`:** Watch the `ceph orch ps` output to see that the mon.$UPGRADE_NCN container is in a running state before proceeding to step 8.  If the daemon ends up in an `unknown` state instead of `running`, you may need to force it to redeploy:
     ```bash
     ncn# ceph orch daemon rm $UPGRADE_NCN --force
     ncn# ceph orch daemon redeploy $UPGRADE_NCN
     ```

8. Start the remainder of the daemons. This command can be run from the stable node.

   ```bash
   ncn#  for s in $(ceph orch ps | grep $UPGRADE_NCN | awk '{print $1}'); do  ceph orch daemon start $s; done
   ```

9. Run script to reconfigure storage load balancer (run on the newly rebuilt storage node):

   ```bash
   ncn# /usr/share/doc/metal/upgrade/1.0/scripts/ceph/ceph-services-stage2.sh
   ```

10. Proceed either of the following options:

   - [Back to Common Prerequisite Steps](../common/prerequisite-steps.md) to rebuild another storage node
   - [Back to Main Page](../../README.md) if done upgrading storage nodes
