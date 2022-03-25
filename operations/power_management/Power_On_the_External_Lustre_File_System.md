# Power On the External Lustre File System

Use this procedure as a general guide to power on an external ClusterStor system. Refer to the detailed procedures that support each ClusterStor hardware and software release:

* *ClusterStor E1000 Administration Guide 4.2 - S-2758* for ClusterStor E1000 systems
* *ClusterStor Administration Guide 3.4 - S-2756* for ClusterStor L300, L300N systems
* *ClusterStor Administration Guide - S-2755* for Legacy ClusterStor systems

Power up storage nodes in the following sequence:

1.  Storage Management Unit \(SMU\) nodes
2.  Metadata server MGS/MDS nodes
3.  Object storage server \(OSS\) nodes

### Prerequisites

* Facility power must be connected to the PDUs the PDU circuit breakers are set to ON.
* This procedure assumes that power switches on all storage equipment are set to OFF.


### Procedure

1.  Set the System Management Unit \(SMU\) chassis power switches to ON.

2.  Set the Metadata Unit \(MDU\) chassis power switches to ON.

3.  Set the Metadata Management Unit \(MMU\) or Advanced Metadata Management Unit \(AMMU\) chassis power switches to ON.

4.  Set the object storage server \(OSS\), scalable storage unit \(SSU\), extension storage unit \(ESU\), and Scalable Flash Unit \(SFU\) chassis power switches to ON.

5.  SSH to the primary management node.

    For example, on system `cls01234`.

    ```bash
    remote$ ssh -l admin cls01234n000.systemname.com
    ```

6.  Check that the shared storage targets are available for the management nodes.

    ```bash
    [n000]$ pdsh -g mgmt cat /proc/mdstat | dshbak -c
    ```

    Example output:

    ```
    ----------------
    cls01234n000
    ----------------
    Personalities : [raid1] [raid6] [raid5] [raid4] [raid10]
    md64 : active raid10 sda[0] sdc[3] sdw[2] sdl[1]
          1152343680 blocks super 1.2 64K chunks 2 near-copies [4/4] [UUUU]
          bitmap: 2/9 pages [8KB], 65536KB chunk
    md127 : active raid1 sdy[0] sdz[1]
          439548848 blocks super 1.0 [2/2] [UU]
    unused devices: <none>
    ----------------
    cls01234n001
    ----------------
    Personalities : [raid1] [raid6] [raid5] [raid4] [raid10]
    md67 : active raid1 sdi[0] sdt[1]
          576171875 blocks super 1.2 [2/2] [UU]
          bitmap: 0/5 pages [0KB], 65536KB chunk
    md127 : active raid1 sdy[0] sdz[1]
          439548848 blocks super 1.0 [2/2] [UU]
    unused devices: <none>
    ```

7.  Check HA status once the node is up and HA configuration has been established.

    ```bash
    [n000]$ sudo crm_mon -1r
    ```

    The output indicates that all resources have started and are balanced between two nodes.

8.  In cases when all resources started on a single node \(for example, all resources have started on node 00 and did not fail back to node 01, run the failback operation:

    ```bash
    [n000]$ cscli failback –n primary_MGMT_node
    ```

9.  As root on the primary management node, power on the MGS and MDS nodes, for example:

    ```bash
    [n000]# cscli power_manage -n cls01234n[02-03] --power-on

    ```

10. Power on the OSS nodes and, if present, the ADU nodes.

    ```bash
    [n000]# cscli power_manage -n oss_adu_nodes --power-on

    ```

11. Check the status of the nodes.

    ```bash
    [n000]# pdsh -a date
    ```

    Example output:
    
    ```
    cls01234n000: Thu Aug 7 01:29:28 PDT 2014
    cls01234n003: Thu Aug 7 01:29:28 PDT 2014
    cls01234n002: Thu Aug 7 01:29:28 PDT 2014
    cls01234n001: Thu Aug 7 01:29:28 PDT 2014
    cls01234n007: Thu Aug 7 01:29:28 PDT 2014
    cls01234n006: Thu Aug 7 01:29:28 PDT 2014
    cls01234n004: Thu Aug 7 01:29:28 PDT 2014
    cls01234n005: Thu Aug 7 01:29:28 PDT 2014
    ```

12. Check the health of the system.

    ```bash
    [n000]# cscli csinfo
    [n000]# cscli show_nodes
    [n000]# cscli fs_info
    ```

13. Check resources before mounting the file system.

    ```bash
    [n000]# ssh cls01234n000 crm_mon -r1 | grep fsys
    [n000]# ssh cls01234n002 crm_mon -r1 | grep fsys
    [n000]# ssh cls01234n004 crm_mon -r1 | grep fsys
    [n000]# ssh cls01234n006 crm_mon -r1 | grep fsys
    [n000]# ssh cls01234n008 crm_mon -r1 | grep fsys
    [n000]# ssh cls01234n010 crm_mon -r1 | grep fsys
    [n000]# ssh cls01234n012 crm_mon -r1 | grep fsys
    ```

14. Mount the file system.

    ```bash
    [n000]# cscli mount -f cls01234
    ```

