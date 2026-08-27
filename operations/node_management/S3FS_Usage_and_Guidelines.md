# S3FS Usage and Guidelines for Shasta

* [Introduction](#introduction)
* [When to use](#when-to-use)
* [When NOT to use](#when-not-to-use)
* [Additional considerations](#additional-considerations)
* [How to use](#how-to-use)
    * [Gathering credentials from the Rados Gateway](#gathering-credentials-from-the-rados-gateway)
    * [Mounting the volume](#mounting-the-volume)
        * [Mounting without cache](#mounting-without-cache)
        * [Mounting with cache](#mounting-with-cache)
    * [Unmounting the volume](#unmounting-the-volume)
* [Troubleshooting and additional information](#troubleshooting-and-additional-information)

## Introduction

S3FS is a near POSIX filesystem.
CSM uses it to provide temporary overflow storage, as well as to support [SDU][sdu] and [NMD][nmd]
services by providing space for dumps.

## When to use

Use S3FS for short term storage of large files or RPMs, to avoid filling up the root volume.

## When NOT to use

* For long term storage.
    * This is ONLY meant to provide temporary relief.
    * A vigilant practice of cleaning up unused files should be enforced.
    * This is particular important on master [NCNs][ncn].
        * The [SDU][sdu] uses S3FS on master nodes.
        * The S3FS cache partition must have sufficient free space in order
          for SDU to function.
* A place to uncompress `tar` files.
    * This puts unnecessary load on the storage cluster, because uncompressing a `tar` file
      requires a lot of reads and writes back to the object storage endpoints.
* Running programs from the S3FS mount point.
    * This eats into memory for long running programs, and the programs may not perform properly.

## Additional considerations

* The cache partition is shared if utilizing automatically mounted partitions.
* Make sure to use the correct [S3][s3] credentials and buckets.
    * See [Gathering credentials from the Rados Gateway](#gathering-credentials-from-the-rados-gateway)

## How to use

### Gathering credentials from the Rados Gateway

* Replace `<radosgw-user>` below with the UID for the Rados Gateway/S3 user ID.
* Use a meaningful filename for storing the credentials.
    * Replace `<filename>` below with the credentials filename.
* Create a mount location.
    * Replace `<mount path>` below with the mount location.

```bash
radosgw-admin user info --uid <radosgw-user>|jq -r '.keys[]|.access_key +":"+ .secret_key' >>${HOME}/.<filename>.s3fs && \
chmod 600 ~/.<filename>.s3fs && \
mkdir <mount path>
```

### Mounting the volume

#### Mounting without cache

```bash
s3fs <radosgw-user> <mount path>  -o passwd_file=${HOME}/.<filename>.s3fs,url=http://rgw-vip.nmn,use_path_request_style
```

#### Mounting with cache

**IMPORTANT:** To use this option there must be a dedicated landing space that is a partition.
This ensures that the usage does not impact the root drive.

```bash
s3fs <radosgw-user> <mount path>  -o passwd_file=${HOME}/.<filename>.s3fs,url=http://rgw-vip.nmn,use_path_request_style,use_cache=<dedicated_cache_partition_location>,check_cache_dir_exist=true
```

### Unmounting the volume

```bash
umount <mount path>
```

## Troubleshooting and additional information

The following links provide additional information about [S3][s3] and S3FS, including troubleshooting guides.

* [Troubleshoot S3FS Mounts](../utility_storage/Troubleshoot_S3FS_Mounts.md)
* [Troubleshoot an Unresponsive S3 Endpoint](../utility_storage/Troubleshoot_an_Unresponsive_S3_Endpoint.md)
* [Generate Temporary S3 Credentials](../artifact_management/Generate_Temporary_S3_Credentials.md)
* [Use S3 Libraries and Clients](../artifact_management/Use_S3_Libraries_and_Clients.md)

<!--- Define the reference-style Markdown links used to make the page easier to edit -->

<!-- markdownlint-disable MD053 -->
<!---
    For references that are likely to appear on a lot of pages (glossary references, for example),
    we allow definitions for entries that are not used on the page, as a convenience.
-->

<!-- non-glossary common links -->

[config-cli]: ../configure_cray_cli.md
[check-latest-docs]: ../../update_product_stream/README.md#check-for-latest-documentation

<!-- glossary entries -->

[aee]: ../../glossary.md#ansible-execution-environment-aee
[an]: ../../glossary.md#application-node-an
[ara]: ../../glossary.md#ara-records-ansible-ara
[bmc]: ../../glossary.md#baseboard-management-controller-bmc
[bos]: ../../glossary.md#boot-orchestration-service-bos
[bss]: ../../glossary.md#boot-script-service-bss
[can]: ../../glossary.md#customer-access-network-can
[canu]: ../../glossary.md#csm-automatic-network-utility-canu
[capmc]: ../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc
[cdu]: ../../glossary.md#coolant-distribution-unit-cdu
[cec]: ../../glossary.md#cabinet-environmental-controller-cec
[cfs]: ../../glossary.md#configuration-framework-service-cfs
[chn]: ../../glossary.md#customer-high-speed-network-chn
[cli]: ../../glossary.md#cray-cli-cray
[cmn]: ../../glossary.md#customer-management-network-cmn
[cn]: ../../glossary.md#compute-node-cn
[csi]: ../../glossary.md#cray-site-init-csi
[fas]: ../../glossary.md#firmware-action-service-fas
[hbtd]: ../../glossary.md#heartbeat-tracker-daemon-hbtd
[hmn]: ../../glossary.md#hardware-management-network-hmn
[hmnfd]: ../../glossary.md#hardware-management-notification-fanout-daemon-hmnfd
[hsm]: ../../glossary.md#hardware-state-manager-hsm
[hsn]: ../../glossary.md#high-speed-network-hsn
[ims]: ../../glossary.md#image-management-service-ims
[iuf]: ../../glossary.md#install-and-upgrade-framework-iuf
[meds]: ../../glossary.md#mountain-endpoint-discovery-service-meds
[mgmt-ncns]: ../../glossary.md#management-nodes
[mountain]: ../../glossary.md#mountain-cabinet
[nc]: ../../glossary.md#node-controller-nc
[ncn]: ../../glossary.md#non-compute-node-ncn
[nid]: ../../glossary.md#node-id-nid
[nmd]: ../../glossary.md#node-memory-dump-nmd
[nmn]: ../../glossary.md#node-management-network-nmn
[pcs]: ../../glossary.md#power-control-service-pcs
[pdu]: ../../glossary.md#power-distribution-unit-pdu
[pit]: ../../glossary.md#pre-install-toolkit-pit
[river]: ../../glossary.md#river-cabinet
[rts]: ../../glossary.md#redfish-translation-service-rts
[s3]: ../../glossary.md#simple-storage-service-s3
[sat]: ../../glossary.md#system-admin-toolkit-sat
[sbps]: ../../glossary.md#scalable-boot-projection-service-sbps
[scsd]: ../../glossary.md#system-configuration-service-scsd
[sdu]: ../../glossary.md#system-diagnostic-utility-sdu
[shcd]: ../../glossary.md#shasta-cabling-diagram-shcd
[slingshot]: ../../glossary.md#slingshot
[sls]: ../../glossary.md#system-layout-service-sls
[sma]: ../../glossary.md#system-monitoring-application-sma
[smd]: ../../glossary.md#hardware-state-manager-smd
[sops]: ../../glossary.md#secrets-operations-sops
[tapms]: ../../glossary.md#tenant-and-partition-management-system-tapms
[uan]: ../../glossary.md#user-access-node-uan
[uss]: ../../glossary.md#user-services-software-uss
[vcs]: ../../glossary.md#version-control-service-vcs
[vnid]: ../../glossary.md#virtual-network-identifier-daemon-vnid
[xname]: ../../glossary.md#xname

<!-- markdownlint-restore -->
