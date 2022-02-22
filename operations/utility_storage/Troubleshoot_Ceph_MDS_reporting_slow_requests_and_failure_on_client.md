# Troubleshooting Ceph MDS Reporting Slow Requests and Failure on Client

Use this procedure to troubleshoot Ceph MDS reporting slow requests after following the [Identify Ceph Latency Issues](Identify_Ceph_Latency_Issues.md) procedure.

> **IMPORTANT:** This procedure includes a mix of commands that need to be run on the host(s) running the MDS daemon(s) and other commands that can be run from any of the ceph-mon nodes.

> **NOTICE:** These steps are based off [upstream Ceph documentation](https://docs.ceph.com/en/octopus/cephfs/troubleshooting/).


## Prerequisites

* The [Identify Ceph Latency Issues](Identify_Ceph_Latency_Issues.md) procedure has been completed.
* This issue has been encountered and this page is being used as a reference for commands.
* The correct version of the documentation for the cluster running is being used.


## Procedure

1. Identify the active MDS.

   ```bash
   ncn-s00(1/2/3)# ceph fs status -f json-pretty|jq -r '.mdsmap[]|select(.state=="active")|.name'
   cephfs.ncn-s003.ihwkop
   ```

2. `ssh` to the host running the active MDS.

3. Enter into a cephadm shell.

   ```bash
   ncn-s003# cephadm shell
   ```

   Example output:

   ```
   Inferring fsid 7350865a-0b21-11ec-b9fa-fa163e06c459
   Inferring config /var/lib/ceph/7350865a-0b21-11ec-b9fa-fa163e06c459/mon.ncn-s003/config
   Using recent ceph image arti.dev.cray.com/third-party-docker-stable-local/ceph/   ceph@sha256:70536e31b29a4241999ec4fd13d93e5860a5ffdc5467911e57e6bf04dfe68337
   [ceph: root@ncn-s003 /]#
   ```

   > **NOTE:** Messages such as "WARNING: The same type, major and minor should not be used for multiple devices" can be ignored. There is an upstream bug to address this issue.

4. Dump in-flight ops.

   ```bash
   [ceph: root@ncn-s003 /]# ceph daemon mds.cephfs.ncn-s003.ihwkop dump_ops_in_flight
   ```

   Example output:

   ```
   {
       "ops": [],
       "num_ops": 0
   }
   ```

   > **NOTE:** The example above is about how to run the command. Recreating the exact scenario to provide a full example is not easily done. This will be updated when the information is available.


## General Steps from Upstream

1. Identify the stuck commands and examine why they are stuck.
   
   1. Usually the last "event" will have been an attempt to gather locks, or sending the operation off to the MDS log.
   
   2. If it is waiting on the OSDs, fix them.
   
   3. If operations are stuck on a specific inode, you probably have a client holding caps which prevent others from using it, either because the client is trying to flush out dirty data or because you have encountered a bug in CephFS' distributed file lock code (the file "capabilities" ["caps"] system).
   
      1. If it is a result of a bug in the capabilities code, restarting the MDS is likely to resolve the problem.
   
   4. If there are no slow requests reported on the MDS, and it is not reporting that clients are misbehaving, either the client has a problem or its requests are not reaching the MDS.

