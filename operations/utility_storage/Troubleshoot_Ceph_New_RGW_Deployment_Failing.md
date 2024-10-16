# Troubleshoot Ceph New RGW Deployment Failing

Troubleshoot an issue where a new RGW deployment is failing because of an address already in use. This bug corrupts the health of the Ceph cluster.

Return the Ceph cluster to a healthy state by resolving issues with failing deployment.

## Prerequisites

This procedure requires admin privileges.

## Procedure

See [Collect Information about the Ceph Cluster](Collect_Information_About_the_Ceph_Cluster.md) for more information on how to interpret the output of the Ceph commands used in this procedure.

### Verify Ceph is deploying a second RGW deployment

1. Log on to a master node or `ncn-s001/2/3` to run the following commands.

1. Observe that a Ceph RGW deployment is failing to deploy because the address is already in use.

    1. Use the `cephadm` logs to see if this error is occurring. The command below is following the `cephadm` logs. It may take a minute or two for the Ceph to attempt to deploy RGW and for the error to appear.

        ```bash
        ceph -W cephadm
        ```

        Example output:

        ```bash
            cluster:
            id:     56cdd77c-7184-11ef-9f67-42010afc0104
            health: HEALTH_WARN
                    Failed to place 2 daemon(s)

        services:
            mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 7d)
            mgr: ncn-s002.mneqjy(active, since 7d), standbys: ncn-s001.iwikun, ncn-s003.pkabeg
            mds: 2/2 daemons up, 3 standby, 1 hot standby
            osd: 18 osds: 18 up (since 7d), 18 in (since 7d)
            rgw: 3 daemons active (3 hosts, 1 zones)

        data:
            volumes: 2/2 healthy
            pools:   15 pools, 625 pgs
            objects: 69.74k objects, 123 GiB
            usage:   260 GiB used, 8.7 TiB / 9.0 TiB avail
            pgs:     625 active+clean

        io:
            client:   8.4 KiB/s rd, 1.8 MiB/s wr, 5 op/s rd, 176 op/s wr

        progress:
            Updating rgw.site1.zone1 deployment (+2 -> 2) (2s)
            [============================]


        2024-09-20T19:04:56.337199+0000 mgr.ncn-s002.mneqjy [INF] Removing key for client.rgw.site1.zone1.ncn-s002.mgujxl
        2024-09-20T19:04:56.371965+0000 mgr.ncn-s002.mneqjy [ERR] Failed while placing rgw.site1.zone1.ncn-s002.mgujxl on ncn-s002: cephadm exited with an error code: 1, stderr: Non-zero exit code 125 from /usr/bin/podman container inspect --format {{.State.Status}} ceph-56cdd77c-7184-11ef-9f67-42010afc0104-rgw-site1-zone1-ncn-s002-mgujxl
        /usr/bin/podman: stderr Error: no such container ceph-56cdd77c-7184-11ef-9f67-42010afc0104-rgw-site1-zone1-ncn-s002-mgujxl
        Non-zero exit code 125 from /usr/bin/podman container inspect --format {{.State.Status}} ceph-56cdd77c-7184-11ef-9f67-42010afc0104-rgw.site1.zone1.ncn-s002.mgujxl
        /usr/bin/podman: stderr Error: no such container ceph-56cdd77c-7184-11ef-9f67-42010afc0104-rgw.site1.zone1.ncn-s002.mgujxl
        Deploy daemon rgw.site1.zone1.ncn-s002.mgujxl ...
        Verifying port 8080 ...
        Cannot bind to IP 0.0.0.0 port 8080: [Errno 98] Address already in use
        ERROR: TCP Port(s) '8080' required for rgw already in use
        2024-09-20T19:04:56.410687+0000 mgr.ncn-s002.mneqjy [INF] Deploying daemon rgw.site1.zone1.ncn-s001.rdtynd on ncn-s001
        2024-09-20T19:04:57.536533+0000 mgr.ncn-s002.mneqjy [INF] Removing key for client.rgw.site1.zone1.ncn-s001.rdtynd
        2024-09-20T19:04:57.576404+0000 mgr.ncn-s002.mneqjy [ERR] Failed while placing rgw.site1.zone1.ncn-s001.rdtynd on ncn-s001: cephadm exited with an error code: 1, stderr: Non-zero exit code 125 from /usr/bin/podman container inspect --format {{.State.Status}} ceph-56cdd77c-7184-11ef-9f67-42010afc0104-rgw-site1-zone1-ncn-s001-rdtynd
        /usr/bin/podman: stderr Error: no such container ceph-56cdd77c-7184-11ef-9f67-42010afc0104-rgw-site1-zone1-ncn-s001-rdtynd
        Non-zero exit code 125 from /usr/bin/podman container inspect --format {{.State.Status}} ceph-56cdd77c-7184-11ef-9f67-42010afc0104-rgw.site1.zone1.ncn-s001.rdtynd
        /usr/bin/podman: stderr Error: no such container ceph-56cdd77c-7184-11ef-9f67-42010afc0104-rgw.site1.zone1.ncn-s001.rdtynd
        Deploy daemon rgw.site1.zone1.ncn-s001.rdtynd ...
        Verifying port 8080 ...
        Cannot bind to IP 0.0.0.0 port 8080: [Errno 98] Address already in use
        ERROR: TCP Port(s) '8080' required for rgw already in use
        ```

        **Note** the name of the daemon attempting to deploy for the next step, in this case `rgw.site1.zone1`

    1. Verify that the running daemon has a different name than the one attempting to deploy

        Check the names of the running daemons with the following command.

        ```bash
        ceph orch ps --daemon_type rgw
        ```

        Example output:

        ```bash
        NAME                       HOST      PORTS   STATUS        REFRESHED  AGE  MEM USE  MEM LIM  VERSION  IMAGE ID      CONTAINER ID
        rgw.site1.ncn-s001.xoaosp  ncn-s001  *:8080  running (6d)     7m ago   6d     516M        -  17.2.6   6eebe3129025  fdd8842a0b16
        rgw.site1.ncn-s002.qsibkp  ncn-s002  *:8080  running (6d)     7m ago   6d     478M        -  17.2.6   6eebe3129025  86bd2327ab81
        rgw.site1.ncn-s003.hwiydc  ncn-s003  *:8080  running (4d)     3m ago   4d     412M        -  17.2.6   6eebe3129025  fb89e37f1ec8
        ```

        In this example, observe that the name of the running RGW deployment is `rgw.site1`. This is different than the RGW  deployment that is trying to be deployed above which has the name `rgw.site1.zone1`.

        If the error is occuring and the running daemon has a different name than the one attempting to deploy continue on to resolve the two RGW deployments.

### Procedure to resolve two RGW deployments

1. Remove the conflicting daemon
**Note:** The RGW deployment in CSM should be named `rgw.site1`. The deployment that should be removed should have a name other than `rgw.site1`. In this example, the deployment that should be removed is `rgw.site1.zone1`.
    This command will remove the conflicting daemon and should restore the ceph cluster to a healthy state.

    ```bash
    ceph orch rm rgw.site1.zone1
    ```

    Example output:

    ```bash
    Removed service rgw.site1.zone1
    ```

1. Check the health of the Ceph cluster on one of the manager nodes.

   Rerun the command to check the ceph admin tool

    ```bash
        ceph -W cephadm
    ```

    Healthy example output:

    ```bash
    cluster:
        id:     56cdd77c-7184-11ef-9f67-42010afc0104
        health: HEALTH_OK

    services:
        mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 11d)
        mgr: ncn-s002.mneqjy(active, since 11d), standbys: ncn-s001.iwikun, ncn-s003.pkabeg
        mds: 2/2 daemons up, 3 standby, 1 hot standby
        osd: 18 osds: 18 up (since 11d), 18 in (since 11d)
        rgw: 3 daemons active (3 hosts, 1 zones)

    data:
        volumes: 2/2 healthy
        pools:   15 pools, 625 pgs
        objects: 74.42k objects, 137 GiB
        usage:   277 GiB used, 8.7 TiB / 9.0 TiB avail
        pgs:     625 active+clean

    io:
        client:   12 KiB/s rd, 3.9 MiB/s wr, 3 op/s rd, 374 op/s wr
    ```
