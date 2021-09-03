# Manage Ceph Services

The following commands are required to start, stop, or restart Ceph services. Restarting Ceph services is helpful for troubleshoot issues with the utility storage platform.

## List Ceph services

```bash
ncn-s00(1/2/3)# ceph orch ps
NAME                             HOST      STATUS        REFRESHED  AGE  VERSION  IMAGE NAME                        IMAGE ID      CONTAINER ID
mds.cephfs.ncn-s001.zwptsg       ncn-s001  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  bb08bcb2f034
mds.cephfs.ncn-s002.qyvoyv       ncn-s002  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  32c3ff10be42
mds.cephfs.ncn-s003.vvsuvy       ncn-s003  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  e172b979c747
mgr.ncn-s001                     ncn-s001  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  ad887936d37f
mgr.ncn-s002                     ncn-s002  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  80902ae9010c
mgr.ncn-s003                     ncn-s003  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  28700bb4053e
mon.ncn-s001                     ncn-s001  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  af8d64f9df8a
mon.ncn-s002                     ncn-s002  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  698557732bf4
mon.ncn-s003                     ncn-s003  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  27421ddd81bd
osd.0                            ncn-s003  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  97f4f922edc7
osd.1                            ncn-s002  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  69d11a7ddecb
osd.10                           ncn-s002  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  aa054d15d4ab
osd.11                           ncn-s001  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  b3814f3348ed
osd.2                            ncn-s001  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  998c334e41c6
osd.3                            ncn-s002  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  da2daa780fd0
osd.4                            ncn-s003  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  b831003fdf32
osd.5                            ncn-s001  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  6850b49c9bc1
osd.6                            ncn-s003  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  6aeb8b274212
osd.7                            ncn-s002  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  4eb2f577daba
osd.8                            ncn-s001  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  f0386c093874
osd.9                            ncn-s003  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  50d7066f66a6
rgw.site1.zone1.ncn-s001.xtjggh  ncn-s001  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  6a90ba6415e6
rgw.site1.zone1.ncn-s002.divvfs  ncn-s002  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  825c5b5f33c5
rgw.site1.zone1.ncn-s003.spojqa  ncn-s003  running (3d)  7m ago     3d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  f95116a16e41
```

## Ceph Monitor Service (ceph-mon)

**`IMPORTANT:`** All of the below ceph orch commands should be run from `ncn-s001/2/3` or `ncn-m001/2/3`.

Start the ceph-mon service:

```bash
# Please note the the mon process can have a container id appended to the end of the host name. So please make sure to use the output from above to ensure you have the correct name.

ncn-s00(1/2/3)# ceph orch daemon start mon.<hostname>
```

Stop the ceph-mon service:

```bash
ncn-s00(1/2/3)# ceph orch daemon stop mon.<hostname>
```

Restart the ceph-mon service:

```bash
ncn-s00(1/2/3)# ceph orch daemon restart mon.<hostname>
```

## Ceph OSD Service (ceph-osd)

Start the ceph-osd service:

```bash
ncn-s00(1/2/3)# ceph orch daemon start osd.<number>
```

Stop the ceph-osd service:

```bash
nncn-s00(1/2/3)# ceph orch daemon stop osd.<number>
```

Restart the ceph-osd service:

```bash
ncn-s00(1/2/3)# ceph orch daemon restart osd.<number>
```

## Ceph Manager Service (ceph-mgr)

Start the ceph-mgr service:

```bash
ncn-s00(1/2/3)# ceph orch daemon start mgr.<hostname>
```

Stop the ceph-mgr service:

```bash
ncn-s00(1/2/3)# ceph orch daemon stop mgr.<hostname>
```

Restart the ceph-mgr service:

```bash
ncn-s00(1/2/3)# ceph orch daemon restart mgr.<hostname>
```

## Ceph MDS Service (cephfs)

Start the ceph-mgr service:

```bash
ncn-s00(1/2/3)# ceph orch daemon start mds.cephfs.<container id from ceph orch ps output>
```

Stop the ceph-mgr service:

```bash
ncn-s00(1/2/3)# ceph orch daemon stop mds.cephfs.<container id from ceph orch ps output>
```

Restart the ceph-mgr service:

```bash
ncn-s00(1/2/3)# ceph orch daemon restart mds.cephfs.<container id from ceph orch ps output>
```

## Ceph Rados-Gateway Service (ceph-radosgw)

Start the rados-gateway:

```bash
ncn-s00(1/2/3)# ceph orch daemon start rgw.site1.zone1.<container id from ceph orch ls>
```

Stop the rados-gateway:

```bash
ncn-s00(1/2/3)# ceph orch daemon stop rgw.site1.zone1.<container id from ceph orch ls>
```

Restart the rados-gateway:

```bash
ncn-s00(1/2/3)# ceph orch daemon restart rgw.site1.zone1.<container id from ceph orch ls>
```

## Ceph Service restart using CEPHADM

**Important:** This command needs to run from the host you are going to start or stop services on.

- Get the service system_unit

```bash
ncn-s# cephadm ls
    {
        "style": "cephadm:v1",
        "name": "mgr.ncn-s001",
        "fsid": "01a0d9d2-ea7f-43dc-af25-acdfa5242a48",
        "systemd_unit": "ceph-01a0d9d2-ea7f-43dc-af25-acdfa5242a48@mgr.ncn-s001",
        "enabled": false,
        "state": "running",
        "container_id": "ad887936d37fd87999b140c366ef288443faf03e869219bdd282b5825be14d6e",
        "container_image_name": "registry.local/ceph/ceph:v15.2.8",
        "container_image_id": "5553b0cb212ca2aa220d33ba39d9c602c8412ce6c5febc57ef9cdc9c5844b185",
        "version": "15.2.8",
        "started": "2021-06-17T22:41:45.132838Z",
        "created": "2021-06-17T22:17:51.063202Z",
        "deployed": "2021-06-17T22:16:03.898845Z",
        "configured": "2021-06-17T22:41:07.807004Z"
    },
```

- restart the service

```bash
ncn-s# systemctl restart ceph-01a0d9d2-ea7f-43dc-af25-acdfa5242a48@mgr.ncn-s001
```

## Ceph Manager Modules

**Location:** Ceph manager modules can be enabled or disabled from any ceph-mon nodes.

Enable Ceph manager modules:

```bash
ncn-m001# ceph mgr MODULE_NAME enable MODULE
```

Disable Ceph manager modules:

```bash
ncn-m001# ceph mgr MODULE_NAME disable MODULE
```

## Scale Ceph services

  We can use the ability to deploy/scale/reconfigure/redeploy Ceph processes down and back up to restart the services.

  **IMPORTANT:** When scaling the Ceph manager daemon (mgr.hostname.<containerid>), you need to keep in mind that you need to have a running manager daemon as it is what is controlling the orchestration processes.

  **IMPORTANT:** You cannot scale osd.all-available-devices, this is the process to auto-discover available OSDs.

  **IMPORTANT:** You cannot scale the crash service; this is the equivalent of a Kubernetes daemon set and runs on all nodes to collect crash data.

  ***For our example we are going to show scaling the mgr service down and back up.***

  You will need two SSH sessions. One to do the work from and another that is running `watch ceph -s` so you can monitor the progress.

  1. List your services

     ```bash
     ncn-s001:~ # ceph orch ls
     NAME                       RUNNING  REFRESHED  AGE  PLACEMENT                                                      IMAGE NAME                        IMAGE ID
     crash                          6/6  9s ago     4d   *                                                              registry.local/ceph/ceph:v15.2.8  5553b0cb212c
     mds.cephfs                     3/3  9s ago     4d   ncn-s001;ncn-s002;ncn-s003;count:3                             registry.local/ceph/ceph:v15.2.8  5553b0cb212c
     mgr                            3/3  9s ago     4d   ncn-s001;ncn-s002;ncn-s003;count:3                             registry.local/ceph/ceph:v15.2.8  5553b0cb212c
     mon                            3/3  9s ago     4d   ncn-s001;ncn-s002;ncn-s003;count:3                             registry.local/ceph/ceph:v15.2.8  5553b0cb212c
     osd.all-available-devices      6/6  9s ago     4d    *                                                              registry.local/ceph/ceph:v15.2.8   5553b0cb212c
     rgw.site1.zone1                3/3  9s ago     4d   ncn-s001;ncn-s002;ncn-s003;ncn-s004;ncn-s005;ncn-s006;count:3  registry.local/ceph/ceph:v15.2.8  5553b0cb212c

     ```

     - Optionally you can limit the results.
       ceph orch [<service_type>] [<service_name>] [--export] [plain|json|json-pretty|yaml] [--refresh]

       ```bash
       ncn-s001:~ # ceph orch ls mgr
       NAME  RUNNING  REFRESHED  AGE  PLACEMENT                           IMAGE NAME                        IMAGE ID
       mgr       3/3  17s ago    4d   ncn-s001;ncn-s002;ncn-s003;count:3  registry.local/ceph/ceph:v15.2.8  5553b0cb212c
       ```

       - From this we can get our placement of the services.


  1. Choose the service you want to scale. ***(reminder the example will use the MGR service)***
     1. If you are scaling mds or mgr daemons then you will want to make sure you are failing over the active mgr/mds daemon so you always have one running.

     ```bash
     # To get the active MDS

     ncn-s# ceph fs status -f json-pretty|jq -r '.mdsmap[]|select(.state=="active")|.name'

     cephfs.ncn-s001.juehkw <-- current active MDS. note this will change when you fail it over so keep this command handy

     # To get the active MGR

     ncn-s# ceph mgr dump | jq -r .active_name

     ncn-s002.fumzfm  <-- current active MGR. note this will change when you fail it over so keep this command handy
     ```

  1. Now we have our service, the current placement policy, and if applicable the active MGR/MDS daemon

  1. Scale the service

     ```bash
     ceph orch apply --placement="1 <host where the active mgr is running>"

     example:
     ncn-s001:~ # ceph orch apply mgr --placement="1 ncn-s002"
     Scheduled mgr update...
     ```

  1. Watch your SSH session that is showing the Ceph status (`ceph -s`)

     ```bash
     ncn-s001:~ # ceph -s
     cluster:
      id:     11d5d552-cfac-11eb-ab69-fa163ec012bf
      health: HEALTH_OK

     services:
      mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 70s)
      mgr: ncn-s002.fumzfm(active, since 14s)
      mds: cephfs:1 {0=cephfs.ncn-s001.juehkw=up:active} 1 up:standby-replay 1 up:standby
      osd: 6 osds: 6 up (since 4d), 6 in (since 4d)
      rgw: 2 daemons active (site1.zone1.ncn-s005.hzfbkd, site1.zone1.ncn-s006.vjuwkf)

     task status:

     data:
      pools:   7 pools, 193 pgs
      objects: 256 objects, 7.5 MiB
      usage:   9.1 GiB used, 261 GiB / 270 GiB avail
      pgs:     193 active+clean

     io:
      client:   663 B/s rd, 1 op/s rd, 0 op/s wr

     ```

     Note that our mgr service is now showing 1 active on the node we chose.

  1. Scale the service back up to 3 mgrs.

     ```bash
     ncn-s001:~ # ceph orch apply mgr --placement="3 ncn-s001 ncn-s002 ncn-s003"
     Scheduled mgr update...
     ```

  1. When you see your Ceph status output shows you have 3 running mgr daemons then you can scale down the last daemon back down and up.
      - **IF it is the MDS or MGR daemons then REMEMBER we have to fail over the active daemon**

     ```bash
     ncn-s001:~ # ceph mgr fail ncn-s002.fumzfm   # This was our active MGR.
     ```

     in your Ceph status output you should see the ACTIVE ceph mgr process change.

     ```bash
     mgr: ncn-s003.wtvbtz(active, since 2m), standbys: ncn-s001.cgbxdw
     ```

  1. Finally scale your service back to its original deployment size
     ```bash
     ncn-s001:~ # ceph orch apply mgr  --placement="3 ncn-s001 ncn-s002 ncn-s003"
     Scheduled mgr update...
     ```

   1. Monitor the Ceph status to make sure all your daemons come back online.
