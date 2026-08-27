# Troubleshoot S3 Filesystem Mount Issues

The following procedure includes steps to troubleshoot issues with S3 filesystem mount points on worker and master NCNs.
Beginning in the CSM 1.2 release, `S3FS` is deployed in order to reduce space usage on NCNs.

* [Expected `s3fs` mounts on NCNs](#expected-s3fs-mounts-on-ncns)
    * [Master node mount points](#master-node-mount-points)
    * [Worker node mount points](#worker-node-mount-points)
* [Verify and restore `s3fs` mounts on NCNs](#verify-and-restore-s3fs-mounts-on-ncns)
    1. [Verify mounts are present](#step-1-verify-mounts-are-present)
        * [Verify mounts on master nodes](#verify-mounts-on-master-nodes)
        * [Verify mounts on worker nodes](#verify-mounts-on-worker-nodes)
    1. [Verify `/etc/fstab` contains the mounts](#step-2-verify-etcfstab-contains-the-mounts)
        * [Master nodes `/etc/fstab` entries](#master-nodes-etcfstab-entries)
        * [Worker nodes `/etc/fstab` entry](#worker-nodes-etcfstab-entry)
    1. [Attempt to remount the mount point](#step-3-attempt-to-remount-the-mount-point)
* [Mount `admin-tools` S3 bucket](#mount-admin-tools-s3-bucket)
* [Related links](#related-links)

## Expected `s3fs` mounts on NCNs

### Master node mount points

Master nodes should host the following mount points:

| *Mount point*                        | *S3 bucket*   |
| ------------------------------------ | ------------- |
| `/var/opt/cray/config-data`          | `config-data` |
| `/var/opt/cray/sdu/collection-mount` | `sds`         |

> NOTE: the mount `/var/lib/admin-tools` (`admin-tools` S3 bucket) is no longer mounted in CSM 1.4+.
> If it is desired to have this bucket mounted, see [Mount `admin-tools` S3 bucket](#mount-admin-tools-s3-bucket).

### Worker node mount points

Worker nodes should host the following mount point:

| *Mount point*                    | *S3 bucket*   |
| -------------------------------- | ------------- |
| `/var/lib/cps-local/boot-images` | `boot-images` |

**Note:** If this mount is missing, the `cray-cps-cm-pm` pods may be unhealthy (in the `CrashLoopBackoff` state).
Proceed to [Step 2: Verify `/etc/fstab` contains the mounts](#step-2-verify-etcfstab-contains-the-mounts) to resolve the issue.

## Verify and restore `s3fs` mounts on NCNs

### Step 1: Verify mounts are present

#### Verify mounts on master nodes

(`ncn-m#`) Run the following command on master nodes to ensure the mounts are present:

```bash
mount | grep 's3fs on'
```

Example output:

```text
s3fs on /var/opt/cray/config-data type fuse.s3fs (rw,nosuid,nodev,relatime,user_id=0,group_id=0)
s3fs on /var/opt/cray/sdu/collection-mount type fuse.s3fs (rw,relatime,user_id=0,group_id=0,allow_other)
```

If the output is missing one or more of the mounts, then proceed to
[Step 2: Verify `/etc/fstab` contains the mounts](#step-2-verify-etcfstab-contains-the-mounts).

#### Verify mounts on worker nodes

(`ncn-w#`) Run the following command on worker nodes to ensure the mount is present:

```bash
mount | grep 's3fs on'
```

Example output:

```text
s3fs on /var/lib/cps-local/boot-images type fuse.s3fs (rw,nosuid,nodev,relatime,user_id=0,group_id=0)
```

**Note:** If this mount is missing, the `cray-cps-cm-pm` pods may be unhealthy (in the `CrashLoopBackoff` state).
If the output is missing the mount, then proceed to
[Step 2: Verify `/etc/fstab` contains the mounts](#step-2-verify-etcfstab-contains-the-mounts).

### Step 2: Verify `/etc/fstab` contains the mounts

(`ncn-mw#`) Ensure that the `/etc/fstab` contains the expected content:

```bash
grep fuse.s3fs /etc/fstab
```

#### Master nodes `/etc/fstab` entries

Expected `/etc/fstab` entries for master nodes:

```text
sds /var/opt/cray/sdu/collection-mount fuse.s3fs _netdev,allow_other,passwd_file=/root/.sds.s3fs,url=http://rgw-vip.nmn,use_path_request_style,use_cache=/var/lib/s3fs_cache,check_cache_dir_exist,use_xattr,uid=2370,gid=2370,umask=0007,allow_other 0 0
config-data /var/opt/cray/config-data fuse.s3fs _netdev,allow_other,passwd_file=/root/.config-data.s3fs,url=http://rgw-vip.nmn,use_path_request_style,use_xattr 0 0
```

If any of the entries are missing, then add them and proceed to
[Step 3: Attempt to remount the mount point](#step-3-attempt-to-remount-the-mount-point).

#### Worker nodes `/etc/fstab` entry

Expected `/etc/fstab` entry for worker nodes:

```text
boot-images /var/lib/cps-local/boot-images fuse.s3fs _netdev,allow_other,passwd_file=/root/.ims.s3fs,url=http://rgw-vip.nmn,use_path_request_style,use_cache=/var/lib/s3fs_cache,check_cache_dir_exist,use_xattr 0 0
```

If the entry is missing, then add it and proceed to
[Step 3: Attempt to remount the mount point](#step-3-attempt-to-remount-the-mount-point).

### Step 3: Attempt to remount the mount point

This step is the same for master and worker nodes.

(`ncn-mw#`) Run the following command to mount the directories specified in the `/etc/fstab` file.

```bash
mount -a
```

If the above command fails, then the error likely indicates that there is an issue communicating with Ceph's `Radosgw` endpoint (`rgw-vip`).
In this case, see [Troubleshoot an Unresponsive S3 Endpoint](Troubleshoot_an_Unresponsive_S3_Endpoint.md).

## Mount `admin-tools` S3 bucket

In CSM 1.2 and CSM 1.3, `/var/lib/admin-tools (admin-tools S3 bucket)` was a mounted S3 bucket.
Starting in CSM 1.4, the `admin-tools` S3 bucket is no longer mounted.
It is not necessary for this bucket to be mounted for system operations.
However, if it is desired to have the `admin-tools` S3 bucket mounted,
run the following script on all master nodes where the `admin-tools` bucket should be mounted.

(`ncn-m#`) Mount the `admin-tools` S3 bucket.

```bash
/usr/share/doc/csm/scripts/mount-admin-tools-bucket.sh
```

> NOTE: This mount will not be recreated after a node upgrade or rebuild;
> This procedure will need to be redone in the case of a node upgrade or rebuild.

## Related links

* [Troubleshoot an Unresponsive S3 Endpoint](Troubleshoot_an_Unresponsive_S3_Endpoint.md)
* [S3FS Usage and Guidelines](../node_management/S3FS_Usage_and_Guidelines.md)
* [Generate Temporary S3 Credentials](../artifact_management/Generate_Temporary_S3_Credentials.md)
* [Use S3 Libraries and Clients](../artifact_management/Use_S3_Libraries_and_Clients.md)
