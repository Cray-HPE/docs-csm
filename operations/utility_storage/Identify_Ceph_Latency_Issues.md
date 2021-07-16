# Identify Ceph Latency Issues

Examine the output of the `ceph -s` command to get context for potential issues causing latency.

Troubleshoot the underlying causes for the `ceph -s` command reporting slow PGs.

## Prerequisites

This procedure requires admin privileges.

## Procedure

1. View the status of Ceph.

    ```bash
    ncn-m001# ceph -s
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
