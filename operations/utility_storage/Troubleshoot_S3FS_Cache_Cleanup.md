# Troubleshoot S3FS Cache Cleanup

This procedure describes how to manually clean up S3FS cache when the automatic pruning is insufficient
and the cache continues to grow, consuming excessive disk space on worker nodes.

> For more information on S3FS cache pruning, see
> [Cache pruning](../node_management/S3FS_Usage_and_Guidelines.md#cache-pruning).

## Background

(`ncn-w#`) CSM includes an automatic S3FS cache pruning mechanism in the form of a daily `cron` job:

```bash
cat /etc/cron.d/prune-s3fs-boot-images-cache
```

Output:

```text
0 0 * * * root /usr/bin/prune-s3fs-cache.sh boot-images /var/lib/s3fs_cache 161061273600 -silent
```

However, some files may not be properly pruned by the automated process.
Over time, this may lead to increasing disk usage, which requires manual intervention.

## Symptoms

- High disk usage on worker nodes
- S3FS cache directories growing continuously despite automatic pruning
- Files accumulating in `/var/lib/s3fs_cache/` subdirectories

(`ncn-w#`) Example of problematic cache growth:

```bash
cd /var/lib/s3fs_cache/ && \
  ls -la && \
  echo "Disk Usage:" && \
  du -sh boot-images/ .boot-images.mirror/
```

Example output:

```text
total 36
drwxr-xr-x 6 root root 4096 Nov 29 08:02 .
drwxr-xr-x 1 root root 4096 Nov 29 08:16 ..
drwxr-xr-x 39 root root 4096 Mar 5 11:40 boot-images
drwxr-xr-x 2 root root 4096 Mar 12 11:56 .boot-images.mirror
drwxr-xr-x 39 root root 4096 Mar 5 11:40 .boot-images.stat
drwx------ 2 root root 16384 Nov 29 08:43 lost+found
Disk Usage:
67G boot-images/
42G .boot-images.mirror/
```

## Prerequisites

- Root access to the affected worker nodes

## Procedure

The contents of the S3FS cache can be safely deleted, because the cache is repopulated on demand.

### Manual cache cleanup

(`ncn-w#`) Perform the following steps on each affected worker node:

1. Check current disk usage.

   ```bash
   df -h /var/lib/s3fs_cache/
   du -sh /var/lib/s3fs_cache/*
   ```

1. Clean up files older than 30 days in the main cache directory.

   ```bash
   find /var/lib/s3fs_cache/boot-images/ -atime +30 -type f | xargs rm -vf
   ```

1. Clean up files in the mirror directory.

   ```bash
   find /var/lib/s3fs_cache/.boot-images.mirror/ -atime +30 -type f | xargs rm -vf
   ```

1. Clean up files in the `stat` directory.

   ```bash
   find /var/lib/s3fs_cache/.boot-images.stat/ -atime +30 -type f | xargs rm -vf
   ```

1. Remove empty directories.

   ```bash
   find /var/lib/s3fs_cache/ -type d -empty ! -wholename /var/lib/s3fs_cache/ -delete
   ```

1. Check the disk usage after cleanup.

   ```bash
   df -h /var/lib/s3fs_cache/
   ```

## Alternative cleanup methods

### More aggressive cleanup

In order to clean up files older than a different time period, adjust the `-atime` parameter.

For example:

- (`ncn-w#`) Clean up files older than 7 days:

    ```bash
    find /var/lib/s3fs_cache/boot-images/ -atime +7 -type f | xargs rm -vf
    ```

- (`ncn-w#`) Clean up files older than 1 day:

    ```bash
    find /var/lib/s3fs_cache/boot-images/ -atime +1 -type f | xargs rm -vf
    ```

### Complete cache reset

(`ncn-w#`) If the cache is severely corrupted or wishing to start fresh, then perform
a complete cache reset.

> **Warning**: This will remove all cached data, which may cause a temporary performance
impact as the cache rebuilds.

```bash
cd /var/lib/s3fs_cache/
rm -rf boot-images/ .boot-images.mirror/ .boot-images.stat/
```

## Important notes

- **Safe to delete**: S3FS cache files can be safely deleted at any time because they are rebuilt on demand
- **Performance impact**: Deleting the cache may cause temporary performance degradation as data is re-cached
- **Regular maintenance**: Consider implementing regular manual cleanup if automatic pruning proves insufficient
- **Monitoring**: Set up alerts for disk usage on worker nodes to catch cache growth early

## Related documentation

- [Troubleshoot S3FS Mounts](Troubleshoot_S3FS_Mounts.md)
- [Troubleshoot an Unresponsive S3 Endpoint](Troubleshoot_an_Unresponsive_S3_Endpoint.md)
- [S3FS Usage and Guidelines](../node_management/S3FS_Usage_and_Guidelines.md)
- [Utility Storage](Utility_Storage.md)
