# Validate Added Storage Node

Validate the storage node added successfully. The following examples are based on a storage cluster that was expanded from three nodes to four.

1. Verify there are 3 mons, 3 mds, 3 mgr processes, and rgws (one for each of the four storage nodes)

    ```bash
    ncn-m# ceph -s
      ceph -s
        cluster:
          id:     b13f1282-9b7d-11ec-98d9-b8599f2b2ed2
          health: HEALTH_OK

        services:
          mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 4h)
          mgr: ncn-s001.pdeosn(active, since 4h), standbys: ncn-s002.wjnqvu, ncn-s003.avkrzl
          mds: cephfs:1 {0=cephfs.ncn-s001.ldlvfj=up:active} 1 up:standby-replay 1 up:standby
          osd: 18 osds: 18 up (since 4h), 18 in (since 4h)
          rgw: 4 daemons active (site1.zone1.ncn-s001.ktslgl, site1.zone1.ncn-s002.inynsh, site1.zone1.ncn-s003.dvyhak, site1.zone1.ncn-s004.jnhqvt)
      
        task status:
      
        data:
          pools:   12 pools, 713 pgs
          objects: 37.20k objects, 72 GiB
          usage:   212 GiB used, 31 TiB / 31 TiB avail
          pgs:     713 active+clean

        io:
          client:   7.0 KiB/s rd, 300 KiB/s wr, 2 op/s rd, 49 op/s wr
    ```

1. Verify the added host contains OSDs and the OSDs are up.

    ```bash
    ncn-m# ceph osd tree
    ID  CLASS  WEIGHT    TYPE NAME          STATUS  REWEIGHT  PRI-AFF
    -1         31.43875  root default
    -7          6.98639      host ncn-s001
     0    ssd   1.74660          osd.0          up   1.00000  1.00000
    10    ssd   1.74660          osd.10         up   1.00000  1.00000
    11    ssd   1.74660          osd.11         up   1.00000  1.00000
    15    ssd   1.74660          osd.15         up   1.00000  1.00000
    -3          6.98639      host ncn-s002
     3    ssd   1.74660          osd.3          up   1.00000  1.00000
     5    ssd   1.74660          osd.5          up   1.00000  1.00000
     7    ssd   1.74660          osd.7          up   1.00000  1.00000
    12    ssd   1.74660          osd.12         up   1.00000  1.00000
    -5          6.98639      host ncn-s003
     1    ssd   1.74660          osd.1          up   1.00000  1.00000
     4    ssd   1.74660          osd.4          up   1.00000  1.00000
     8    ssd   1.74660          osd.8          up   1.00000  1.00000
    13    ssd   1.74660          osd.13         up   1.00000  1.00000
    -9         10.47958      host ncn-s004
     2    ssd   1.74660          osd.2          up   1.00000  1.00000
     6    ssd   1.74660          osd.6          up   1.00000  1.00000
     9    ssd   1.74660          osd.9          up   1.00000  1.00000
    14    ssd   1.74660          osd.14         up   1.00000  1.00000
    16    ssd   1.74660          osd.16         up   1.00000  1.00000
    17    ssd   1.74660          osd.17         up   1.00000  1.00000
    ```

1. Verify the radosgw and haproxy are correct.

    Run the following command on the added storage node.

    There will be an output \(without an error\) returned if radosgw and haproxy are correct.

    ```bash
    ncn-s# curl -k https://rgw-vip.nmn
    <?xml version="1.0" encoding="UTF-8"?><ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/ "><Owner><ID>anonymous</ID><DisplayName></DisplayName></Owner><Buckets></Buckets></ListAllMyBucketsResult
    ```
