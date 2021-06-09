## Restart Ceph Services via Ansible

Restart all of the Ceph Services via Ansible on `ncn-s001`. Monitor the recovery of the Ceph services as they come back up.

The use of Ansible allows for a much quicker way to restart all of the Ceph services.

### Prerequisites

This procedure requires administrative privileges.

### Limitations

Ansible is only available on NCN storage nodes.

### Procedure

1.  Restart the Ceph services via Ansible.

    ```bash
    ncn-s001# ansible ceph_all -m shell -a "systemctl restart ceph-osd.target"
    ncn-s001# ansible ceph_all -m shell -a "systemctl restart ceph-radosgw.target"
    ncn-s001# ansible ceph_all -m shell -a "systemctl restart ceph-mon.target"
    ncn-s001# ansible ceph_all -m shell -a "systemctl restart ceph-mgr.target"
    ncn-s001# ansible ceph_all -m shell -a "systemctl restart ceph-mds.target"
    ```

2.  Log in to an manager node.

3.  Monitor the recovery of the Ceph services.

    ```bash
    ncn-m001# ceph -s
      cluster:
        id:     5a62e378-4d55-47ad-b78f-5463de34124c
        health: HEALTH_OK
    
      services:
        mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 20h)
        mgr: ncn-s003(active, since 9d), standbys: ncn-s001, ncn-s002
        mds: cephfs:1 {0=ncn-s002=up:active} 2 up:standby
        osd: 18 osds: 18 up (since 20h), 18 in (since 9d)
        rgw: 3 daemons active (ncn-s001.rgw0, ncn-s002.rgw0, ncn-s003.rgw0)
    
      data:
        pools:   11 pools, 220 pgs
        objects: 825.66k objects, 942 GiB
        usage:   2.0 TiB used, 61 TiB / 63 TiB avail
        pgs:     220 active+clean
    
      io:
        client:   2.5 KiB/s rd, 13 MiB/s wr, 2 op/s rd, 1.27k op/s wr
    ```

    It will take a short amount of time to recover. The following are things to look for when monitoring Ceph:

    -   rbd will recover and become operational quickly; it will finish its recovery as a background task
    -   cephfs will need to replay logs, which will be slightly slower as it needs the above step to finish the foreground tasks before it starts the replay
    -   radosgw/s3 will be available immediately after the rbd foreground task is complete, which will most likely be done by the time the radosgw step completes


