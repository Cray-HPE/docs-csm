# Storage node `cloud-init` fails with 'Timed out waiting for device' error

## Observed Error

This error can be observed from a storage node's console.

```text
[ TIME ] Timed out waiting for device /dev/disk/by-label/CEPHETC.
[DEPEND] Dependency failed for File System Check on /dev/disk/by-label/CEPHETC.
[DEPEND] Dependency failed for /etc/ceph.
[DEPEND] Dependency failed for Local File Systems.
[DEPEND] Dependency failed for Early Kernel Boot Messages.
[ TIME ] Timed out waiting for device /dev/disk/by-label/CEPHVAR.
[DEPEND] Dependency failed for /var/lib/ceph.
[DEPEND] Dependency failed for File System Check on /dev/disk/by-label/CEPHVAR.
```

## Description

This error happens when a storage node is being upgraded to a new image outside of the normal CSM major release upgrade.
This happens because `rd.live.dir` still exists after the node reboots and the node does not pull the new image.

See the [boot a storage node into new image without upgrading CSM](../../operations/node_management/Boot_storage_node_into_new_image.md) document for a more in depth description of the error and the procedure to work around it.
