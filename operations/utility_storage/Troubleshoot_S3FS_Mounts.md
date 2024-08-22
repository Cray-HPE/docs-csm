# Troubleshoot S3FS Mount Issues

The following procedure includes steps to troubleshoot issues with S3FS mount points on worker and master NCNs. Beginning in the CSM 1.2 release, `S3FS` is deployed as tool to reduce space usage on NCNs. Below is a list of the mount points on masters and workers:

## Master Node Mount Points

Master nodes should host the following three mount points:

```bash
/var/opt/cray/config-data (config-data S3 bucket)
/var/opt/cray/sdu/collection-mount (sds S3 bucket)
```

> NOTE: the mount `/var/lib/admin-tools (admin-tools S3 bucket)` is no longer mounted in CSM 1.4+.
> If it is desired to have this bucket mounted, please see [Mount 'admin-tools' S3 bucket](#mount-admin-tools-s3-bucket).

## Worker Node Mount Points

Worker nodes should host the following mount point:

```bash
/var/lib/cps-local/boot-images (boot-images S3 bucket)
```

**Note:** If this mount is missing, the `cray-cps-cm-pm` pods may be unhealthy (in the `CrashLoopBackoff` state). Proceed to Step 1 to resolve the issue.

## Step 1: Verify Mounts are Present

### Verify Mount Points on Master Nodes

Run the following command on master nodes to ensure the mounts are present:

```bash
ncn-m: # mount | grep 's3fs on'
s3fs on /var/opt/cray/config-data type fuse.s3fs (rw,nosuid,nodev,relatime,user_id=0,group_id=0)
s3fs on /var/opt/cray/sdu/collection-mount type fuse.s3fs (rw,relatime,user_id=0,group_id=0,allow_other)
```

If the output is missing one or more of the mounts, proceed to Step 2

### Verify Mount Point on Worker Nodes

Run the following command on worker nodes to ensure the mount is present:

```bash
ncn-w: # mount | grep 's3fs on'
s3fs on /var/lib/cps-local/boot-images type fuse.s3fs (rw,nosuid,nodev,relatime,user_id=0,group_id=0)
```

If the output is missing the mount, proceed to Step 2

## Step 2: Verify `/etc/fstab` Contains the Mounts

### Master Nodes `/etc/fstab` Entries

Ensure the `/etc/fstab` contains the following content:

```bash
ncn-m: # grep fuse.s3fs /etc/fstab
sds /var/opt/cray/sdu/collection-mount fuse.s3fs _netdev,allow_other,passwd_file=/root/.sds.s3fs,url=http://rgw-vip.nmn,use_path_request_style,use_cache=/var/lib/s3fs_cache,check_cache_dir_exist,use_xattr,uid=2370,gid=2370,umask=0007,allow_other 0 0
config-data /var/opt/cray/config-data fuse.s3fs _netdev,allow_other,passwd_file=/root/.config-data.s3fs,url=http://rgw-vip.nmn,use_path_request_style,use_xattr 0 0
```

If the three entries above are not present in `/etc/fstab`, add the above content and proceed to Step 3.

### Worker Nodes `/etc/fstab` Entry

Ensure the `/etc/fstab` contains the following content:

```bash
ncn-w: # grep fuse.s3fs /etc/fstab
boot-images /var/lib/cps-local/boot-images fuse.s3fs _netdev,allow_other,passwd_file=/root/.ims.s3fs,url=http://rgw-vip.nmn,use_path_request_style,use_cache=/var/lib/s3fs_cache,check_cache_dir_exist,use_xattr 0 0
```

If the above line is not present in `/etc/fstab`, add the above content and proceed to Step 3.

## Step 3: Attempt to Remount the Mount Point

This step is the same for master and worker nodes. Run the following command to mount the directories specified in the `/etc/fstab` file:

```bash
ncn-mw: # mount -a
```

If the above command fails, then the error likely indicates that there is an issue communicating with Ceph's `Radosgw` endpoint (`rgw-vip`).
In this case the [Troubleshoot an Unresponsive S3 Endpoint](Troubleshoot_an_Unresponsive_S3_Endpoint.md) procedure should be followed to ensure the endpoint is healthy.

## Mount 'admin-tools' S3 bucket

In CSM 1.2 and CSM 1.3, `/var/lib/admin-tools (admin-tools S3 bucket)` was a mounted S3 bucket. Starting in CSM 1.4, the `admin-tools` S3 bucket is no longer mounted.
It is not necessary for this bucket to be mounted for system operations.
However, if it is desired to have the `admin-tools` S3 bucket mounted, please follow the steps below.

  1. (`ncn-m#`) Mount the `admin-tools` S3 bucket. Run this on each master node where the bucket should be mounted.

      ```bash
      function mount_admin_tools() {
        s3_bucket="admin-tools"
        s3fs_mount_dir="/var/lib/admin-tools"
        s3_user="admin-tools"
        
        s3fs_cache_dir=/var/lib/s3fs_cache
        if [ -d ${s3fs_cache_dir} ]; then
          s3fs_opts="use_path_request_style,use_cache=${s3fs_cache_dir},check_cache_dir_exist,use_xattr"
        else
          s3fs_opts="use_path_request_style,use_xattr"
        fi

        echo "Configuring for ${s3_bucket} S3 bucket at ${s3fs_mount_dir} for ${s3_user} S3 user"

        mkdir -p ${s3fs_mount_dir}

        pwd_file=/root/.${s3_user}.s3fs
        access_key=$(kubectl get secret ${s3_user}-s3-credentials -o json | jq -r '.data.access_key' | base64 -d)
        secret_key=$(kubectl get secret ${s3_user}-s3-credentials -o json | jq -r '.data.secret_key' | base64 -d)
        s3_endpoint=$(kubectl get secret ${s3_user}-s3-credentials -o json | jq -r '.data.http_s3_endpoint' | base64 -d)

        echo "${access_key}:${secret_key}" > ${pwd_file}
        chmod 600 ${pwd_file}

        echo "Mounting bucket: ${s3_bucket} at ${s3fs_mount_dir}"
        s3fs ${s3_bucket} ${s3fs_mount_dir} -o passwd_file=${pwd_file},url=${s3_endpoint},${s3fs_opts}

        echo "Adding fstab entry for ${s3_bucket} S3 bucket at ${s3fs_mount_dir} for ${s3_user} S3 user"
        echo "${s3_bucket} ${s3fs_mount_dir} fuse.s3fs _netdev,allow_other,passwd_file=${pwd_file},url=${s3_endpoint},${s3fs_opts} 0 0" >> /etc/fstab

        echo "Set cache pruning for admin tools to 5G of the 200G volume (every 2nd hour)"
        echo "0 */2 * * * root /usr/bin/prune-s3fs-cache.sh admin-tools ${s3fs_cache_dir} 5368709120 -silent" > /etc/cron.d/prune-s3fs-admin-tools-cache
      }
      mount_admin_tools
      ```

  1. (`ncn-m#`) Check that the `admin-tools` bucket is mounted correctly.

      1. Check `/etc/fstab` contains the following content:

          ```bash
          ncn-m: # grep fuse.s3fs /etc/fstab
          sds /var/opt/cray/sdu/collection-mount fuse.s3fs _netdev,allow_other,passwd_file=/root/.sds.s3fs,url=http://rgw-vip.nmn,use_path_request_style,use_cache=/var/lib/s3fs_cache,check_cache_dir_exist,use_xattr,uid=2370,gid=2370,umask=0007,allow_other 0 0
          admin-tools /var/lib/admin-tools fuse.s3fs _netdev,allow_other,passwd_file=/root/.admin-tools.s3fs,url=http://rgw-vip.nmn,use_path_request_style,use_cache=/var/lib/s3fs_cache,check_cache_dir_exist,use_xattr 0 0
          config-data /var/opt/cray/config-data fuse.s3fs _netdev,allow_other,passwd_file=/root/.config-data.s3fs,url=http://rgw-vip.nmn,use_path_request_style,use_xattr 0 0
          ```

      1. Check that `/var/lib/admin-tools` is mounted.

          ```bash
          ncn-m: # mount | grep 's3fs on'
          s3fs on /var/opt/cray/config-data type fuse.s3fs (rw,nosuid,nodev,relatime,user_id=0,group_id=0)
          s3fs on /var/lib/admin-tools type fuse.s3fs (rw,relatime,user_id=0,group_id=0,allow_other)
          s3fs on /var/opt/cray/sdu/collection-mount type fuse.s3fs (rw,relatime,user_id=0,group_id=0,allow_other)
          ```

> NOTE: This mount will not be recreated after a node upgrade or rebuild.
> This procedure will need to be redone in the case of a node upgrade or rebuild.
