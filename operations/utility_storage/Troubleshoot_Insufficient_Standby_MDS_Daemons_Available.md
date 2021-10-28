# Troubleshoot Insufficient Standby MDS Daemons Available

## Procedure

1. Log into a node running ceph-mon. Typically this will be ncn-s001/2/3.

1. Check the ceph health.

   ```bash
   ceph health detail
   ```

   Example Output:

   ```screen
   HEALTH_WARN insufficient standby MDS daemons available
   [WRN] MDS_INSUFFICIENT_STANDBY: insufficient standby MDS daemons available
   have 0; want 1 more
   ```

   This output explicitly states that you need at least 1 more to clear the alert.

1. Determine which MDS daemons are down.

   ```bash
   ceph orch ps --daemon_type mds
   ```

   Example Output:

   ```screen
   NAME                        HOST      STATUS         REFRESHED  AGE  VERSION    IMAGE NAME                        IMAGE ID      CONTAINER ID
   mds.cephfs.ncn-s001.lhoocr  ncn-s001  stopped        4m ago     18h  <unknown>  registry.local/ceph/ceph:v15.2.8  <unknown>     <unknown>
   mds.cephfs.ncn-s002.nywheq  ncn-s002  stopped        4m ago     18h  <unknown>  registry.local/ceph/ceph:v15.2.8  <unknown>     <unknown>
   mds.cephfs.ncn-s003.jdufcg  ncn-s003  running (18h)  4m ago     18h  15.2.8     registry.local/ceph/ceph:v15.2.8  5553b0cb212c  4df61111d738
   ```

   **IMPORTANT:** Depending on the configuration and the number of MDS daemons, the number of MDS daemons in a `stopped` or `error` state may vary.

1. Start the stopped MDS daemon(s).

   ```bash
   ceph orch daemon start <MDS daemon name>
   ```

   Repeat for each stopped MDS daemon.

1. Check the status of the cluster.

   ```bash
   ceph health detail
   ```

   Expected Output:

   ```screen
   HEALTH_OK
   ```

**IMPORTANT:** If the daemon is not starting using the method above, please refer to [Manage Ceph Services](Manage_Ceph_Services.md)