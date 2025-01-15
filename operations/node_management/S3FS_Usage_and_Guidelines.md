# S3FS Usage and Guidelines for Shasta

## Introduction

[S3FS](https://github.com/s3fs-fuse/s3fs-fuse) is a FUSE-based filesystem backed by Amazon S3. CSM uses it to provide temporary overflow storage, as well as to support SDU and NMD services to provide space for dumps.

## When to Use

* If the need is a landing point for large files that may fill up the root volume.
* Short term storage of large files or rpms.

## When NOT to Use

* For long term storage of code, test images, test rpms, or tar files.
    * This is ONLY meant to provide temporary relief. Exercising a vigilant practice of cleaning up unused files should be enforced.
* As a landing point to uncompress tar files.
    * This will put unnecessary load on the storage cluster as uncompressing a tar file will require a lot of reads and writes back to the object storage endpoints.
    * Running programs from the S3FS mount point.
        * Although this can be done but will eat into memory for long running programs and may not perform properly.

## Cache Pruning

S3FS maintains a [local cache](https://github.com/s3fs-fuse/s3fs-fuse/wiki/Fuse-Over-Amazon#details), which can fill up if left unchecked, so CSM periodically clears the cache. The s3fs cache parent directory is `/var/lib/s3fs_cache`, with a subdirectory
corresponding to a given s3fs mount point. On master nodes, this will contain an `sds/` subdirectory. Otherwise, on all other nodes, it will contain a `boot-images/` subdirectory.

Periodically, one of two cron jobs runs to clear out cache files. `sds/` is cleared at 00:05 daily when it surpasses 100 GiB, and `boot-images/` is cleared at 00:00 daily when it surpasses 150 GiB.

**Note**: Other arbitrary files and directories directly under `/var/lib/s3fs_cache` will **not** be pruned, and will continue to occupy disk space until they are deleted manually. Do not store large files in this directory expecting them to be pruned.

## Additional Considerations

* Ensure it is only temporary use on master nodes.
    * SDU utilizes S3FS on the master servers and ideally we would like to reserve the S3FS cache partition for SDU.
    * The cache partition is shared if utilizing automatically mounted partitions.
    * Make sure you are utilizing the correct S3 credentials and buckets.

## How To Use

1. Gather creds from radosgw

   ***NOTES:***

   * Please replace \<radosgw-user> below with the UID for the radosgw/s3 user id.
   * Make sure to use a meaningful filename for storing the credentials and replace \<filename> below.
   * Make sure to create a mount location and use that below to replace \<mount path>

    ```bash
    radosgw-admin user info --uid <radosgw-user>|jq -r '.keys[]|.access_key +":"+ .secret_key' >>${HOME}/.<filename>.s3fs
    chmod 600 ~/.<filename>.s3fs
    mkdir <mount path>
    ```

1. Mounting the volume
   1. Mount without cache

      ```text
      # s3fs <radosgw-user> <mount path>  -o passwd_file=${HOME}/.<filename>.s3fs,url=http://rgw-vip.nmn,use_path_request_style
      ```

   2. Mount w/ cache

      ***IMPORTANT:*** To use this option there must be a dedicated landing space that is a partition. This ensures that the usage does not impact the root drive.

      ```text
      s3fs <radosgw-user> <mount path>  -o passwd_file=${HOME}/.<filename>.s3fs,url=http://rgw-vip.nmn,use_path_request_style,use_cache=<dedicated_cache_partition_location>,check_cache_dir_exist=true
      ```

1. Unmounting the volume

   ```bash
   umount <mount path>
   ```
