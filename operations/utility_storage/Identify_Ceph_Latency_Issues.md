# Identify Ceph Latency Issues

Examine the output of the `ceph -s` command to get context for potential issues causing latency.

Troubleshoot the underlying causes for the `ceph -s` command reporting slow PGs.

## Prerequisites

This procedure requires admin privileges.

## Procedure

1. View the status of Ceph.

    ```bash
    ncn-m001# ceph -s
    ```

    Example output:

    ```
    cluster:
       id:     73084634-9534-434f-a28b-1d6f39cf1d3d
       health: HEALTH_WARN
               1 filesystem is degraded
               1 MDSs report slow metadata IOs
               Reduced data availability: 15 pgs inactive, 15 pgs peering
               46 slow ops, oldest one blocked for 1395 sec, daemons [osd,2,osd,5,mon,ceph-1,mon,ceph-2,mon,ceph-3] have slow ops.

     services:
       mon: 3 daemons, quorum ceph-3,ceph-1,ceph-2 (age 38m)
       mgr: ceph-2(active, since 30m), standbys: ceph-3, ceph-1
       mds: cephfs:1/1 {0=ceph-2=up:replay} 2 up:standby
       osd: 15 osds: 15 up (since 93s), 15 in (since 23m); 10 remapped pgs
       rgw: 1 daemon active (ceph-1.rgw0)

     data:
       pools:   9 pools, 192 pgs
       objects: 15.93k objects, 55 GiB
       usage:   175 GiB used, 27 TiB / 27 TiB avail
       pgs:     7.812% pgs not active
                425/47793 objects misplaced (0.889%)
                174 active+clean
                8   peering
                7   remapped+peering
                2   active+remapped+backfill_wait
                1   active+remapped+backfilling

     io:
       client:   7.0 KiB/s wr, 0 op/s rd, 1 op/s wr
       recovery: 12 MiB/s, 3 objects/s
    ```

    The output can provide a lot of context to potential issues causing latency. In the example output above, the following troubleshooting information can be observed:

    - health - Shows latency and what daemons/OSDs are associated with it.
    - mds - MDS is functional, but it is in replay because of the slow ops.
    - osd - All OSDs are up and in. This could be related to a network issue or a single system issue if both OSDs are on the same box.
    - client - Shows the amount of IO/Throughput that clients using Ceph are performing. If health is not set to HEALTH\_OK and traffic is passing through, then Ceph is functioning and re-balancing data because of typical hardware/network issues.
    - recovery - Shows recovery traffic as the system ensures all the copies of data are available to ensure data redundancy.

## Fixes

Based on the output from `ceph -s` (using our example above) we can correlate some information to help determine our bottleneck.

1. When reporting slow ops for OSDs, then it is good to find out if those OSDs are on the same node or different nodes.
    1. If on the same node, then look at networking or other hardware related issues on that node.
    2. If the osds are on different nodes, then networking issues should be investigated.
       1. As an initial step, restart the OSDs, if the slow ops go away and do not return, then we can investigate the logs for possible software bugs or memory issues.
       2. If the slow ops come right back, then there is an issue with replication between the 2 OSDs which tends to be network related.

2. When reporting slow ops for `MONs`, then it is typically an issue with the process.
   1. The most common cause here is either an abrupt clock skew or a hung mon/mgr process.
      1. The recommended remediation is to do a rolling restart of the Ceph `MON` and `MGR` daemons.

3. When reporting slow ops for `MDS`, then it could be due to a couple of different reasons.
   1. If listed in addition to `OSDs`, then the root cause for this will typically be the `OSDs` and the process above should be used followed by restarting the `MDS` daemons.
   2. If it is only listing `MDS`, then restart the MDS daemons. If the problem persists, then the logs will have to be investigated for the root cause.
   3. See [Troubleshoot_Ceph_MDS_reporting_slow_requests_and_failure_on_client](Troubleshoot_Ceph_MDS_reporting_slow_requests_and_failure_on_client.md) for additional steps to help identify MDS slow ops.