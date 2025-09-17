# Troubleshoot S3FS Cache Cleanup

This procedure describes how to manually clean up S3FS cache when the automatic pruning is insufficient and the cache continues to grow, consuming excessive disk space on worker nodes.

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

Example of problematic cache growth:

```bash
ncn-w001:~ # cd /var/lib/s3fs_cache/
ncn-w001:/var/lib/s3fs_cache # ls -la
total 36
drwxr-xr-x 6 root root 4096 Nov 29 08:02 .
drwxr-xr-x 1 root root 4096 Nov 29 08:16 ..
drwxr-xr-x 39 root root 4096 Mar 5 11:40 boot-images
drwxr-xr-x 2 root root 4096 Mar 12 11:56 .boot-images.mirror
drwxr-xr-x 39 root root 4096 Mar 5 11:40 .boot-images.stat
drwx------ 2 root root 16384 Nov 29 08:43 lost+found

ncn-w001:/var/lib/s3fs_cache # du -sh boot-images/ .boot-images.mirror/
67G boot-images/
42G .boot-images.mirror/
```

## Prerequisites

- Root access to the affected worker nodes
- Understanding that S3FS cache can be safely deleted as it will be rebuilt on demand

## Procedure

### Manual cache cleanup

Perform the following steps on each affected worker node:

1. (`ncn-w#`) Log in to the worker node and navigate to the S3FS cache directory:

   ```bash
   cd /var/lib/s3fs_cache/
   ```

2. (`ncn-w#`) Check current disk usage:

   ```bash
   df -h /var/lib/s3fs_cache/
   du -sh *
   ```

3. (`ncn-w#`) Clean up files older than 30 days in the main cache directory:

   ```bash
   cd /var/lib/s3fs_cache/boot-images/
   find . -atime +30 -type f | xargs rm -vf
   ```

4. (`ncn-w#`) Clean up files in the mirror directory:

   ```bash
   cd /var/lib/s3fs_cache/.boot-images.mirror/
   find . -atime +30 -type f | xargs rm -vf
   ```

5. (`ncn-w#`) Clean up files in the `stat` directory:

   ```bash
   cd /var/lib/s3fs_cache/.boot-images.stat/
   find . -atime +30 -type f | xargs rm -vf
   ```

6. (`ncn-w#`) Remove empty directories:

   ```bash
   cd /var/lib/s3fs_cache/
   find . -type d -empty -delete
   ```

7. (`ncn-w#`) Check the disk usage after cleanup:

   ```bash
   df -h /var/lib/s3fs_cache/
   ```

### 3. Alternative Cleanup Methods

#### For More Aggressive Cleanup

If you need to clean up files older than a different time period, adjust the `-atime` parameter:

```bash
# Clean up files older than 7 days
find . -atime +7 -type f | xargs rm -vf

# Clean up files older than 1 day
find . -atime +1 -type f | xargs rm -vf
```

#### For Complete Cache Reset

If the cache is severely corrupted or you need to start fresh:

> **Warning**: This will remove all cached data and may cause temporary performance impact as the cache rebuilds.

```bash
cd /var/lib/s3fs_cache/
rm -rf boot-images/ .boot-images.mirror/ .boot-images.stat/
```

## Important Notes

- **Safe to Delete**: S3FS cache files can be safely deleted at any time as they are rebuilt on demand
- **Performance Impact**: Deleting cache may cause temporary performance degradation as data is re-cached
- **Regular Maintenance**: Consider implementing regular manual cleanup if automatic pruning proves insufficient
- **Monitoring**: Set up alerts for disk usage on worker nodes to catch cache growth early

## Related Documentation

- [Troubleshoot S3FS Mounts](Troubleshoot_S3FS_Mounts.md)
- [Utility Storage](Utility_Storage.md)
