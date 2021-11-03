# Troubleshoot Large Object Map Objects in Ceph Health

Troubleshoot an issue where Ceph reports a HEALTH\_WARN of 1 large omap objects. Adjust the omap object key threshold or number of placement groups \(PG\) to resolve this issue.

## Prerequisites

Ceph health is reporting a HEALTH\_WARN for large Object Map \(omap\) objects.

```bash
ncn-m001# ceph -s
  cluster:
    id:     464f8ee0-667d-49ac-a82b-43ba8d377f81
    health: HEALTH_WARN
            1 large omap objects
            clock skew detected on mon.ncn-m002, mon.ncn-m003

  services:
    mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 20h)
    mgr: ncn-s003(active, since 9d), standbys: ncn-s001, ncn-s002
    mds: cephfs:1 {0=ncn-s002=up:active} 2 up:standby
    osd: 18 osds: 18 up (since 20h), 18 in (since 9d)
    rgw: 3 daemons active (ncn-s001.rgw0, ncn-s002.rgw0, ncn-s003.rgw0)


  data:
    pools:   11 pools, 600 pgs
    objects: 1.82M objects, 2.6 TiB
    usage:   6.1 TiB used, 57 TiB / 63 TiB avail
    pgs:     600 active+clean

  io:
    client:   162 KiB/s rd, 9.0 MiB/s wr, 2 op/s rd, 890 op/s wr

```

## Procedure

1. Adjust the number of omap objects.

    Use one of the options below to resolve the issue:

    - Use the `ceph config` command.

        In the example below, the omap object key threshold is set to 350000, but it can be set to a higher number if desired.

        ```bash
        ncn-m001# ceph config set client.osd osd_deep_scrub_large_omap_object_key_threshold 350000
        ```

        In the exmaple below, the rgw_usage_max_user_shards is set to 16 from 1.  This can be set to a maximum of 32.

        ```bash
        ceph config set client.radosgw  rgw_usage_max_user_shards 16
        ```

    - Increase the number of PGs for the Ceph pool.
        1. Get the current threshold and PG numbers.

            ```bash
            ncn-m001# ceph osd pool autoscale-status
             POOL                          SIZE  TARGET SIZE  RATE  RAW CAPACITY   RATIO  TARGET RATIO  BIAS  PG_NUM  NEW PG_NUM  AUTOSCALE
             cephfs_data                 477.8M                3.0        64368G  0.0000                 1.0       4              on
             cephfs_metadata             781.9M                3.0        64368G  0.0000                 4.0      16              on
             .rgw.root                   384.0k                3.0        64368G  0.0000                 1.0       4              on
             default.rgw.buckets.data     4509G                3.0        64368G  0.2102        0.2000   1.0     128              on
             default.rgw.control             0                 3.0        64368G  0.0000                 1.0       4              on
             default.rgw.buckets.index    1199M                3.0        64368G  0.0001        0.1800   1.0     128              on
             default.rgw.meta             4898k                3.0        64368G  0.0000                 1.0       4              on
             default.rgw.log                 0                 3.0        64368G  0.0000                 1.0       4              on
             kube                        307.0G                3.0        64368G  0.0143        0.1000   1.0      48              on
             smf                          1414G                2.0        64368G  0.0440        0.3000   1.0     256              on
             default.rgw.buckets.non-ec      0                 3.0        64368G  0.0000                 1.0       4              on
            ```

        1. Adjust the target\_size\_ratio value to increase the PGs for the pool.

            This number should be increased a tenth or smaller at a time. Check the autoscale-status between each adjustment. When there is a change to the New PG NUM, stop adjusting the number.

            In the example below, the target\_size\_ratio is set to 0.2.

            ```bash
            ncn-m001# ceph osd pool set POOL_NAME target_size_ratio 0.2
            ```

        1. Check to see if the change is taking effect.

            ```bash
            ncn-m001# ceph osd pool autoscale-status
            ```

        1. Watch the status of the Ceph health.

            Verify the recovery traffic is taking place on the keys. The -w option can be used to watch the cluster.

            ```bash
            ncn-m001# ceph -s
            ```
