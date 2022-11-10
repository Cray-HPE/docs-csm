# Troubleshoot Ceph Services Not Starting After a Server Crash

## Issue

There is a known issue where the Ceph container images will not start after a power failure or server component failure that causes the server to crash and not boot back up

There will be a message similar to the following in the `journalctl` logs for the Ceph services on the machine that crashed:

```screen
ceph daemons will not start due to: Error: readlink /var/lib/containers/storage/overlay/l/CXMD7IEI4LUKBJKX5BPVGZLY3Y: no such file or directory
```

When the issue materializes, then it is highly likely the Ceph container images have been corrupted.

## Fix

1. Remove the corrupted images.

   ```bash
   for i in $(podman images|grep -v REPO|awk {'print $1":"$2'}); do podman image rm $i; done
   ```

1. Reload the images.

   ```bash
   /srv/cray/scripts/common/pre-load-images.sh
   ```

1. Validate that the services are starting.

   ```bash
   ncn-s00(1/2/3)# ceph orch ps
   ```

   Example output:

   ```screen
   NAME                             HOST      STATUS         REFRESHED  AGE  VERSION  IMAGE NAME                                       IMAGE    ID      CONTAINER ID
   alertmanager.ncn-s001            ncn-s001  running (95m)  2m ago     97m  0.20.0   registry.local/prometheus/alertmanager:v0.20.0      0881eb8f169f  a3fbad5afe50
   crash.ncn-s001                   ncn-s001  running (97m)  2m ago     97m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  ddc724e9a18e
   crash.ncn-s002                   ncn-s002  running (97m)  2m ago     97m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  3925895be42d
   crash.ncn-s003                   ncn-s003  running (97m)  2m ago     97m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  b9eb9f3582f7
   grafana.ncn-s001                 ncn-s001  running (97m)  2m ago     97m  6.6.2    registry.local/ceph/ceph-grafana:6.6.2              a0dce381714a  269fd70c881f
   mds.cephfs.ncn-s001.dkpjnt       ncn-s001  running (95m)  2m ago     95m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  600c4a5513e5
   mds.cephfs.ncn-s002.nyirpe       ncn-s002  running (95m)  2m ago     95m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  6c9295a5a795
   mds.cephfs.ncn-s003.gqxuoc       ncn-s003  running (95m)  2m ago     95m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  c92990c970f4
   mgr.ncn-s001.lhjrhi              ncn-s001  running (98m)  2m ago     98m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  e85dbd963f0d
   mgr.ncn-s002.hvqjgu              ncn-s002  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  a9ba72dfde66
   mgr.ncn-s003.zqoych              ncn-s003  running (97m)  2m ago     97m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  a33f6f1a265c
   mon.ncn-s001                     ncn-s001  running (98m)  2m ago     99m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  53245f1e60b7
   mon.ncn-s002                     ncn-s002  running (97m)  2m ago     97m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  cdbda41fc32e
   mon.ncn-s003                     ncn-s003  running (97m)  2m ago     97m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  24578b34f6cd
   node-exporter.ncn-s001           ncn-s001  running (97m)  2m ago     97m  0.18.1   registry.local/prometheus/node-exporter:v0.18.1     e5a616e4b9cf  79617e2d92ed
   node-exporter.ncn-s002           ncn-s002  running (97m)  2m ago     97m  0.18.1   registry.local/prometheus/node-exporter:v0.18.1     e5a616e4b9cf  d5a93a7ab603
   node-exporter.ncn-s003           ncn-s003  running (96m)  2m ago     96m  0.18.1   registry.local/prometheus/node-exporter:v0.18.1     e5a616e4b9cf  8ba07c965a83
   osd.0                            ncn-s003  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  9dd55acc0475
   osd.1                            ncn-s001  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  08548417e7ea

   [...]
   ```

   At this point, the processes are starting/running on the node that crashed; this may take a few minutes.

   If after five minutes the services are still reporting down, then fail-over the Ceph mgr daemon and re-check the daemons:

   ```bash
   ceph mgr fail $(ceph mgr dump | jq -r .active_name)
   ```

## Services not starting due to `ssh` keys not cached on nodes

```bash
num_storage_nodes=$(ceph node ls|jq -r '.osd|keys|length')
ceph cephadm get-pub-key > /etc/ceph/ceph.pub
for node in $(seq 1 $num_storage_nodes); do
   nodename=$(printf "ncn-s%03d" $node)
   ssh-keyscan -t rsa -H $nodename >> ~/.ssh/known_hosts
done
```

It is recommended to also clear the local cache entries in the `known_host` files on the nodes.

```bash
for node in $(seq 1 "$num_storage_nodes"); do
    nodename=$(printf "ncn-s%03d" "$node")
    ssh-keyscan -H "$nodename" >> ~/.ssh/known_hosts
done

for node in $(seq 1 "$num_storage_nodes"); do
 nodename=$(printf "ncn-s%03d.nmn" "$node")
 ssh-keyscan -H "$nodename" >> ~/.ssh/known_hosts
done
```
