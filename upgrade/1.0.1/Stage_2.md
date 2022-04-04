# Stage 2 - Ceph image upgrade

>**`IMPORTANT:`**
>
> Reminder: Before running any upgrade scripts, be sure the Cray CLI output format is reset to default by running the following command:
>
>```bash
> ncn# unset CRAY_FORMAT
>```

1. In order for nodes to properly PXE boot, Border Gateway Protocol \(BGP\) must be healthy. Before proceeding, check the status of BGP as described in the [Check BGP Status and Reset Sessions](../../operations/network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md) procedure.

1. Run `ncn-upgrade-ceph-nodes.sh` for `ncn-s001`. Follow output of the script carefully. The script will pause for manual interaction.

    ```bash
    ncn-m001# /usr/share/doc/csm/upgrade/1.0.1/scripts/upgrade/ncn-upgrade-ceph-nodes.sh ncn-s001
    ```

    > NOTE: You may need to reset the root password for each node after it is rebooted

1. Repeat the previous step for each other storage node, one at a time.

1. After `ncn-upgrade-ceph-nodes.sh` has successfully run for all storage nodes, rescan SSH keys on all storage nodes by running the following commands on `ncn-m001`:
    ```bash
    ncn-m001# grep -oP "(ncn-s\w+)" /etc/hosts |
                sort -u |
                xargs -t -i ssh {} 'truncate --size=0 ~/.ssh/known_hosts'
    ncn-m001# grep -oP "(ncn-s\w+)" /etc/hosts |
                sort -u |
                xargs -t -i ssh {} 'grep -oP "(ncn-s\w+|ncn-m\w+|ncn-w\w+)" /etc/hosts |
                                    sort -u |
                                    xargs -t -i ssh-keyscan -H \{\} >> /root/.ssh/known_hosts'
    ```

1. Deploy `node-exporter` and `alertmanager`.

    **NOTE:** This process will need to run on a node running `ceph-mon`, which in most cases will be `ncn-s001`, `ncn-s002`, and `ncn-s003`. It only needs to be run once, not on every one of these nodes.

    1. Deploy `node-exporter`:

        ```bash
        ncn-s# ceph orch apply node-exporter
        Scheduled node-exporter update...
        ```

    1. Deploy `alertmanager`:

        ```bash
        ncn-s# ceph orch apply alertmanager
        Scheduled alertmanager update...
        ```

    1. Verify `node-exporter` is running:

        **IMPORTANT:** There should be a `node-exporter` container per Ceph node

        ```bash
        ncn-s# ceph orch ps --daemon_type node-exporter
        NAME                    HOST      STATUS         REFRESHED  AGE  VERSION  IMAGE NAME                                       IMAGE ID           CONTAINER ID
        node-exporter.ncn-s001  ncn-s001  running (57m)  3m ago     67m  0.18.1   docker.io/prom/node-exporter:v0.18.1             e5a616e4b9cf       3465eade21da
        node-exporter.ncn-s002  ncn-s002  running (57m)  3m ago     67m  0.18.1   registry.local/prometheus/node-exporter:v0.18.1  e5a616e4b9cf       7ed9b6cc9991
        node-exporter.ncn-s003  ncn-s003  running (57m)  3m ago     67m  0.18.1   registry.local/prometheus/node-exporter:v0.18.1  e5a616e4b9cf       1078d9e555e4

    1. Verify `alertmanager` is running:

        **IMPORTANT:** There should be a single `alertmanager` container for the cluster.

        ```bash
        ncn-s# ceph orch ps --daemon_type alertmanager
        NAME                   HOST      STATUS         REFRESHED  AGE  VERSION  IMAGE NAME                                      IMAGE ID           CONTAINER ID
        alertmanager.ncn-s001  ncn-s001  running (66m)  3m ago     68m  0.20.0   registry.local/prometheus/alertmanager:v0.20.0  0881eb8f169f       775aa53f938f
        ```

1. Update BSS to ensure the Ceph images are loaded if a node is rebuilt.

    ```bash
    ncn-m001# . /usr/share/doc/csm/upgrade/1.0.1/scripts/ceph/lib/update_bss_metadata.sh
    ncn-m001# update_bss_storage
    ```

1. Ensure the ceph services are set to autostart by running the following script on `ncn-s001`:

   ```bash
   ncn-s001# /srv/cray/scripts/common/ceph-enable-services.sh
   ```

 Once `Stage 2` is successfully completed, all the Ceph nodes have been rebooted into the new image. Now proceed to [Stage 3](Stage_3.md).
