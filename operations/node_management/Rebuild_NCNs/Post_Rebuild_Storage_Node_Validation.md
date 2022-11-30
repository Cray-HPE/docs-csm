# Post Rebuild Storage Node Validation

Validate the storage node rebuilt successfully.

Skip this section if a master or worker node was rebuilt.

## Procedure

1. Verify there are 3 mons, 3 mds, 3 mgr processes, and rgws.

    ```bash
    ceph -s
    ```

    Example output:

    ```yaml
      cluster:
        id:     22d01fcd-a75b-4bfc-b286-2ed8645be2b5
        health: HEALTH_OK

      services:
        mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 4m)
        mgr: ncn-s001(active, since 19h), standbys: ncn-s002, ncn-s003
        mds: cephfs:1 {0=ncn-s001=up:active} 2 up:standby
        osd: 12 osds: 12 up (since 2m), 12 in (since 2m)
        rgw: 3 daemons active (ncn-s001.rgw0, ncn-s002.rgw0, ncn-s003.rgw0)

      task status:
        scrub status:
            mds.ncn-s001: idle

      data:
        pools:   10 pools, 480 pgs
        objects: 926 objects, 31 KiB
        usage:   12 GiB used, 21 TiB / 21 TiB avail
        pgs:     480 active+clean
    ```

1. Verify the OSDs are back in the cluster.

    ```bash
    ceph osd tree
    ```

    Example output:

    ```text
    ID CLASS WEIGHT   TYPE NAME         STATUS REWEIGHT PRI-AFF
    -1       20.95917 root default
    -3        6.98639     host ncn-s001
     2   ssd  1.74660         osd.2         up  1.00000 1.00000
     5   ssd  1.74660         osd.5         up  1.00000 1.00000
     8   ssd  1.74660         osd.8         up  1.00000 1.00000
    11   ssd  1.74660         osd.11        up  1.00000 1.00000
    -7        6.98639     host ncn-s002
     0   ssd  1.74660         osd.0         up  1.00000 1.00000
     4   ssd  1.74660         osd.4         up  1.00000 1.00000
     7   ssd  1.74660         osd.7         up  1.00000 1.00000
    10   ssd  1.74660         osd.10        up  1.00000 1.00000
    -5        6.98639     host ncn-s003
     1   ssd  1.74660         osd.1         up  1.00000 1.00000
     3   ssd  1.74660         osd.3         up  1.00000 1.00000
     6   ssd  1.74660         osd.6         up  1.00000 1.00000
     9   ssd  1.74660         osd.9         up  1.00000 1.00000
    ```

1. Verify the radosgw and haproxy are correct.

    There will be an output \(without an error\) returned if radosgw and haproxy are correct.

    ```bash
    curl -k https://rgw-vip.nmn
    ```

    Example output:

    ```text
    <?xml version="1.0" encoding="UTF-8"?><ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/ "><Owner><ID>anonymous</ID><DisplayName></DisplayName></Owner><Buckets></Buckets></ListAllMyBucketsResult
    ```

## Next Step

Return to the main [Rebuild NCNs](Rebuild_NCNs.md#validation) page.
