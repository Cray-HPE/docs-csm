# Power Off the External Lustre File System

General procedure for powering off an external ClusterStor system.

Use this procedure as a general guide to power off an external ClusterStor system. Refer to the detailed procedures in the appropriate ClusterStor administration guide:

|Title|Model|
|-----|-----|
|`ClusterStor E1000 Administration Guide 4.2 - S-2758`|ClusterStor E1000|
|`ClusterStor Administration Guide 3.4 - S-2756`|ClusterStor L300/L300N|
|`ClusterStor Administration Guide - S-2755`|Legacy ClusterStor|

## Procedure

1. SSH to the primary MGMT node as `admin`.

    ```bash
    remote$ ssh -l admin cls01234n00.us.cray.com
    ```

1. Change to root user.

    ```bash
    admin@n000$ sudo su –
    ```

1. Collect status information for the system before shutdown.

    ```bash
    cscli csinfo
    cscli show_nodes
    cscli fs_info
    crm_mon -1r
    ```

1. Check resources before unmounting the file system.

    ```bash
    ssh cls01234n002 crm_mon -r1 | grep fsys
    ssh cls01234n004 crm_mon -r1 | grep fsys
    ssh cls01234n006 crm_mon -r1 | grep fsys
    ssh cls01234n008 crm_mon -r1 | grep fsys
    ssh cls01234n010 crm_mon -r1 | grep fsys
    ssh cls01234n012 crm_mon -r1 | grep fsys
    . . .
    ```

1. Stop the Lustre file system (`FILESYSTEM_NAME` will be reported from the `cscli fs_info` command run above).

    ```bash
    [n000]# cscli unmount -f FILESYSTEM_NAME
    ```

1. Verify that resources have been stopped by running the following on all even-numbered nodes:

    ```bash
    [n000]# ssh NODENAME crm_mon -r1 | grep fsys
    ```

    Example output:

    ```text
    cls01234n006_md0-fsys (ocf::heartbeat:XYMNTR): Stopped
    cls01234n006_md1-fsys (ocf::heartbeat:XYMNTR): Stopped
    cls01234n006_md2-fsys (ocf::heartbeat:XYMNTR): Stopped
    cls01234n006_md3-fsys (ocf::heartbeat:XYMNTR): Stopped
    cls01234n006_md4-fsys (ocf::heartbeat:XYMNTR): Stopped
    cls01234n006_md5-fsys (ocf::heartbeat:XYMNTR): Stopped
    cls01234n006_md6-fsys (ocf::heartbeat:XYMNTR): Stopped
    cls01234n006_md7-fsys (ocf::heartbeat:XYMNTR): Stopped
    ```

1. SSH to the MGS node (the `MGS_NODE` name will be reported from the `cscli fs_info` command run above).

    ```bash
    ssh MGS_NODE

    ```

1. To determine if Resource Group md65-group is stopped, use the `crm_mon` utility to monitor the status of the MGS and MDS nodes.

    Shows MGS and MDS nodes in a partial stopped state.

    ```bash
    [MGS]# crm_mon -1r | grep fsys
    ```

    Example output:

    ```text
    cls01234n003_md66-fsys (ocf::heartbeat:XYMNTR): Stopped
    cls01234n003_md65-fsys (ocf::heartbeat:XYMNTR): Started
    ```

    If the output above shows a partial stopped state (`Stopped` and `Started`), issue the `stop_xyraid` command and verify that the node is stopped:

    ```bash
    [MGS]# stop_xyraid nodename_md65-group

    [MGS]# crm\_mon -1r | grep fsys
    cls01234n003_md66-fsys (ocf::heartbeat:XYMNTR): Stopped
    cls01234n003_md65-fsys (ocf::heartbeat:XYMNTR): Stopped
    ```

1. Exit the MGS node.

    ```bash
    exit
    ```

1. Power off the non-MGMT diskless nodes.

    1. Check power state of all non-MGMT nodes and list the node hostnames \(in this example `cls01234n[02-15]`\) before power off.
  
        ```bash
        pm -q
        ```
  
        Example output:
  
        ```text
        on: cls01234n[000-001]
        on: cls01234n[002-015]
        unknown:
        ```
  
    1. Power off all non-MGMT nodes.
  
        ```bash
        [n00]$ cscli power_manage -n cls01234n[02-15] --power-off
        ```
  
    1. Check the power status of the nodes.
  
        ```bash
        pm -q
        ```
  
        Example output:
  
        ```text
        on: cls01234n[000-001]
        off: cls01234n[002-015]
        unknown:
        ```

1. Repeat step 11 until all non-MGMT nodes are powered off.

1. From the primary MGMT node, power off the MGMT nodes:

    ```bash
    cscli power_manage -n cls01234n[000-001] --power-off
    ```

1. Shut down the primary management node.

    ```bash
    shutdown -h now
    ```

## Next Step

Return to [System Power Off Procedures](System_Power_Off_Procedures.md) and continue with next step.
