# Troubleshoot System Clock Skew

Resynchronize system clocks after Ceph reports a clock skew.

Systems use `chronyd` to synchronize their system clocks. If systems are not able to communicate, then the clocks can drift, causing clock skew. Another reason for this issue would be an individual manually changing the clocks or a task that may change the clocks and require a series of steps \(time adjustments\) to resynchronize.

Major time jumps where the clock is set back in time will require a full restart of all Ceph services.

Clock skew can cause issues with Kubernetes operations, etcd, node responsiveness, and more.

## Prerequisites

This procedure requires admin privileges.

## Procedure

1. Verify that the system is impact by clock skew.

    Ceph provides block storage and requires a clock skew of less than 0.05 seconds to report back healthy.

    ```bash
    ncn-m001# ceph -s
    cluster:
       id:     b6d509e6-772e-4785-a421-e4a138b1780c
       health: HEALTH_WARN
               clock skew detected on mon.ncn-m002, mon.ncn-m003

    services:
       mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 20h)
       mgr: ncn-s003(active, since 9d), standbys: ncn-s001, ncn-s002
       mds: cephfs:1 {0=ncn-s002=up:active} 2 up:standby
       osd: 18 osds: 18 up (since 20h), 18 in (since 9d)
       rgw: 3 daemons active (ncn-s001.rgw0, ncn-s002.rgw0, ncn-s003.rgw0)

    data:
       pools:   10 pools, 224 pgs
       objects: 19.41k objects, 59 GiB
       usage:   167 GiB used, 274 GiB / 441 GiB avail
       pgs:     224 active+clean

    io:
       client:   919 KiB/s wr, 0 op/s rd, 16 op/s wr
    ```

    **`IMPORTANT:`** If you see this message in the ceph logs `unable to obtain rotating service keys; retrying` it will also indicate clock skew. You may have to utilize `xzgrep skew *.xz to see the skew` if you logs have rolled over.


2. View the Ceph health details.

    1. View the Ceph logs.

        If looking back to earlier logs, use the `xzgrep` command for the ceph.log or the ceph-mon\*.log. There are cases where the MGR and OSD logs are not in the ceph-mon logs. This indicates that the skew was very drastic and sudden, thus causing the ceph-mon process to panic and not log the issue.

        ```bash
        ncn-m001# grep skew /var/log/ceph/*.log
        ```

    2. View the system time.

        ```bash
        ncn-w001# ansible ceph_all -m shell -a date
        ```

3. Sync the clocks to fix the issue.

    ```bash
    ncn-w001# systemctl restart chronyd.service
    ```

    Wait a bit after running the command and the Ceph alert will clear. Restart the Ceph mon service on that node if the alert does not clear.

4. Check Ceph health to verify the clock skew issue is resolved.

    It may take up to 15 minutes for this warning to resolve.

    ```bash
    ncn-m001# ceph -s
    cluster:
      id:     5f3b4031-d6c0-4118-94c0-bffd90b534eb
      health: HEALTH_OK

    services:
      mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 20h)
      mgr: ncn-s003(active, since 9d), standbys: ncn-s001, ncn-s002
      mds: cephfs:1 {0=ncn-s002=up:active} 2 up:standby
      osd: 18 osds: 18 up (since 20h), 18 in (since 9d)
      rgw: 3 daemons active (ncn-s001.rgw0, ncn-s002.rgw0, ncn-s003.rgw0)

    data:
      pools:   11 pools, 240 pgs
      objects: 3.12k objects, 11 GiB
      usage:   45 GiB used, 39 GiB / 84 GiB avail
      pgs:     240 active+clean
    ```

    If clocks are in sync and Ceph is still reporting skew, refer to [Manage Ceph Services](Manage_Ceph_Services.md) on restarting services.
