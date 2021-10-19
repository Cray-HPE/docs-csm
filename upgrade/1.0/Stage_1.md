# Stage 1 - Ceph upgrade from Nautilus (14.2.x) to Octopus (15.2.x)

## Stage 1.1

Run:

```bash
ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-ceph-initial.sh ncn-s001
```

> NOTE: Run the script once each for all storage nodes. Follow output of the script carefully. The script will pause for manual interaction

## Stage 1.2

**`IMPORTANT:`** We scale down the conman deployments during stage 1.2 (this stage), so all console sessions will be down for this portion of the upgrade

**`IMPORTANT`** If this has be run previously, then check point files may need to be deleted.

```bash
Directory location = /etc/cray/ceph/_upgraded

/etc/cray/ceph/images_pre_pulled
/etc/cray/ceph/radosgw_converted
/etc/cray/ceph/upgrade_initialized
/etc/cray/ceph/mons_upgraded
/etc/cray/ceph/mgrs_upgraded
/etc/cray/ceph/keys_distributed
/etc/cray/ceph/converted_to_orch
/etc/cray/ceph/osds_upgraded
/etc/cray/ceph/mds_upgraded
/etc/cray/ceph/rgws_upgraded
```

**`NOTE:`** You can delete all these files and rerun or you can just delete any files from your last step. You may end up with checkpoint files if the upgrade was exited out of by the user. But if you know you exited out of OSDs and it was not a clean exit, then you would only need remove `osd_upgraded`, `mds_upgraded` and `rgw_upgraded`.

1. Start the Ceph upgrade

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-ceph.sh
   ```

   `**`IMPORTANT NOTES`**

   > * At this point your Ceph commands will still be working.
   > * You have a new way of executing Ceph commands in addition to the traditional way.
   >   * Please see [Cephadm Reference Material](../../operations/utility_storage/Cephadm_Reference_Material.md) for more information.
   > * Both methods are dependent on the master nodes and storage nodes 001/2/3 have a ceph.client.admin.keyring and/or a ceph.conf file    (cephadm will not require the ceph.conf).
   > * When you continue with Stage 2, you may have issues running your Ceph commands.
   >   * If you are experiencing this, please double check that you restored your /etc/ceph directory from your tar backup.
   > * Any deployments or statefulsets (except slurm and pbs) that are backed by a cephfs PVC will be unavailable during this stage of the upgrade. These deployments will be scaled down and back up automatically. This includes **(but can vary by deployment)**: `nexus`, `cray-ipxe`, `cray-tftp`, `cray-ims`, `cray-console-operator`, and `cray-cfs-api-db`. To view the complete list for the system being upgraded, run the following script to list them:
    >>
    >>   ```bash
    >>   ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/list-cephfs-clients.sh
    >>   ```

2. Verify that conman is running

    ```bash
    ncn-m# kubectl get pods -n services|grep con
    ncn-w002:~ # kubectl get pods -n services|grep con
    cray-console-data-9b5984846-l6bvb                              2/2     Running            0          3d22h
    cray-console-data-postgres-0                                   3/3     Running            0          5h15m
    cray-console-data-postgres-1                                   3/3     Running            0          4d23h
    cray-console-data-postgres-2                                   3/3     Running            0          5d
    cray-console-data-wait-for-postgres-5-jrsq4                    0/2     Completed          0          3d22h
    cray-console-node-0                                            3/3     Running            0          5d
    cray-console-node-1                                            3/3     Running            0          5h15m
    cray-console-operator-c4748d6b4-vvpn7                          2/2     Running            0          4d23h
    csm-config-import-1.0.0-beta.46-5t7kx                          0/3     Completed          0          4d
    ```

**`NOTE:`** if conman is not running please see [establishing conman console connections](operations/../../../operations/conman/Establish_a_Serial_Connection_to_NCNs.md)

3. Verify that the Workload Manager pods (slurm or pbs, for example) are in a 'Running' state by examining the output of `kubectl get pods -n user -o wide`.  If these pods are not in a good state, it may be necessary to restore Workload Manager data that was backed-up in a previous stage.  For more information about restoring Workload Manager data from back-up, see the related procedures in the `Troubleshooting and Administrative Tasks` sub-section of the `Install a Workload Manager` section of the `HPE Cray Programming Environment Installation Guide: CSM on HPE Cray EX`.

Once the `Stage 1` upgrade is complete please proceed to [Stage 2](Stage_2.md)
