# Troubleshoot Ceph Services Not Starting After a Server Crash

## Issue

There is a known issue where the Ceph container images will not start after a power failure or server component failure that causes the server to crash and not boot back up

There will be a message similar to the following in the journalctl logs for the Ceph services on the machine that crashed:

`ceph daemons will not start due to: Error: readlink /var/lib/containers/storage/overlay/l/CXMD7IEI4LUKBJKX5BPVGZLY3Y: no such file or directory`

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
   # ceph orch ps
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
   osd.10                           ncn-s001  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  5d3f372c2164
   osd.11                           ncn-s002  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  c3697f42ee78
   osd.12                           ncn-s003  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  3671a6897993
   osd.13                           ncn-s001  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  35bc02ccd8a6
   osd.14                           ncn-s002  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  a777b16e6e8b
   osd.15                           ncn-s003  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  b725bd38b753
   osd.16                           ncn-s001  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  fa4e211a6632
   osd.17                           ncn-s002  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  ae5cd8b169cc
   osd.2                            ncn-s002  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  abbf4563210b
   osd.3                            ncn-s003  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  765115ca70e8
   osd.4                            ncn-s001  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  ef4186a535df
   osd.5                            ncn-s002  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  d4c96c856f2a
   osd.6                            ncn-s003  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  ff7c0c2a8b66
   osd.7                            ncn-s001  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  c18c09dd115f
   osd.8                            ncn-s002  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  5ea54dfa7cbe
   osd.9                            ncn-s003  running (96m)  2m ago     96m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  0bd8f2e7cbe6
   prometheus.ncn-s001              ncn-s001  running (95m)  2m ago     97m  2.18.1   docker.io/prom/prometheus:v2.18.1                   de242295e225  43c3411ae2cb
   rgw.site1.zone1.ncn-s001.hjmgem  ncn-s001  running (94m)  2m ago     94m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  0f23173da9b0
   rgw.site1.zone1.ncn-s002.eccwzc  ncn-s002  running (94m)  2m ago     94m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  a71878b4847b
   rgw.site1.zone1.ncn-s003.lsmzng  ncn-s003  running (94m)  2m ago     94m  15.2.8   registry.local/ceph/ceph:v15.2.8                    5553b0cb212c  0a5f56e8fc98
   ```

   At this point, the processes are starting/running on the node that crashed; this may take a few minutes.

   If after five mins the services are still reporting down, then fail-over the ceph mgr daemon and re-check the daemons:

   ```bash
   ceph mgr fail $(ceph mgr dump | jq -r .active_name)
   ```

