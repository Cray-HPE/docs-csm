

## Power Off the External Lustre File System

General procedure for powering off an external ClusterStor system.

Use this procedure as a general guide to power off an external ClusterStor system. Refer to the detailed procedures in the appropriate ClusterStor administration guide:

|Title|Model|
|-----|-----|
|ClusterStor E1000 Administration Guide 4.2 - S-2758|ClusterStor E1000|
|ClusterStor Administration Guide 3.4 - S-2756|ClusterStor L300/L300N|
|ClusterStor Administration Guide - S-2755|Legacy ClusterStor|

1.  SSH to the primary MGMT node as `admin`.

    ```screen
    remote$ ssh -l admin cls01234n00.us.cray.com
    ```

2.  Change to root user.

    ```screen
    admin@n000$ sudo su –
    ```

3.  Collect status information for the system before shutdown.

    ```screen
    n000# cscli csinfo
    n000# cscli show_nodes
    n000# cscli fs_info
    n000# crm_mon -1r
    ```

4.  Check resources before unmounting the file system.

    ```screen
    n000# ssh cls01234n002 crm_mon -r1 | grep fsys
    n000# ssh cls01234n004 crm_mon -r1 | grep fsys
    n000# ssh cls01234n006 crm_mon -r1 | grep fsys
    n000# ssh cls01234n008 crm_mon -r1 | grep fsys
    n000# ssh cls01234n010 crm_mon -r1 | grep fsys
    n000# ssh cls01234n012 crm_mon -r1 | grep fsys
    . . .
    ```

5.  Stop the Lustre file system.

    ```screen
    [n000]# cscli unmount -f FILESYSTEM_NAME
    ```

6.  Verify that resources have been stopped by running the following on all even-numbered nodes:

    ```screen
    [n000]# ssh NODENAME crm_mon -r1 | grep fsys
    cls01234n006\_md0-fsys (ocf::heartbeat:XYMNTR): Stopped          
    cls01234n006\_md1-fsys (ocf::heartbeat:XYMNTR): Stopped          
    cls01234n006\_md2-fsys (ocf::heartbeat:XYMNTR): Stopped          
    cls01234n006\_md3-fsys (ocf::heartbeat:XYMNTR): Stopped          
    cls01234n006\_md4-fsys (ocf::heartbeat:XYMNTR): Stopped          
    cls01234n006\_md5-fsys (ocf::heartbeat:XYMNTR): Stopped          
    cls01234n006\_md6-fsys (ocf::heartbeat:XYMNTR): Stopped          
    cls01234n006\_md7-fsys (ocf::heartbeat:XYMNTR): Stopped
    ```

7.  SSH to the MGS node.

    ```screen
    MGS# ssh MGS\_NODE
    
    ```

8.  To determine if Resource Group md65-group is stopped, use the `crm_mon` utility to monitor the status of the MGS and MDS nodes.

    Shows MGS and MDS nodes in a partial stopped state.

    ```screen
    [MGS]# crm_mon -1r | grep fsys
    cls01234n003\_md66-fsys (ocf::heartbeat:XYMNTR): Stopped
    cls01234n003\_md65-fsys (ocf::heartbeat:XYMNTR): Started
    ```

9.  If the node is not stopped, issue the `stop_xyraid` command and verify that the node is stopped:

    ```screen
    [MGS]# stop_xyraid nodename_md65-group
    
    [MGS]# crm\_mon -1r | grep fsys
    cls01234n003\_md66-fsys (ocf::heartbeat:XYMNTR): Stopped
    cls01234n003\_md65-fsys (ocf::heartbeat:XYMNTR): Stopped
    ```

10. Exit the MGS node.

    ```screen
    MGS# exit
    ```

11. Power off the non-MGMT diskless nodes.

    ```screen
    n000# cscli power\_manage -n DISKLES_NODES\[XX-YY\ --power-off
    ```

12. Check power state of all non-MGMT nodes and list the node hostnames \(in this example `cls01234n[02-15]`\) before power off.

    ```screen
    n000# pm –q
    on: cls01234n\[000-001\]
    on: cls01234n\[002-015\]
    unknown:
    ```

13. Power off all non-MGMT nodes.

    ```screen
    
    [n00]$ cscli power\_manage -n cls01234n\[02-15\] --power-off
    ```

14. Check the power status of the nodes.

    ```screen
    n000# pm –q
    on: cls01234n\[000-001\]
    off: cls01234n\[002-015\]
    unknown:
    ```

15. Repeat step 14 until all non-MGMT nodes are powered off.

16. From the primary MGMT node, power off the MGMT nodes:

    ```screen
    n000# cscli power\_manage -n cls01234n\[000-001\] --power-off
    ```

17. Shutdown the primary management node.

    ```screen
    n000# shutdown -h now
    ```





