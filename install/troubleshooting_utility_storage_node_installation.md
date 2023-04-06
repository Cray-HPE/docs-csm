# Utility Storage Installation Troubleshooting

## Topics

- [`ncn-s001` console is stuck 'Sleeping for five seconds waiting Ceph to be healthy...'](#ncn-s001-console-is-stuck-'Sleeping-for-five-seconds-waiting-ceph-to-be-healthy...)

## Details

### `ncn-s001` console is stuck 'Sleeping for five seconds waiting Ceph to be healthy...'

> **NOTES:**
> It can be appropriate for `ncn-s001` to wait with this message for a while. To check if Ceph OSDs are still coming up, run `ceph -s` and check the number of OSDs.
After a couple minutes, run `ceph -s` again and see if there are more OSDs. If OSDs are still increasing, then continue to wait.

1. (`ncn-s001`) Check Ceph health.

   ```bash
   ceph health detail
   ceph -s
   ```

2. If Ceph health shows the following health warning

   ```bash
   HEALTH_WARN 1 pool(s) do not have an application enabled
   [WRN] POOL_APP_NOT_ENABLED: 1 pool(s) do not have an application enabled
      application not enabled on pool '.mgr'
      use 'ceph osd pool application enable <pool-name> <app-name>', where <app-name> is 'cephfs', 'rbd', 'rgw', or freeform for custom applications. 
   ```

   (`ncn-s001`) Then enable the `.mgr` pool with the following command.

   ```bash
   ceph osd pool application enable .mgr mgr
   ```

   Expected output:

   ```bash
   enabled application 'mgr' on pool '.mgr'
   ```

3. If Ceph health does not show the warning above, then most likely the storage node install will finish after waiting longer. Other Ceph troubleshooting procedures are in the
[troubleshooting section](../operations/utility_storage/Utility_Storage.md#storage-troubleshooting-references) of the [utility storage documentation](../operations/utility_storage/Utility_Storage.md).
