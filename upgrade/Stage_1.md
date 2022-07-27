# Stage 1 - Ceph image upgrade

**Reminder:** If any problems are encountered and the procedure or command output does not provide relevant guidance, see
[Relevant troubleshooting links for upgrade-related issues](README.md#relevant-troubleshooting-links-for-upgrade-related-issues).

## Procedure

1. (`ncn-m001#`) Run `ncn-upgrade-worker-storage-nodes.sh` for `ncn-s001`. 

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-s001
   ```

   > **`NOTE`** 
   >> You can also upgrade multiple storage nodes with a comma separated list. This will upgrade the storage nodes sequentially.
   >
   >```bash
   > /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-s001,ncn-s002,ncn-s003
   >```



## Stage completed

All the Ceph nodes have been rebooted into the new image.

This stage is completed. Continue to [Stage 2](Stage_2.md).
