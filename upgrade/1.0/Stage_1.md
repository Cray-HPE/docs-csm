# Stage 1 - Ceph upgrade from Nautilus (14.2.x) to Octopus (15.2.x)

>**`IMPORTANT:`**
> 
> Reminder: Before running any upgrade scripts, be sure the Cray CLI output format is reset to default by running the following command:
>
>```bash
> ncn# unset CRAY_FORMAT
>```

## Stage 1.1

1. Run `ncn-upgrade-ceph-initial.sh` for `ncn-s001`. Follow output of the script carefully. The script will pause for manual interaction.

    ```bash
    ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-ceph-initial.sh ncn-s001
    ```

1. Repeat the previous step for each other storage node, one at a time.

## Stage 1.2

**`IMPORTANT:`** We scale down the `conman` deployments during this stage, so all console sessions will be down for this portion of the upgrade.

**`IMPORTANT`** If you have to repeat the `ncn-upgrade-ceph.sh` script, the following checkpoint files may need to be deleted:

```
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

**`NOTE:`** You can delete all these files and rerun or you can just delete any files from your last step. You may end up with checkpoint files if the upgrade was aborted by the user. But if you know you exited out of OSDs and it was not a clean exit, then you would only need to remove `osd_upgraded`, `mds_upgraded`, and `rgw_upgraded`.

1. Start the Ceph upgrade.

    **NOTE**: This script may take hours to complete. In the script output, if you observe a continuous loop on a single OSD, **do not abort the script**. It should eventually progress. If it does not, contact Cray HPE support.

    ```bash
    ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-ceph.sh
    ```

    **`IMPORTANT NOTES`**

    > * At this point your Ceph commands will still be working.
    > * After the upgrade, you will have a new way of executing Ceph commands in addition to the traditional way.
    >     * Please see [Cephadm Reference Material](../../operations/utility_storage/Cephadm_Reference_Material.md) for more information.
    > * Both methods require the master nodes and storage nodes 001/2/3 to have a `ceph.client.admin.keyring` and/or a `ceph.conf` file (`cephadm` will not require the `ceph.conf`).
    > * When you continue with Stage 2, you may have issues running your Ceph commands.
    >     * If you are experiencing this, please double check that you restored your `/etc/ceph` directory from your tar backup.
    > * Any deployments or statefulsets (except `slurm` and `pbs`) that are backed by a `cephfs` PVC will be unavailable during this stage of the upgrade. These deployments will be scaled down and back up automatically. This includes **(but can vary by deployment)**: `nexus`, `cray-ipxe`, `cray-tftp`, `cray-ims`, `cray-console-operator`, and `cray-cfs-api-db`. To view the complete list for the system being upgraded, run the following script to list them:
    >>
    >>   ```bash
    >>   ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/list-cephfs-clients.sh
    >>   ```

2. Verify that cray console services are running

    ```bash
    ncn# kubectl get pods -n services | grep cray-console-
    cray-console-data-5cd59677d9-ph4dh                             2/2     Running     0          21h
    cray-console-data-postgres-0                                   3/3     Running     0          21h
    cray-console-data-postgres-1                                   3/3     Running     0          21h
    cray-console-data-postgres-2                                   3/3     Running     0          21h
    cray-console-data-wait-for-postgres-1-7trgr                    0/2     Completed   0          21h
    cray-console-node-0                                            3/3     Running     0          8m36s
    cray-console-node-1                                            3/3     Running     0          7m26s
    cray-console-operator-7f9894f657-5dz7r                         2/2     Running     0          8m34s
    ```

    **`NOTE:`** If your output does not look similar to what is shown above, please see [establishing serial console connections](operations/../../../operations/conman/Establish_a_Serial_Connection_to_NCNs.md)

3. Verify that the Workload Manager (WLM) pods (`slurm` or `pbs`, for example) are in a `Running` state.

    ```bash
    ncn# kubectl get pods -n user -o wide
    slurmctld-659bddd779-swhr8               3/3     Running             0          20h    10.39.3.53    ncn-w001   <none>           <none>
    slurmdb-745d546db5-lszjt                 1/1     Running             1          152d   10.37.2.89    ncn-w003   <none>           <none>
    slurmdbd-5c9f44f8d5-lffr6                3/3     Running             3          118d   10.39.2.128   ncn-w001   <none>           <none>
    ```

    If any WLM pods are not in a good state, it may be necessary to restore WLM data that was backed-up in a previous stage. For more information about restoring Workload Manager data from back-up, see the related procedures in the `Troubleshooting and Administrative Tasks` sub-section of the `Install a Workload Manager` section of the `HPE Cray Programming Environment Installation Guide: CSM on HPE Cray EX`.

Once the `Stage 1` upgrade is complete, please proceed to [Stage 2](Stage_2.md)
