# Ceph Storage Types

As a reference, the following `ceph` and `rbd` commands are run from a master node or ncn-s001/2/3. Certain commands will work on different systems. For example, the `rbd` command can be used on the worker nodes if specifying the proper key.

## Ceph Block \(rbd\)

**List block devices in a specific pool:**

```bash
ncn-m001# rbd -p POOL_NAME ls -l
```

Example output:

```
NAME     SIZE  PARENT FMT PROT LOCK
kube_vol 4 GiB          2
```

**Create a block device:**

```bash
ncn-m001# rbd create -p POOL_NAME VOLUME_NAME -size SIZE
```

**Remove a block device:**

```bash
ncn-m001# rbd -p POOL_NAME remove VOLUME_NAME
```

**Show mapped devices:**

```bash
ncn-m001# rbd showmapped
```

Example output:

```
id pool namespace image    snap device
0  test           test_vol -    /dev/rbd0
1  kube           kube_vol -    /dev/rbd1
2  smf            smf_vol  -    /dev/rbd2
```

## Ceph MDS \(File\)

**Display CephFS shares with their pool information:**

```bash
ncn-m001# ceph fs ls
```

Example output:

```
name: cephfs, metadata pool: cephfs_metadata, data pools: [cephfs_data ]
```

**Show the status of all CephFS components:**

```bash
ncn-m001# ceph fs status
```

Example output:

```
cephfs - 0 clients <<-- Containers or hosts attached to cephfs are represented here
======
+------+--------+-----------+---------------+-------+-------+
| Rank | State  |    MDS    |    Activity   |  dns  |  inos |
+------+--------+-----------+---------------+-------+-------+
|  0   | active | ceph-2    | Reqs:    0 /s |  10   |   13  |  <<-- Active server
+------+--------+-----------+---------------+-------+-------+
+-----------------+----------+-------+-------+
|       Pool      |   type   |  used | avail |
+-----------------+----------+-------+-------+
| cephfs_metadata | metadata | 1536k | 13.1G |
|   cephfs_data   |   data   |   0   | 13.1G | <<-- Where files get stored
+-----------------+----------+-------+-------+
+-------------+
| Standby MDS |
+-------------+
|   ceph-1    |
|   ceph-3    |
+-------------+
MDS version: ceph version 14.2.0-300-gacd2f2b9e1 (acd2f2b9e196222b0350b3b59af9981f91706c7f) nautilus (stable)

```

## Ceph RadosGW \(object/s3\)

**List the services to learn more about the radosgw service:**

The following command lists more than just the radosgw service, so ensure the correct sections are used.

```bash
ncn-m001# ceph service dump
```

Example output:

```
{
    "epoch": 2,
    "modified": "2019-08-11 04:37:31.464120",
    "services": {
        "rgw": {            <<-- Note this section
            "daemons": {
                "summary": "",
                "<hostname redacted>.rgw0": {
                    "start_epoch": 2,
                    "start_stamp": "2019-08-11 04:37:31.454975",
                    "gid": 24609,
                    "addr": "10.2.0.1:0/3889467377",
                    "metadata": {
                        "arch": "x86_64",
                        "ceph_release": "nautilus",
                        "ceph_version": "ceph version 14.2.0-300-gacd2f2b9e1 (acd2f2b9e196222b0350b3b59af9981f91706c7f) nautilus (stable)",
                        "ceph_version_short": "14.2.0-300-gacd2f2b9e1",
                        "cpu": "Intel(R) Xeon(R) Platinum 8176 CPU @ 2.10GHz",
                        "distro": "sles",
                        "distro_description": "SUSE Linux Enterprise Server 15",
                        "distro_version": "15",
                        "frontend_config#0": "beast endpoint=<ip address redacted>:8080",
                        "frontend_type#0": "beast",
                        "hostname": "<hostname redacted>",
                        "kernel_description": "#1 SMP Thu Jul 11 11:24:28 UTC 2019 (bf2abc2)",
                        "kernel_version": "4.12.14-150.27-default",
                        "mem_swap_kb": "0",
                        "mem_total_kb": "196736052",
                        "num_handles": "1",
                        "os": "Linux",
                        "pid": "48512",
                        "zone_id": "f9b1f6cc-3396-4161-b694-f2d5019b80c6",
                        "zone_name": "default",
                        "zonegroup_id": "cea2e773-7e4e-4673-b6fd-91adb76e25f5",
                        "zonegroup_name": "default"
                    }
                },
```

**Edit and view user information:**

The following command is an example of how to get information about a specific user.

```bash
ncn-m001# radosgw-admin user info --uid TEST_USER
```

Example output:

```
{
    "user_id": "test_user",
    "display_name": "test_user",
    "email": "",
    "suspended": 0,
    "max_buckets": 1000,
    "subusers": [],  <<-- Any users created and maintained by this user
    "keys": [
        {
            "user": "test_user",
            "access_key": "QEA6PG8VDSJ41JR4C6GZ",  <<-- Random key unique to this user and system
            "secret_key": "SzNCqWwZ7XlGZ1tdtuVdhLTno48ugthx5YwCF6E8" <<-- Random key unique to this user and system
        }
    ],
    "swift_keys": [],
    "caps": [],
    "op_mask": "read, write, delete",
    "default_placement": "",
    "default_storage_class": "",
    "placement_tags": [],
    "bucket_quota": {
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },
    "user_quota": {
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },
    "temp_url_keys": [],
    "type": "rgw",
    "mfa_ids": []
}
```

The `radosgw-admin bucket` command is used to remove or view buckets.

**To list the buckets:**

```bash
ncn-m001# radosgw-admin bucket list
```

**To remove a specific bucket:**

```bash
ncn-m001# radosgw-admin bucket rm --bucket-name BUCKET_NAME
```
