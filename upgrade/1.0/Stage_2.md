# Stage 2 - Ceph image upgrade

For each storage node in the cluster, start by following the steps:

```bash
ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-ceph-nodes.sh ncn-s001
```

> NOTE: Run the script once each for all storage nodes. Follow output of the script carefully. The script will pause for manual interaction
> Note that these steps should be performed on one storage node at a time.

After the last storage node has been rebooted you will need to deploy node-exporter and alertmanager

**NOTE:** This process will need to run on a node running ceph-mon, which in most cases will be ncn-s00(1/2/3)
**NOTE:** You may need to reset the root password for each node after it is rebooted

1. Load the images into podman.

    ```bash
    ncn-s# export num_storage_nodes=$(craysys metadata get num-storage-nodes)
    ncn-s# for node in $(seq 1 $num_storage_nodes); do
      nodename=$(printf "ncn-s%03d" $node)
      ssh "$nodename" /srv/cray/scripts/common/pre-load-images.sh
    done
    ```

1. Deploy node-exporter and alertmanager

    ```bash
    ncn-s00(1/2/3)# ceph orch apply node-exporter
    Scheduled node-exporter update...

    ncn-s00(1/2/3)# ceph orch apply alertmanager
    Scheduled alertmanager update...
    ```

1. Verify node-exporter and alertmanager are running

    ```bash
    ncn-s00(1/2/3)# ceph orch ps --daemon_type node-exporter
     NAME                    HOST      STATUS         REFRESHED  AGE  VERSION  IMAGE NAME                                       IMAGE ID           CONTAINER ID
     node-exporter.ncn-s001  ncn-s001  running (57m)  3m ago     67m  0.18.1   docker.io/prom/node-exporter:v0.18.1             e5a616e4b9cf       3465eade21da
     node-exporter.ncn-s002  ncn-s002  running (57m)  3m ago     67m  0.18.1   registry.local/prometheus/node-exporter:v0.18.1  e5a616e4b9cf       7ed9b6cc9991
     node-exporter.ncn-s003  ncn-s003  running (57m)  3m ago     67m  0.18.1   registry.local/prometheus/node-exporter:v0.18.1  e5a616e4b9cf       1078d9e555e4

     ncn-s00(1/2/3)# ceph orch ps --daemon_type alertmanager
     NAME                   HOST      STATUS         REFRESHED  AGE  VERSION  IMAGE NAME                                      IMAGE ID           CONTAINER ID
     alertmanager.ncn-s001  ncn-s001  running (66m)  3m ago     68m  0.20.0   registry.local/prometheus/alertmanager:v0.20.0  0881eb8f169f       775aa53f938f
     ```

  **IMPORTANT:** There should be a node-exporter container per ceph node and a single alertmanager container for the cluster.

  Once `Stage 2` is completed and all the ceph node have been rebooted into the new image, then please proceed to [Stage 3](Stage_3.md)