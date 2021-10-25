# Restore Nexus Data After Data Corruption

In rare cases, if a Ceph upgrade is not completed successfully and has issues, the eventual Ceph health can end up with a damaged mds (cephfs) daemon. Ceph reports this as follows running the `ceph -s` command:

```bash
ncn-s002# ceph -s
  cluster:
    id:     7ed70f4c-852e-494a-b9e7-5f722af6d6e7
    health: HEALTH_ERR
            1 filesystem is degraded
            1 filesystem is offline
            1 mds daemon damaged
```

When Ceph is in this state, Nexus will likely not operate properly and can be recovered using the following procedure.

### Procedure

The commands in this procedure should be run from a master NCN (unless otherwise noted).

1. Determine where the originally installed Nexus helm chart and manifest exists.

   During normal installs, the initial artifacts (docker images and helm charts) are available on `ncn-m001` in `/mnt/pitdata` after it has been rebooted out of `PIT` mode. The administrator may need to re-mount this volume (first step below):

   1. Re-mount the volume.
      
      ```bash
      ncn-m001# mount -vL PITDATA /mnt/pitdata
      ```

   1. Find the Nexus helm chart to use.
      
      ```bash
      ncn-m001# ls /mnt/pitdata/csm-0.9.4/helm/*nexus*
      /mnt/pitdata/csm-0.9.4/helm/cray-nexus-0.6.0.tgz <-- this is the helm chart to use
      ```
   
   1. Find the Nexus manifest to use.
      
      ```bash
      ncn-m001# ls /mnt/pitdata/csm-0.9.4/manifests/nexus.yaml
      /mnt/pitdata/csm-0.9.4/manifests/nexus.yaml <-- this is the manifest to use
      ```
      
      >**NOTE:** Do not proceed with further steps until these two files are located, as they are necessary to re-install the helm chart after deletion.

1. Uninstall the Nexus helm chart.

   ```bash
   ncn-m001# helm uninstall -n nexus cray-nexus
   ```

1. Delete the backing Nexus PVC.

   ```bash
   ncn-m001# kubectl -n nexus delete pvc nexus-data
   ```

1. Re-install the `cray-nexus` helm chart (using the chart and manifest determined in step 1).

   ```bash
   ncn-m001# loftsman ship --manifest-path /mnt/pitdata/csm-0.9.4/manifests/nexus.yaml --charts-path /mnt/pitdata/csm-0.9.4/helm/cray-nexus-0.6.0.tgz
   ```

1. Re-populate Nexus with `0.9.x` artifacts.

   Depending on where initial `PIT` data was determined in step 1, now locate the Nexus setup script:

   ```bash
   ncn-m001# ls /mnt/pitdata/csm-0.9.4/lib/setup-nexus.sh
   /mnt/pitdata/csm-0.9.4/lib/setup-nexus.sh
   ```

   Re-populate the `0.9.x` artifacts by running the `setup-nexus.sh` script:

   ```bash
   ncn-m001# /mnt/pitdata/csm-0.9.4/lib/setup-nexus.sh
   ```

1. Re-populate Nexus with `1.0` artifacts. This step is also necessary if the mds/cephfs corruption occurred when upgrading from `0.9.x` to `1.0`. Nexus must be populated with both versions of the artifacts in order to support both old/new docker images during upgrade.

   Locate the Nexus setup script, this is typically in `/root/csm-1.0.*` on `ncn-m001`:

   ```bash
   ncn-m001# ls /root/csm-1.0.0-beta.50/lib/setup-nexus.sh
   /root/csm-1.0.0-beta.50/lib/setup-nexus.sh
   ```

   Re-populate the `1.0.x` artifacts by running the `setup-nexus.sh` script:

   ```bash
   ncn-m001# /root/csm-1.0.0-beta.50/lib/setup-nexus.sh
   ```

1. Re-populate Nexus with any add-on products that had been installed on this system.

   If any additional products were installed on this system after initial install, locate the install documentation for those products and re-run the appropriate portion of their install script(s) to load those artifacts back into Nexus. For example, if SLES repositories have been added to Nexus prior to this content restore, refer to the install documentation contained in that distribution's tar file for instructions on how to again load that content into Nexus.

1. Scale up any deployments/statefulsets that may have been scaled down during upgrade (if applicable). These commands should be run from `ncn-s001`.

   Source the `k8s-scale-utils.sh` script in order to define the `scale_up_cephfs_clients` function:
   ```bash
   ncn-m001# source /usr/share/doc/csm/upgrade/1.0/scripts/ceph/lib/k8s-scale-utils.sh
   ```

   Execute the `scale_up_cephfs_clients` function in order to scale up any `cephfs` clients that may still be scaled down:
   ```bash
   ncn-m001# scale_up_cephfs_clients
   ```
