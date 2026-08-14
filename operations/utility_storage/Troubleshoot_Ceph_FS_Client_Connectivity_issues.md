# Troubleshoot Ceph MDS Client Connectivity Issues

Use this procedure to diagnose and fix clients not logging into Ceph FS.

## Important notes

- This guide does not diagnose nor fix network issues. Ensure that all networking is functional before proceeding.
- The commands in this procedure can be run from a master NCN or one of the first three storage NCNs.

## Procedure

1. Identify if clients are not logged into Ceph FS.

   ```bash
   ceph fs status
   ```

   Example output:

   ```text
   cephfs - 0 clients    <---- This indicates there are no clients connected
   ======
   RANK      STATE                MDS               ACTIVITY     DNS    INOS
   0        active      cephfs.ncn-s001.abiiiw  Reqs:    0 /s     0      0
   0-s   standby-replay  cephfs.ncn-s002.kyayma  Evts:   38 /s  35.5k  3220
        POOL         TYPE     USED  AVAIL
   cephfs_metadata  metadata  2403M  11.1T
   cephfs_data      data    2641G  11.1T
       STANDBY MDS
   cephfs.ncn-s003.sjatdm
   ```

1. Fail over the MDS to trigger clients logins.

   ```bash
   ceph mds fail 0
   ```

   **NOTE** "0" refers to the active rank in the above output.

1. Verify that clients have reconnected.

   ```bash
   ceph fs status
   ```

   Example output:

   ```text
   cephfs - 24 clients   <---- Shows clients have reconnected
   ======
   RANK      STATE                MDS               ACTIVITY     DNS    INOS
    0        active      cephfs.ncn-s002.kyayma  Reqs:    1 /s  52.8k  20.3k
   0-s   standby-replay  cephfs.ncn-s003.sjatdm  Evts:    0 /s     0      0
         POOL         TYPE     USED  AVAIL
   cephfs_metadata  metadata  2404M  11.1T
     cephfs_data      data    2641G  11.1T
        STANDBY MDS
   cephfs.ncn-s001.abiiiw
   MDS version: ceph version 15.2.8 (bdf3eebcd22d7d0b3dd4d5501bee5bac354d5b55) octopus (stable)
   ```
