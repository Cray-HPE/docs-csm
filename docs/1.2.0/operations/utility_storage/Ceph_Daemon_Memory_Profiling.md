# Ceph Daemon Memory Profiling

This procedure is meant as an instructional guide to provide information back to HPE Cray to assist in tuning and troubleshooting exercises.

## Procedure

> **NOTE:** For this example, a ceph-mon process on ncn-s001 is used.

1. Identify the process and location of the daemon to profile.

   ```bash
   ncn-s00(1/2/3)# ceph orch ps --daemon_type mon
   ```

   Example output:

   ```
   NAME          HOST      STATUS        REFRESHED  AGE  VERSION  IMAGE NAME                        IMAGE ID      CONTAINER ID
   mon.ncn-s001  ncn-s001  running (1h)  60s ago    1h   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  bcca26f69191
   mon.ncn-s002  ncn-s002  running (1h)  61s ago    1h   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  43c8472465b2
   mon.ncn-s003  ncn-s003  running (1h)  61s ago    1h   15.2.8   registry.local/ceph/ceph:v15.2.8  5553b0cb212c  7aa1b1f19a00
   ```

2. SSH to the node where the process is running if it is different from the current node.

3. Start the profiler.

   ```bash
   ncn-s001# ceph tell mon.ncn-s001 heap start_profiler
   ```

   A message stating "mon.ncn-s001 started profiler" will be returned.

4. Dump stats. This `does NOT require` the profiler to be running.

   ```bash
   ncn-s001# ceph tell mon.ncn-s001 heap stats
   ```

   Example output:

   ```
   mon.ncn-s001 tcmalloc heap stats:------------------------------------------------
   MALLOC:      972461744 (  927.4 MiB) Bytes in use by application
   MALLOC: +            0 (    0.0 MiB) Bytes in page heap freelist
   MALLOC: +      8804424 (    8.4 MiB) Bytes in central cache freelist
   MALLOC: +      3706880 (    3.5 MiB) Bytes in transfer cache freelist
   MALLOC: +     25649416 (   24.5 MiB) Bytes in thread cache freelists
   MALLOC: +      5636096 (    5.4 MiB) Bytes in malloc metadata
   MALLOC:   ------------
   MALLOC: =   1016258560 (  969.2 MiB) Actual memory used (physical + swap)
   MALLOC: +    189841408 (  181.0 MiB) Bytes released to OS (aka unmapped)
   MALLOC:   ------------
   MALLOC: =   1206099968 ( 1150.2 MiB) Virtual address space used
   MALLOC:
   MALLOC:          14833              Spans in use
   MALLOC:             25              Thread heaps in use
   MALLOC:           8192              Tcmalloc page size
   ------------------------------------------------
   Call ReleaseFreeMemory() to release freelist memory to the OS (via madvise()).
   Bytes released to the OS take up virtual address space but no physical memory.
   ```

5. Dump heap. This `requires` the profiler to be running.

   ```bash
   # ceph tell mon.ncn-s001 heap dump
   ```

   Example output:

   ```
   mon.ncn-s001 dumping heap profile now.
   ------------------------------------------------
   MALLOC:      976849264 (  931.6 MiB) Bytes in use by application
   MALLOC: +            0 (    0.0 MiB) Bytes in page heap freelist
   MALLOC: +      8819048 (    8.4 MiB) Bytes in central cache freelist
   MALLOC: +      3617280 (    3.4 MiB) Bytes in transfer cache freelist
   MALLOC: +     25531176 (   24.3 MiB) Bytes in thread cache freelists
   MALLOC: +      5636096 (    5.4 MiB) Bytes in malloc metadata
   MALLOC:   ------------
   MALLOC: =   1020452864 (  973.2 MiB) Actual memory used (physical + swap)
   MALLOC: +    185647104 (  177.0 MiB) Bytes released to OS (aka unmapped)
   MALLOC:   ------------
   MALLOC: =   1206099968 ( 1150.2 MiB) Virtual address space used
   MALLOC:
   MALLOC:          14834              Spans in use
   MALLOC:             25              Thread heaps in use
   MALLOC:           8192              Tcmalloc page size
   ------------------------------------------------
   Call ReleaseFreeMemory() to release freelist memory to the OS (via madvise()).
   Bytes released to the OS take up virtual address space but no physical memory.
   ```

6. Release memory.

   ```bash
   ncn-s001# ceph tell mon.ncn-s001 heap release
   ```

   A message stating "mon.ncn-s001 releasing free RAM back to system" will be returned.

7. Stop the profiler.

   ```bash
   ncn-s001# ceph tell mon.ncn-s001 heap stop_profiler
   ```

   A message stating " mon.ncn-s001 stopped profiler" will be returned.

