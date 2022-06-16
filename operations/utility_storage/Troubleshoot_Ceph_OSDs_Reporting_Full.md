# Troubleshoot Ceph OSDs Reporting Full

Use this procedure to examine the Ceph cluster and troubleshoot issues where Ceph runs out of space and the Kubernetes cluster cannot write data. The OSDs need to be reweighed to move data from the drive and get it back under the warning threshold.

When a single OSD for a pool fills up, the pool will go into read-only mode to protect the data. This can occur if the data distribution is unbalanced or if more storage nodes are needed.

Return the Ceph cluster to a healthy state after it reports a full OSD.

## Prerequisites

The commands in this procedure need to be run on a ceph-mon node.

### Procedure

1. View the status of the Ceph cluster.

    ```bash
    ncn-m001# ceph -s
    ```

    Example output:

    ```
      cluster:
        id:     64e553c3-e7d9-4636-81a4-56f26c1b20e1
        health: HEALTH_ERR
              1 full osd(s)
              13 pool(s) full

      services:
        mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 20h)
        mgr: ncn-s003(active, since 9d), standbys: ncn-s001, ncn-s002
        mds: cephfs:1 {0=ncn-s002=up:active} 2 up:standby
        osd: 18 osds: 18 up (since 20h), 18 in (since 9d)
        rgw: 3 daemons active (ncn-s001.rgw0, ncn-s002.rgw0, ncn-s003.rgw0)

      data:
        pools:   13 pools, 288 pgs
        objects: 2.98M objects, 11 TiB
        usage:   32 TiB used, 24 TiB / 56 TiB avail
        pgs:     288 active+clean

      io:
        client:   379 KiB/s rd, 2.2 KiB/s wr, 13 op/s rd, 1 op/s wr
    ```

1. View the Ceph health detail.

    The OSD\_NEARFULL list can have multiple results. Take a note of the returned results to compare with the output of the `ceph osd df` output.

    ```bash
    ncn-m001# ceph health detail
    ```

    Example output:

    ```
    HEALTH_ERR 1 nearfull osd(s); 13 pool(s) nearfull; Degraded data redundancy (low space): 3 pgs backfill_toofull
    OSD_NEARFULL 1 nearfull osd(s)
        osd.9 is near full  <<-- Note this value
    ```

1. View the storage utilization of the cluster and pools.

    ```bash
    ncn-m001# ceph df
    ```

    Example output:

    ```
    RAW STORAGE:
       CLASS    SIZE       AVAIL      USED       RAW USED     %RAW USED
       ssd      56 TiB     24 TiB     32 TiB       32 TiB         57.15
       TOTAL    56 TiB     24 TiB     32 TiB       32 TiB         57.15

    POOLS:
       POOL                           ID     STORED      OBJECTS     USED        %USED     MAX AVAIL
       cephfs_data                     1      39 MiB         387     121 MiB      0.10        39 GiB
       cephfs_metadata                 2     257 MiB         123     770 MiB      0.64        39 GiB
       .rgw.root                       3     3.7 KiB           8     400 KiB         0        39 GiB
       defaults.rgw.buckets.data       4         0 B           0         0 B         0        39 GiB
       default.rgw.control             5         0 B           8         0 B         0        39 GiB
       defaults.rgw.buckets.index      6         0 B           0         0 B         0        39 GiB
       default.rgw.meta                7      22 KiB         114     4.4 MiB         0        39 GiB
       default.rgw.log                 8         0 B         207         0 B         0        39 GiB
       kube                            9     220 GiB      61.88k     661 GiB     84.93        39 GiB
       smf                            10      10 TiB       2.86M      31 TiB     99.63        39 GiB
       default.rgw.buckets.index      11     5.9 MiB          14     5.9 MiB         0        39 GiB
       default.rgw.buckets.data       12     145 GiB      48.11k     436 GiB     78.81        39 GiB
       default.rgw.buckets.non-ec     13     305 KiB          34     1.9 MiB         0        39 GiB
    ```

1. View the utilization of the OSDs to see if data is not balanced across them.

    In the example below, the OSD.9 value is showing that it is 95.17 percent full.

    ```bash
    ncn-m001# ceph osd df
    ```

    Example output:

    ```
    ID CLASS WEIGHT  REWEIGHT SIZE    RAW USE DATA    OMAP     META    AVAIL   %USE  VAR  PGS STATUS
     1   ssd 3.49219  1.00000 3.5 TiB 2.1 TiB 2.1 TiB  6.3 MiB 3.9 GiB 1.4 TiB 60.81 1.06  57     up
     4   ssd 3.49219  1.00000 3.5 TiB 2.0 TiB 2.0 TiB  133 KiB 3.7 GiB 1.5 TiB 57.58 1.01  56     up
     5   ssd 3.49219  1.00000 3.5 TiB 2.1 TiB 2.1 TiB  195 KiB 3.5 GiB 1.4 TiB 61.33 1.07  49     up
     6   ssd 3.49219  1.00000 3.5 TiB 1.2 TiB 1.2 TiB  321 KiB 2.4 GiB 2.3 TiB 33.90 0.59  40     up
     7   ssd 3.49219  1.00000 3.5 TiB 1.5 TiB 1.5 TiB 1012 KiB 2.9 GiB 2.0 TiB 43.03 0.75  39     up
     8   ssd 3.49219  1.00000 3.5 TiB 1.7 TiB 1.7 TiB  194 KiB 4.0 GiB 1.8 TiB 47.96 0.84  47     up
     0   ssd 3.49219  1.00000 3.5 TiB 2.8 TiB 2.8 TiB  485 KiB 5.2 GiB 696 GiB 80.53 1.41  75     up
     **9   ssd 3.49219  1.00000 3.5 TiB 3.3 TiB 3.3 TiB  642 KiB 6.1 GiB 173 GiB 95.17 1.67  67     up**
    10   ssd 3.49219  1.00000 3.5 TiB 1.7 TiB 1.7 TiB  6.7 MiB 3.1 GiB 1.8 TiB 47.74 0.84  68     up
    11   ssd 3.49219  1.00000 3.5 TiB 2.8 TiB 2.8 TiB  1.1 MiB 5.4 GiB 675 GiB 81.14 1.42  78     up
     2   ssd 3.49219  1.00000 3.5 TiB 2.2 TiB 2.2 TiB   27 KiB 4.0 GiB 1.3 TiB 62.14 1.09  40     up
     3   ssd 3.49219  1.00000 3.5 TiB 2.3 TiB 2.3 TiB  445 KiB 4.4 GiB 1.2 TiB 65.90 1.15  55     up
    12   ssd 3.49219  1.00000 3.5 TiB 541 GiB 540 GiB 1006 KiB 1.3 GiB 3.0 TiB 15.14 0.27  48     up
    13   ssd 3.49219  1.00000 3.5 TiB 2.6 TiB 2.6 TiB  176 KiB 4.9 GiB 895 GiB 74.96 1.31  56     up
    14   ssd 3.49219  1.00000 3.5 TiB 1.8 TiB 1.8 TiB  6.4 MiB 3.3 GiB 1.7 TiB 52.03 0.91  48     up
    15   ssd 3.49219  1.00000 3.5 TiB 1.2 TiB 1.2 TiB  179 KiB 2.5 GiB 2.3 TiB 34.44 0.60  41     up
    ```

1. Use the `ceph osd reweight` command on the OSD to move data from the drive and get it back under the warning threshold of 85 percent.

    This command tells Ceph that the drive can now only hold 80 percent of the usable space \(CRUSH weight\).

    ```bash
    ncn-m001# ceph osd reweight osd.9 0.80
    ```

1. Confirm the reweight command made the change.

    In this example, the new reweight is .79999 and the use is now at 80 percent.

    ```bash
    ncn-m001# ceph osd df
    ```

    Example output:

    ```
    ID CLASS WEIGHT  REWEIGHT SIZE    RAW USE DATA    OMAP     META    AVAIL   %USE  VAR  PGS STATUS
     1   ssd 3.49219  1.00000 3.5 TiB 2.1 TiB 2.1 TiB  7.1 MiB 4.7 GiB 1.4 TiB 60.91 1.07  57     up
     4   ssd 3.49219  1.00000 3.5 TiB 2.0 TiB 2.0 TiB  137 KiB 3.7 GiB 1.5 TiB 57.65 1.01  56     up
     5   ssd 3.49219  1.00000 3.5 TiB 2.1 TiB 2.1 TiB  207 KiB 4.0 GiB 1.3 TiB 61.42 1.07  49     up
     6   ssd 3.49219  1.00000 3.5 TiB 1.2 TiB 1.2 TiB  293 KiB 2.4 GiB 2.3 TiB 33.94 0.59  40     up
     7   ssd 3.49219  1.00000 3.5 TiB 1.5 TiB 1.5 TiB 1012 KiB 2.9 GiB 2.0 TiB 43.08 0.75  39     up
     8   ssd 3.49219  1.00000 3.5 TiB 1.7 TiB 1.7 TiB  198 KiB 3.1 GiB 1.8 TiB 48.00 0.84  47     up
     0   ssd 3.49219  1.00000 3.5 TiB 3.0 TiB 3.0 TiB  497 KiB 5.5 GiB 522 GiB 85.40 1.49  80     up
     **9   ssd 3.49219  0.79999 3.5 TiB 2.8 TiB 2.8 TiB  650 KiB 6.1 GiB 687 GiB 80.80 1.41  51     up**
    10   ssd 3.49219  1.00000 3.5 TiB 2.0 TiB 2.0 TiB  7.2 MiB 3.6 GiB 1.5 TiB 57.35 1.00  75     up
    11   ssd 3.49219  1.00000 3.5 TiB 2.8 TiB 2.8 TiB  1.1 MiB 5.3 GiB 664 GiB 81.43 1.42  82     up
     2   ssd 3.49219  1.00000 3.5 TiB 2.2 TiB 2.2 TiB   31 KiB 4.0 GiB 1.3 TiB 62.22 1.09  40     up
     3   ssd 3.49219  1.00000 3.5 TiB 2.3 TiB 2.3 TiB  457 KiB 4.2 GiB 1.2 TiB 65.98 1.15  55     up
    12   ssd 3.49219  1.00000 3.5 TiB 542 GiB 541 GiB  990 KiB 1.3 GiB 3.0 TiB 15.16 0.27  48     up
    13   ssd 3.49219  1.00000 3.5 TiB 2.6 TiB 2.6 TiB  196 KiB 4.9 GiB 892 GiB 75.05 1.31  56     up
    14   ssd 3.49219  1.00000 3.5 TiB 1.8 TiB 1.8 TiB  7.1 MiB 3.3 GiB 1.7 TiB 52.10 0.91  48     up
    15   ssd 3.49219  1.00000 3.5 TiB 1.2 TiB 1.2 TiB  171 KiB 2.7 GiB 2.3 TiB 34.48 0.60  41     up
                        TOTAL  56 TiB  32 TiB  32 TiB   27 MiB  62 GiB  24 TiB 57.19
    MIN/MAX VAR: 0.27/1.49  STDDEV: 18.51
    ```

1. Monitor the Ceph cluster during recovery.

    ```bash
    ncn-m001# ceph -s
    ```
