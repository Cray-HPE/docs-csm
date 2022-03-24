# Redeploy the iPXE and TFTP Services

Redeploy the iPXE and TFTP services if a pod with a ceph-fs Process Virtualization Service \(PVS\) on a Kubernetes worker node is causing a `HEALTH_WARN` error.

Resolve issues with ceph-fs and ceph-mds by restarting the iPXE and TFTP services. The Ceph cluster will return to a healthy state after this procedure.

### Prerequisites

This procedure requires administrative privileges.

### Procedure

1.  Find the iPXE and TFTP deployments.

    ```bash
    ncn-m001# kubectl get deployments -n services|egrep 'tftp|ipxe'
    ```

    Example output:

    ```
    cray-ipxe                                   1/1     1            1           22m
    cray-tftp                                   3/3     3            3           28m
    ```

2.  Delete the deployments for the iPXE and TFTP services.

    ```bash
    ncn-m001# kubectl -n services delete deployment cray-tftp
    ncn-m001# kubectl -n services delete deployment cray-ipxe
    ```

3.  Check the status of Ceph.

    Ceph commands need to be run on `ncn-m001`. If a health warning is shown after checking the status, the ceph-mds daemons will need to be restarted on the manager nodes.

    1.  Check the health of the Ceph cluster.

        ```bash
        ncn-m001# ceph -s
        ```

        Example output:

        ```
          cluster:
            id:     bac74735-d804-49f3-b920-cd615b18316b
            health: HEALTH_WARN
                    1 filesystem is degraded

          services:
            mon: 3 daemons, quorum ncn-m001,ncn-m002,ncn-m003 (age 13d)
            mgr: ncn-m001(active, since 24h), standbys: ncn-m002, ncn-m003
            mds: cephfs:1/1 {0=ncn-m002=up:reconnect} 2 up:standby
            osd: 60 osds: 60 up (since 4d), 60 in (since 4d)
            rgw: 5 daemons active (ncn-s001.rgw0, ncn-s002.rgw0, ncn-s003.rgw0, ncn-s004.rgw0, ncn-s005.rgw0)

          data:
            pools:   13 pools, 1664 pgs
            objects: 2.47M objects, 9.3 TiB
            usage:   26 TiB used, 78 TiB / 105 TiB avail
            pgs:     1664 active+clean

          io:
            client:   990 MiB/s rd, 111 MiB/s wr, 2.76k op/s rd, 1.03k op/s wr
        ```

    2.  Obtain more information on the health of the cluster.

        ```bash
        ncn-m001# ceph health detail
        ```

        Example output:

        ```
        HEALTH_WARN 1 filesystem is degraded
        FS_DEGRADED 1 filesystem is degraded
            fs cephfs is degraded
        ```

    3.  Show the status of all CephFS components.

        ```bash
        ncn-m001# ceph fs status
        ```

        Example output:

        ```
        cephfs - 9 clients
        ======
        +------+-----------+----------+----------+-------+-------+
        | Rank |   State   |   MDS    | Activity |  dns  |  inos |
        +------+-----------+----------+----------+-------+-------+
        |  0   | reconnect | ncn-m002 |          | 11.0k |   74  |
        +------+-----------+----------+----------+-------+-------+
        +-----------------+----------+-------+-------+
        |       Pool      |   type   |  used | avail |
        +-----------------+----------+-------+-------+
        | cephfs_metadata | metadata |  780M | 20.7T |
        |   cephfs_data   |   data   |  150M | 20.7T |
        +-----------------+----------+-------+-------+
        +-------------+
        | Standby MDS |
        +-------------+
        |   ncn-m003  |
        |   ncn-m001  |
        ```

    4.  Restart the ceph-mds service.

        This step should only be done if a health warning is shown in the previous substeps.

        ```bash
        ncn-m001# for i in 1 2 3 ; do ansible ncn-m00$i -m shell -a "systemctl restart ceph-mds@ncn-m00$i"; done
        ```

4.  Failover the ceph-mds daemon.

    This step should only be done if a health warning still exists after restarting the ceph-mds service.

    ```bash
    ncn-m001# ceph mds fail ncn-m002
    ```

    The initial output will display the following:

    ```bash
    cephfs - 0 clients
    ======
    +------+--------+----------+----------+-------+-------+
    | Rank | State  |   MDS    | Activity |  dns  |  inos |
    +------+--------+----------+----------+-------+-------+
    |  0   | **rejoin** | ncn-m003 |          |    0  |    0  |
    +------+--------+----------+----------+-------+-------+
    +-----------------+----------+-------+-------+
    |       Pool      |   type   |  used | avail |
    +-----------------+----------+-------+-------+
    | cephfs_metadata | metadata |  781M | 20.7T |
    |   cephfs_data   |   data   |  117M | 20.7T |
    +-----------------+----------+-------+-------+
    +-------------+
    | Standby MDS |
    +-------------+
    |   ncn-m002  |
    |   ncn-m001  |
    +-------------+
    ```

    The rejoin status should turn to active:

    ```bash
    cephfs - 7 clients
    ======
    +------+--------+----------+---------------+-------+-------+
    | Rank | State  |   MDS    |    Activity   |  dns  |  inos |
    +------+--------+----------+---------------+-------+-------+
    |  0   | **active** | ncn-m003 | Reqs:    0 /s | 11.1k |  193  |
    +------+--------+----------+---------------+-------+-------+
    +-----------------+----------+-------+-------+
    |       Pool      |   type   |  used | avail |
    +-----------------+----------+-------+-------+
    | cephfs_metadata | metadata |  781M | 20.7T |
    |   cephfs_data   |   data   |  117M | 20.7T |
    +-----------------+----------+-------+-------+
    +-------------+
    | Standby MDS |
    +-------------+
    |   ncn-m002  |
    |   ncn-m001  |
    +-------------+
    ```

5.  Ensure the service is deleted along with the associated PVC.

    The output for the command below should empty. If an output is displayed, such as in the example below, then the resources have not been deleted.

    ```bash
    ncn-m001# kubectl get pvc -n services|grep tftp
    ```

    Example of resources not being deleted in returned output:

    ```
    cray-tftp-shared-pvc Bound pvc-315d08b0-4d00-11ea-ad9d-b42e993b7096 5Gi RWX ceph-cephfs-external 29m
    ```

    *Optional:* Use the following command to delete the associated PVC.

    ```bash
    ncn-m001# kubectl -n services delete pvc PVC_NAME
    ```

6.  Deploy the TFTP service.

    Wait for the TFTP pods to come online and verify the PVC was created.

    ```bash
    ncn-m001# loftsman helm upgrade cray-tftp loftsman/cray-tftp
    ```

7.  Deploy the iPXE service.

    This may take a couple of minutes and may show up in error state. Wait a couple minutes and it will go to running.

    ```bash
    ncn-m001# loftsman helm upgrade cms-ipxe loftsman/cms-ipxe
    ```

8.  Log into the iPXE pod and verify the iPXE file was created.

    This may take another couple of minutes while it is creating the files.

    1.  Find the iPXE pod ID.

        ```bash
        ncn-m001# kubectl get pods -n services --no-headers -o wide | grep cray-ipxe | awk '{print $1}'
        ```

    2.  Log into the pod using the iPXE pod ID.

        ```bash
        ncn-m001# kubectl exec -n services -it IPXE_POD_ID /bin/sh
        ```

        To see the containers in the pod:

        ```bash
        ncn-m001# kubectl describe pod/CRAY-IPXE_POD_NAME -n services
        ```

9.  Log into the TFTP pods and verify it is seeing the correct file size.

    1.  Find the TFTP pod ID.

        ```bash
        ncn-m001# kubectl get pods -n services --no-headers -o wide | grep cray-tftp | awk '{print $1}'
        ```

        Example output:

        ```
        cray-tftp-7dc77f9cdc-bn6ml
        cray-tftp-7dc77f9cdc-ffgnh
        cray-tftp-7dc77f9cdc-mr6zd
        cray-tftp-modprobe-42648
        cray-tftp-modprobe-4kmqg
        cray-tftp-modprobe-4sqsk
        cray-tftp-modprobe-hlfcc
        cray-tftp-modprobe-r6bvb
        cray-tftp-modprobe-v2txr
        ```

    2.  Log into the pod using the TFTP pod ID.

        ```bash
        ncn-m001# kubectl exec -n services -it TFTP_POD_ID /bin/sh
        ```

    3.  Change to the /var/lib/tftpboot directory.

        ```bash
        # cd /var/lib/tftpboot
        ```

    4.  Check the ipxe.efi size on the TFTP servers.

        If there are any issues, the file will have a size of 0 bytes.

        ```bash
        # ls -l
        ```

        Example output:

        ```
        total 1919
        -rw-r--r--    1 root     root        980768 May 15 16:49 debug.efi
        -rw-r--r--    1 root     root        983776 May 15 16:50 ipxe.efi
        ```

