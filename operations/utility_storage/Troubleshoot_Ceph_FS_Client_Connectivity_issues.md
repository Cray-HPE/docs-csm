# Troubleshooting Ceph MDS Client Connectivity Issues

Use this procedure to diagnose and fix clients not logging into Ceph fs.

**MOTE:** This section does not diagnose nor fix network issues.  Please ensure there that all networking if functional before proceeding.

***IMPORTANT:*** The following commands can be run from ncn-m001/2/3 or ncn-s001/2/3. 

## Procedure

1. Identify if clients are not logged into Ceph FS.

   ```bash
   # ceph fs status
   cephfs - 0 clients    <---- This indicates we have no clients connected
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

   NOTE: "0" refers to the active rank in our above output.

1. Verify clients have reconnected.

   ```bash
   # ceph fs status
   cephfs - 24 clients   <---- Shows our clients have reconnected
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
