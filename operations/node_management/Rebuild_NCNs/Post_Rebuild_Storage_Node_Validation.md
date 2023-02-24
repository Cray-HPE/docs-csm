# Post Rebuild Storage Node Validation

Validate the storage node rebuilt successfully.

Skip this section if a master or worker node was rebuilt.

## Procedure

1. Verify there are 3 `mons`, 3 `mds`, 3 `mgr` processes, and `rgws`.

    ```bash
    ceph -s
    ```

    Example output:

    ```yaml
      cluster:
        id:     4c9e9d74-a208-11ed-b008-98039bb427f6
        health: HEALTH_OK

      services:
        mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 19m)
        mgr: ncn-s002.mgvtbe(active, since 18m), standbys: ncn-s001.gvuyjf, ncn-s003.ndzqsk
        mds: 1/1 daemons up, 1 standby, 1 hot standby
        osd: 18 osds: 18 up (since 17m), 18 in (since 18m)
        rgw: 3 daemons active (3 hosts, 1 zones)

      data:
        volumes: 1/1 healthy
        pools:   13 pools, 553 pgs
        objects: 38.18k objects, 70 GiB
        usage:   202 GiB used, 63 TiB / 63 TiB avail
        pgs:     553 active+clean

      io:
        client:   19 KiB/s rd, 403 KiB/s wr, 4 op/s rd, 66 op/s wr
    ```

1. Verify the OSDs are back in the cluster.

    ```bash
    ceph osd tree
    ```

    Example output:

    ```text
    ID  CLASS  WEIGHT    TYPE NAME          STATUS  REWEIGHT  PRI-AFF
    -1         62.87558  root default
    -5         20.95853      host ncn-s001
    2    ssd   3.49309          osd.2          up   1.00000  1.00000
    5    ssd   3.49309          osd.5          up   1.00000  1.00000
    6    ssd   3.49309          osd.6          up   1.00000  1.00000
    9    ssd   3.49309          osd.9          up   1.00000  1.00000
    12   ssd   3.49309          osd.12         up   1.00000  1.00000
    16   ssd   3.49309          osd.16         up   1.00000  1.00000
    -3         20.95853      host ncn-s002
    0    ssd   3.49309          osd.0          up   1.00000  1.00000
    3    ssd   3.49309          osd.3          up   1.00000  1.00000
    7    ssd   3.49309          osd.7          up   1.00000  1.00000
    10   ssd   3.49309          osd.10         up   1.00000  1.00000
    13   ssd   3.49309          osd.13         up   1.00000  1.00000
    15   ssd   3.49309          osd.15         up   1.00000  1.00000
    -7         20.95853      host ncn-s003
    1    ssd   3.49309          osd.1          up   1.00000  1.00000
    4    ssd   3.49309          osd.4          up   1.00000  1.00000
    8    ssd   3.49309          osd.8          up   1.00000  1.00000
    11   ssd   3.49309          osd.11         up   1.00000  1.00000
    14   ssd   3.49309          osd.14         up   1.00000  1.00000
    17   ssd   3.49309          osd.17         up   1.00000  1.00000
    ```

1. Verify the `radosgw` and `haproxy` are correct.

    There will be an output \(without an error\) returned if `radosgw` and `haproxy` are correct.

    ```bash
    curl -k https://rgw-vip.nmn
    ```

    Example output:

    ```text
    <?xml version="1.0" encoding="UTF-8"?><ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/ "><Owner><ID>anonymous</ID><DisplayName></DisplayName></Owner><Buckets></Buckets></ListAllMyBucketsResult
    ```

## Next Step

If executing this procedure as part of an NCN rebuild, return to the main [Rebuild NCNs](Rebuild_NCNs.md#storage-node) page and proceed with the next step.
