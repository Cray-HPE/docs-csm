# Add Ceph OSDs

**`IMPORTANT:`** This document is addressing how to add an OSD when the `OSD auto-discovery` fails to add in new drives.

Check to ensure you have OSD auto-discovery enabled.

```bash
ncn-s00(1/2/3)# ceph orch ls osd
```

Example output:

```bash
NAME                       RUNNING  REFRESHED  AGE  PLACEMENT  IMAGE NAME                        IMAGE ID
osd.all-available-devices      9/9  4m ago     3d   *          registry.local/ceph/ceph:v15.2.8  5553b0cb212c
```

>**`NOTE`** Ceph version 15.2.x and newer will utilize the ceph orchestrator to add any available drives on the storage nodes to the OSD pool. The process below is in the event that the orchestrator did not add the available drives into the cluster

## Prerequisites

This procedure requires administrative privileges and will require at least two windows.

## Procedure

1. In the first window, log in as `root` on the first master node \(`ncn-m001`\).

    ```bash
    ssh ncn-m001
    ```

1. Watch the status of the cluster to monitor the progress of the drives being added.

    The following example shows only six OSDs in use.

    ```bash
    watch -n 10 ceph -s
    ```

    Example output:

    ```bash
      cluster:
        id: 5b359a58-e6f7-4f0c-98b8-f528f620896a
        health: HEALTH_OK

      services:
        mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 20h)
        mgr: ncn-s003(active, since 9d), standbys: ncn-s001, ncn-s002
        mds: cephfs:1 {0=ncn-s002=up:active} 2 up:standby
        osd: 18 osds: 18 up (since 20h), 18 in (since 9d)
        rgw: 3 daemons active (ncn-s001.rgw0, ncn-s002.rgw0, ncn-s003.rgw0)

      data:
        pools:   11 pools, 220 pgs
        objects: 826.23k objects, 944 GiB
        usage:   2.0 TiB used, 61 TiB / 63 TiB avail
        pgs:     220 active+clean

      io:
        client:   1.7 KiB/s rd, 12 MiB/s wr, 1 op/s rd, 1.32k op/s wr
    ```

1. In the second window, log into ncn-s00(1/2/3) or an ncn-m node and fail over the mgr process.
    1. There is an issue where orchestration tasks can get hung up and the failover will clear that up.

    ```bash
    ceph mgr fail $(ceph mgr dump | jq -r .active_name)
    ```

1. In the second window, list your available drives on the node(s) where the OSDs are missing

   The following example is utilizing ncn-s001. Ensure the correct host for the situation is used.

   ```bash
   ceph orch device ls
   ```

   Example output:

   ```bash
   ceph orch device ls ncn-s001
   Hostname  Path      Type  Serial                Size   Health   Ident  Fault  Available
   ncn-s001  /dev/sdb  hdd   f94bd091-cc25-476b-9  48.3G  Unknown  N/A    N/A    No
   ```

   > **`NOTE`** The drive in question is reporting available. The following steps are going to erase that drive so PLEASE make sure to verify that drive is not being used.

   ```bash
   podman ps
   ```

   Example output:

   ```bash
   CONTAINER ID  IMAGE                             COMMAND               CREATED                 STATUS                     PORTS   NAMES
   596d1c235da8  registry.local/ceph/ceph:v15.2.8  -n client.rgw.sit...  Less than a second ago  Up Less than a second ago          ceph-11d5d552-cfac-11eb-ab69-fa163ec012bf-rgw.site1.ncn-s001.oztynu
   eecfac35fe7c  registry.local/ceph/ceph:v15.2.8  -n mon.ncn-s001 -...  2 seconds ago           Up 2 seconds ago                   ceph-11d5d552-cfac-11eb-ab69-fa163ec012bf-mon.ncn-s001
   3140f5062945  registry.local/ceph/ceph:v15.2.8  -n mgr.ncn-s001.b...  17 seconds ago          Up 17 seconds ago                  ceph-11d5d552-cfac-11eb-ab69-fa163ec012bf-mgr.ncn-s001.bfdept
   3d25564047e1  registry.local/ceph/ceph:v15.2.8  -n mds.cephfs.ncn...  3 days ago              Up 3 days ago                      ceph-11d5d552-cfac-11eb-ab69-fa163ec012bf-mds.cephfs.ncn-s001.juehkw
   4ebd6db27d08  registry.local/ceph/ceph:v15.2.8  -n osd.2 -f --set...  4 days ago              Up 4 days ago                      ceph-11d5d552-cfac-11eb-ab69-fa163ec012bf-osd.2
   96c6e11677f0  registry.local/ceph/ceph:v15.2.8  -n client.crash.n...  4 days ago              Up 4 days ago                      ceph-11d5d552-cfac-11eb-ab69-fa163ec012bf-crash.ncn-s001

   ```

   If you find an Running OSD container then we should assume that the drive is being used or might have critical data on it. If you know this to 100% not be the case (example a rebuild), then you can proceed.

   Repeat this step for all drives on the storage node\(s\) that have unused storage which should be added to Ceph.

   ```bash
   ceph orch device zap ncn-s001 /dev/sdb (optional --force)
   ```

   Proceed to the next step after all of the OSDs have been added to the storage nodes.

1. In the first window, check how many OSDs are available.

    The following example shows 18 OSDs in use.

    ```bash
    cluster:
    id: 5b359a58-e6f7-4f0c-98b8-f528f620896a
    health: HEALTH_ERR
    Degraded data redundancy (low space): 3 pgs backfill_toofull
    services:
    mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 20h)
    mgr: ncn-s003(active, since 9d), standbys: ncn-s001, ncn-s002
    mds: cephfs:1 {0=ncn-s002=up:active} 2 up:standby
    {0=ncn-m002=up:active}
    2 up:standby
    osd: 18 osds: 18 up (since 20h), 18 in (since 9d)
    rgw: 3 daemons active (ncn-s001.rgw0, ncn-s002.rgw0, ncn-s003.rgw0)
    data:
    pools: 11 pools, 204 pgs
    objects: 70.98k objects, 241 GiB
    usage: 547 GiB used, 62 TiB / 63 TiB avail
    pgs: 39582/212949 objects misplaced (18.588%)
    163 active+clean
    36 active+remapped+backfill_wait
    3 active+remapped+backfill_wait+backfill_toofull
    2 active+remapped+backfilling
    io:
    client: 20 MiB/s wr, 0 op/s rd, 807 op/s wr
    recovery: 559 MiB/s, 187 objects/s
    ```

   ```bash
   ceph orch ps --daemon_type osd ncn-s001
   ```

   Example output:

   ```bash
   NAME   HOST      STATUS        REFRESHED  AGE  VERSION  IMAGE NAME                        IMAGE ID      CONTAINER ID
   osd.2  ncn-s001  running (4d)  20s ago    4d   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  4ebd6db27d08
   ```

1. Reset the pool quotas.

   This step is only necessary when the cluster capacity has increased.

   ```bash
   ncn-s00(1/2/3)# source /srv/cray/scripts/common/fix_ansible_inv.sh
   ncn-s00(1/2/3)# fix_inventory
   ncn-s00(1/2/3)# source /etc/ansible/boto3_ansible/bin/activate
   ncn-s00(1/2/3)# ansible-playbook /etc/ansible/ceph-rgw-users/ceph-pool-quotas.yml
   ncn-s00(1/2/3)# deactivate
   ```
