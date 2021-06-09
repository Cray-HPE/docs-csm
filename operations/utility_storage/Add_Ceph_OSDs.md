## Add Ceph OSDs

Add one or more OSDs to a Ceph cluster and reset the Ceph pool quotas once they have been added.

Adding OSDs helps increase the Ceph cluster object storage.

### Prerequisites

This procedure requires administrative privileges and will require at least two windows.

### Procedure

1.  In the first window, log in as `root` on the first master node \(`ncn-m001`\).

    ```bash
    ncn-w001# ssh ncn-m001
    ```

2.  Watch the status of the cluster to monitor the progress of the drives being added.

    The following example shows only six OSDs in use.

    ```bash
    ncn-m001# watch -n 10 ceph -s
      cluster:
        id: 5b359a58-e6f7-4f0c-98b8-f528f620896a
        health: HEALTH_OK
    
      services:
        mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 20h)
        mgr: ncn-s003(active, since 9d), standbys: ncn-s001, ncn-s002
        mds: cephfs:1 {0=ncn-s002=up:active} 2 up:standby
        osd: 18 osds: 18 up (since 20h), 18 in (since 9d)
        rgw: 3 daemons active (ncn-s001.rgw0, ncn-s002.rgw0, ncn-s003.rgw0)
    
      data:
        pools:   11 pools, 220 pgs
        objects: 826.23k objects, 944 GiB
        usage:   2.0 TiB used, 61 TiB / 63 TiB avail
        pgs:     220 active+clean
    
      io:
        client:   1.7 KiB/s rd, 12 MiB/s wr, 1 op/s rd, 1.32k op/s wr
    ```

3.  In the second window, log in to the storage node that has the new OSD\(s\) to be added. In these steps, ncn-s003 is used as an example for the storage node.

    ```bash
    ncn-w001# ssh ncn-s003
    ```

4.  In the second window, add the drives to the cluster.

    Repeat this step for all drives on the storage node\(s\) that have unused storage which should be added to Ceph.

    ```bash
    ncn-s003# ceph-volume lvm create --data /dev/sda --bluestore
    ncn-s003# ceph-volume lvm create --data /dev/sdb --bluestore
    ncn-s003# ceph-volume lvm create --data /dev/sdc --bluestore
    ncn-s003# ceph-volume lvm create --data /dev/sdd --bluestore
    ncn-s003# lsblk
    NAME                    MAJ:MIN  RM  SIZE  RO  TYPE  MOUNTPOINT
    sda                       8:0    1   3.5T   0  disk
    └─ceph--2da25103--a688--41f8--bed7--e315766b38bb-osd--block--4ce0a42e--dd10--4098--a53d--0b744d020fbf 254:2    0   3.5T  0 lvm
    sdb                       8.16   1   3.5T   0  disk
    └─ceph--0f7ef4cd--4b57--4554--b87e--c00c6ed432b4-osd--block--de77a409--7b38--4b4a--a294--268f5e82f11a 254:3    0   3.5T  0 lvm
    sdc                       8:32   1   3.5T   0  disk
    └─ceph--1f902ead--157c--42a0--a4ef--cb31538a430c-osd--block--f8a1f3e4--f708--42e1--b4f3--9ea113023b9d 254:4    0   3.5T  0 lvm
    sdd                       8:48   1   3.5T   0  disk
    └─ceph--117aa844--fe5f--4e0e--a1a3--53ee2c0084cf-osd--block--42526066--c241--4892--814e--86c00e687c70 254:5    0   3.5T  0 lvm
    sde                       8:64   1   447.1G 0  disk
    ├─sde1                    8:65   1   500M   0  part
    │ └─md127                 9:127  0   500M   0  raid1 /boot/efi
    └─sde2                    8:66   1   446.7G 0  part
    └─md126                   9:126  0   446.7G 0  raid1 /
    sdf                       8:80   1   447.1G 0  disk
    ├─sdf1                    8:81   1   500M   0  part
    │ └─md127                 9:127  0   500M   0  raid1 /boot/efi
    └─sdf2                    8:82   1   446.7G 0  part  
      └─md126                 9:126  0   446.7G 0  raid1 /
    sdg                       8:96   0   3.5T   0  disk
    └─ceph--4cb3983b--0a81--41c1--b00f--db29e8745cb7-osd--data--607a78e2--eab5--4df9--a0a6--f368f40cb4b1  254:0    0   3.5T  0 lvm   
    sdh                       8:112  0   3.5T   0  disk  
    └─ceph--e3a2975f--937a--4df7--ae65--03d9aaaf81bb-osd--data--5495a845--107b--4a1a--a259--6459ee0218dc  254:1    0   3.5T  0 lvm   
    ncn-s003# exit
    ```

    The following example is output from the command above.

    ```bash
    Running command: /usr/bin/ceph-authtool --gen-print-key
    Running command: /usr/bin/ceph --cluster ceph --name client.bootstrap-osd --keyring /var/lib/ceph/bootstrap-osd/ceph.keyring -i - osd new f4c5903c-2a46-4bd3-b4bc-7d228bb23ac4
    Running command: /usr/sbin/vgcreate -s 1G --force --yes ceph-291e782f-0e92-4afb-ae75-2ccfee426cf2 /dev/sdd
     stdout: Physical volume "/dev/sdd" successfully created.
     stdout: Volume group "ceph-291e782f-0e92-4afb-ae75-2ccfee426cf2" successfully created
    Running command: /usr/sbin/lvcreate --yes -l 100%FREE -n osd-block-f4c5903c-2a46-4bd3-b4bc-7d228bb23ac4 ceph-291e782f-0e92-4afb-ae75-2ccfee426cf2
     stdout: Logical volume "osd-block-f4c5903c-2a46-4bd3-b4bc-7d228bb23ac4" created.
    Running command: /usr/bin/ceph-authtool --gen-print-key
    Running command: /bin/mount -t tmpfs tmpfs /var/lib/ceph/osd/ceph-9
    --> Absolute path not found for executable: restorecon
    --> Ensure $PATH environment variable contains common executable locations
    Running command: /bin/chown -h ceph:ceph /dev/ceph-291e782f-0e92-4afb-ae75-2ccfee426cf2/osd-block-f4c5903c-2a46-4bd3-b4bc-7d228bb23ac4
    Running command: /bin/chown -R ceph:ceph /dev/dm-5
    Running command: /bin/ln -s /dev/ceph-291e782f-0e92-4afb-ae75-2ccfee426cf2/osd-block-f4c5903c-2a46-4bd3-b4bc-7d228bb23ac4 /var/lib/ceph/osd/ceph-9/block
    Running command: /usr/bin/ceph --cluster ceph --name client.bootstrap-osd --keyring /var/lib/ceph/bootstrap-osd/ceph.keyring mon getmap -o /var/lib/ceph/osd/ceph-9/activate.monmap
     stderr: got monmap epoch 1
    Running command: /usr/bin/ceph-authtool /var/lib/ceph/osd/ceph-9/keyring --create-keyring --name osd.9 --add-key AQB8PSRfJfWwMhAAz0VGGVlEC9KKSXi9wAIcZA==
     stdout: creating /var/lib/ceph/osd/ceph-9/keyring
    added entity osd.9 auth(key=AQB8PSRfJfWwMhAAz0VGGVlEC9KKSXi9wAIcZA==)
    Running command: /bin/chown -R ceph:ceph /var/lib/ceph/osd/ceph-9/keyring
    Running command: /bin/chown -R ceph:ceph /var/lib/ceph/osd/ceph-9/
    Running command: /usr/bin/ceph-osd --cluster ceph --osd-objectstore bluestore --mkfs -i 9 --monmap /var/lib/ceph/osd/ceph-9/activate.monmap --keyfile - --osd-data /var/lib/ceph/osd/ceph-9/ --osd-uuid f4c5903c-2a46-4bd3-b4bc-7d228bb23ac4 --setuser ceph --setgroup ceph
    --> ceph-volume lvm prepare successful for: /dev/sdd
    Running command: /bin/chown -R ceph:ceph /var/lib/ceph/osd/ceph-9
    Running command: /usr/bin/ceph-bluestore-tool --cluster=ceph prime-osd-dir --dev /dev/ceph-291e782f-0e92-4afb-ae75-2ccfee426cf2/osd-block-f4c5903c-2a46-4bd3-b4bc-7d228bb23ac4 --path /var/lib/ceph/osd/ceph-9 --no-mon-config
    Running command: /bin/ln -snf /dev/ceph-291e782f-0e92-4afb-ae75-2ccfee426cf2/osd-block-f4c5903c-2a46-4bd3-b4bc-7d228bb23ac4 /var/lib/ceph/osd/ceph-9/block
    Running command: /bin/chown -h ceph:ceph /var/lib/ceph/osd/ceph-9/block
    Running command: /bin/chown -R ceph:ceph /dev/dm-5
    Running command: /bin/chown -R ceph:ceph /var/lib/ceph/osd/ceph-9
    Running command: /bin/systemctl enable ceph-volume@lvm-9-f4c5903c-2a46-4bd3-b4bc-7d228bb23ac4
     stderr: Created symlink /etc/systemd/system/multi-user.target.wants/ceph-volume@lvm-9-f4c5903c-2a46-4bd3-b4bc-7d228bb23ac4.service → /usr/lib/systemd/system/ceph-volume@.service.
    Running command: /bin/systemctl enable --runtime ceph-osd@9
     stderr: Created symlink /run/systemd/system/ceph-osd.target.wants/ceph-osd@9.service → /usr/lib/systemd/system/ceph-osd@.service.
    Running command: /bin/systemctl start ceph-osd@9
    --> ceph-volume lvm activate successful for osd ID: 9
    --> ceph-volume lvm create successful for: /dev/sdd
    ```

    Proceed to the next step after all of the OSDs have been added to the storage nodes.

5.  In the first window, check how many OSDs are available.

    The following example shows 18 OSDs in use.

    ```bash
    cluster:
    id: 5b359a58-e6f7-4f0c-98b8-f528f620896a
    health: HEALTH_ERR
    Degraded data redundancy (low space): 3 pgs backfill_toofull
    services:
    mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 20h)
    mgr: ncn-s003(active, since 9d), standbys: ncn-s001, ncn-s002
    mds: cephfs:1 {0=ncn-s002=up:active} 2 up:standby
    {0=ncn-m002=up:active}
    2 up:standby
    osd: 18 osds: 18 up (since 20h), 18 in (since 9d)
    rgw: 3 daemons active (ncn-s001.rgw0, ncn-s002.rgw0, ncn-s003.rgw0)
    data:
    pools: 11 pools, 204 pgs
    objects: 70.98k objects, 241 GiB
    usage: 547 GiB used, 62 TiB / 63 TiB avail
    pgs: 39582/212949 objects misplaced (18.588%)
    163 active+clean
    36 active+remapped+backfill_wait
    3 active+remapped+backfill_wait+backfill_toofull
    2 active+remapped+backfilling
    io:
    client: 20 MiB/s wr, 0 op/s rd, 807 op/s wr
    recovery: 559 MiB/s, 187 objects/s
    ```

6.  Run the ceph-pool-quotas.yml playbook to reset the pool quotas.

    This step is only necessary when the cluster capacity has increased.

    ```bash
    ncn-w001# ansible-playbook /opt/cray/crayctl/ansible_framework/main/ceph-pool-quotas.yml
    ```



