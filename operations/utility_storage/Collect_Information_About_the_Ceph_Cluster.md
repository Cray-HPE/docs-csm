# Collect Information about the Ceph Cluster

These general commands for Ceph are helpful for obtaining information pertinent to troubleshooting issues.

As a reference, the Ceph commands below are run from a ceph-mon node. Certain commands will work on different systems. For example, the `rbd` command can be used on the worker nodes if specifying the proper key.

## Ceph Log and File Locations

- Ceph configurations are located under /etc/ceph/ceph.conf
- Ceph data structure and bootstrap is located under /var/lib/ceph/<fsid>/
- Ceph logs are now accessible by a couple of different methods
  - Utilizing `cephadm ls` to retrieve the systemd_unit on the node for the process, then utilize `journalctl` to dump the logs
  - `ceph log last [<num:int>] [debug|info|sec|warn|error] [*|cluster|audit|cephadm]`
    - Note that that this will dump general cluster logs
  - `cephadm logs [-h] [--fsid FSID] --name <systemd_unit>`

## Check the Status of Ceph

Print the status of the Ceph cluster with the following command:

```bash
ncn-m001# ceph -s
  cluster:
  id:     5f3b4031-d6c0-4118-94c0-bffd90b534eb
  health: HEALTH_OK  <<-- WARN/ERROR/CRITICAL are other states

  services:
    mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 20h) <<-- Should have quorum and ideally an odd number of mon nodes
    mgr: ncn-s003(active, since 9d), standbys: ncn-s001, ncn-s002 <<-- The watchdog for the cluster
    mds: cephfs:1 {0=ncn-s002=up:active} 2 up:standby <<-- Filesystem service
    osd: 18 osds: 18 up (since 20h), 18 in (since 9d) <<-- Data devices: 1 OSD = 1 hard drive designated for Ceph
    rgw: 3 daemons active (ncn-s001.rgw0, ncn-s002.rgw0, ncn-s003.rgw0) <<-- Object storage

  data: <<-- Health stats related to the above services
    pools:   11 pools, 220 pgs
    objects: 825.66k objects, 942 GiB
    usage:   2.0 TiB used, 61 TiB / 63 TiB avail
    pgs:     220 active+clean

  io:
    client:   2.5 KiB/s rd, 13 MiB/s wr, 2 op/s rd, 1.27k op/s wr
```

The `-w` option can be used to watch the cluster.

### Print the OSD tree

Check the OSD status, weight, and location.

```bash
ncn-m001# ceph osd tree
ID CLASS WEIGHT   TYPE NAME         STATUS REWEIGHT PRI-AFF
-1       62.85938 root default
-7       20.95312     host ncn-s001
 1   ssd  3.49219         osd.1         up  1.00000 1.00000
 5   ssd  3.49219         osd.5         up  1.00000 1.00000
 6   ssd  3.49219         osd.6         up  1.00000 1.00000
 7   ssd  3.49219         osd.7         up  1.00000 1.00000
 8   ssd  3.49219         osd.8         up  1.00000 1.00000
 9   ssd  3.49219         osd.9         up  1.00000 1.00000
-5       20.95312     host ncn-s002
 2   ssd  3.49219         osd.2         up  1.00000 1.00000
 4   ssd  3.49219         osd.4         up  1.00000 1.00000
10   ssd  3.49219         osd.10        up  1.00000 1.00000
11   ssd  3.49219         osd.11        up  1.00000 1.00000
12   ssd  3.49219         osd.12        up  1.00000 1.00000
13   ssd  3.49219         osd.13        up  1.00000 1.00000
-3       20.95312     host ncn-s003
 0   ssd  3.49219         osd.0         up  1.00000 1.00000
 3   ssd  3.49219         osd.3         up  1.00000 1.00000
14   ssd  3.49219         osd.14        up  1.00000 1.00000
15   ssd  3.49219         osd.15        up  1.00000 1.00000
16   ssd  3.49219         osd.16        up  1.00000 1.00000
17   ssd  3.49219         osd.17        up  1.00000 1.00000
```

### Storage Utilization

The following command shows the storage utilization of the cluster and pools:

```bash
ncn-m001# ceph df
RAW STORAGE:
    CLASS     SIZE       AVAIL      USED        RAW USED     %RAW USED
    kube      27 GiB     15 GiB     9.2 GiB       12 GiB         45.25
    smf       57 GiB     30 GiB      24 GiB       27 GiB         48.09
    TOTAL     84 GiB     44 GiB      34 GiB       40 GiB         47.18

POOLS:
    POOL                           ID     STORED      OBJECTS     USED        %USED     MAX AVAIL
    cephfs_data                     1         0 B           0         0 B         0        13 GiB
    cephfs_metadata                 2     2.2 KiB          22     1.5 MiB         0        13 GiB
    .rgw.root                       3     1.2 KiB           4     768 KiB         0        13 GiB
    defaults.rgw.buckets.data       4         0 B           0         0 B         0        13 GiB
    default.rgw.control             5         0 B           8         0 B         0        13 GiB
    defaults.rgw.buckets.index      6         0 B           0         0 B         0        13 GiB
    default.rgw.meta                7         0 B           0         0 B         0        13 GiB
    default.rgw.log                 8         0 B         175         0 B         0        13 GiB
    kube                           10     3.1 GiB         799     9.2 GiB     40.64       4.5 GiB
    smf                            11     8.1 GiB       2.11k      24 GiB     47.71       8.9 GiB
```

### Show OSD Usage

Show the utilization of the OSDs with the following command. This is very helpful to see if the data is not balanced across OSDs, which can create hotspots.

```bash
ncn-m001# ceph osd df
ID CLASS WEIGHT  REWEIGHT SIZE   RAW USE DATA    OMAP META  AVAIL   %USE  VAR  PGS STATUS
 1  kube 0.00879  1.00000  9 GiB 4.1 GiB 3.1 GiB  0 B 1 GiB 4.9 GiB 45.25 0.96  99     up
 4   smf 0.01859  1.00000 19 GiB 9.1 GiB 8.1 GiB  0 B 1 GiB 9.9 GiB 48.09 1.02 141     up
 0  kube 0.00879  1.00000  9 GiB 4.1 GiB 3.1 GiB  0 B 1 GiB 4.9 GiB 45.25 0.96  93     up
 3   smf 0.01859  1.00000 19 GiB 9.1 GiB 8.1 GiB  0 B 1 GiB 9.9 GiB 48.09 1.02 147     up
 2  kube 0.00879  1.00000  9 GiB 4.1 GiB 3.1 GiB  0 B 1 GiB 4.9 GiB 45.25 0.96 100     up
 5   smf 0.01859  1.00000 19 GiB 9.1 GiB 8.1 GiB  0 B 1 GiB 9.9 GiB 48.09 1.02 140     up
                    TOTAL 84 GiB  40 GiB  34 GiB  0 B 6 GiB  44 GiB 47.18
MIN/MAX VAR: 0.96/1.02  STDDEV: 1.51
```

### Check the Status of a Single OSD

Use the following command to obtain information about a single OSD using the OSD number. For example, osd.0 would be an OSD number.

```bash
ncn-m001# ceph osd find OSD.ID
{
    "osd": 1,
    "addrs": {
        "addrvec": [
            {
                "type": "v1",
                "addr": "10.248.2.127:6800",
                "nonce": 4966
            }
        ]
    },
    "osd_fsid": "9d41f723-e86f-4b98-b1e7-12c0f5f15546",
    "host": "ceph-1",
    "crush_location": {
        "host": "ceph-1",
        "root": "default"
    }
}
```

### List Storage Pools

List the storage pools with the following commands:

```bash
ncn-m001# ceph osd lspools
1 cephfs_data
2 cephfs_metadata
3 .rgw.root
4 defaults.rgw.buckets.data
5 default.rgw.control
6 defaults.rgw.buckets.index
7 default.rgw.meta
8 default.rgw.log
10 kube
11 smf
```

