# Worker Node COS Power Up Configuration

This procedure is only to be used as part of a full system power up procedure when there are no DVS
clients using CPS/DVS from the worker nodes.

**Important:** Some systems may have a failure to mount Lustre on the worker nodes during the COS 2.3
layer of configuration if their connection to the ClusterStor is via cables to Slingshot switches
in the liquid-cooled cabinets which have not been powered up at this point in the power on procedure.
This affects worker nodes which have Mellanox HSN NICs. Worker nodes with Cassini HSN NICs are unaffected.
This may include systems which have Arista switches.

Normally, CFS could be restarted for these worker nodes after the Slingshot switches in the
liquid-cooled cabinets have been powered up. however there is a known problem with Slingshot 1.7.3a
and earlier versions of the Slingshot Host Software (SHS) which require a special procedure in
the COS 2.3 layer to address this problem.

## Prerequisites

* All compute nodes and application nodes are powered off.
* All Slingshot switches in liquid-cooled cabinets are powered on
* No worker node has any DVS mounts to CPS or other dedicated DVS server.
* No worker node has any Lustre filesystems mounted.
* CFS has failed post-boot configuration, NCN personalization, on the worker nodes.

## Procedure

1. Check whether CFS has failed NCN personalization on the worker nodes.

    When the "Configuration Status" is set to "configured" that node has completed all configuration layers for post-boot CFS.

    If any nodes have "Configuration Status" set to "pending", there should be a CFS session in progress which includes that node.

    If any nodes have "Configuration Status" set to "failed" with "Error Count" set to 3, then the node was unable complete a layer of configuration.  

    ```bash
    ncn-m# sat status --filter role=management --filter enabled=true --fields \
    xname,aliases,role,subrole,"desired config","configuration status","error count"
    ```

    Example output:

    ```text
    +----------------+----------+------------+---------+---------------------+----------------------+-------------+
    | xname          | Aliases  | Role       | SubRole | Desired Config      | Configuration Status | Error Count |
    +----------------+----------+------------+---------+---------------------+----------------------+-------------+
    | x3000c0s7b0n0  | ncn-w001 | Management | Worker  | ncn-personalization | failed               | 3           |
    | x3000c0s9b0n0  | ncn-w002 | Management | Worker  | ncn-personalization | failed               | 3           |
    | x3000c0s11b0n0 | ncn-w003 | Management | Worker  | ncn-personalization | failed               | 3           |
    | x3000c0s13b0n0 | ncn-w004 | Management | Worker  | ncn-personalization | pending              | 2           |
    | x3000c0s25b0n0 | ncn-w005 | Management | Worker  | ncn-personalization | pending              | 2           |
    +----------------+----------+------------+---------+---------------------+----------------------+-------------+
    ```

    This example shows three worker nodes which have failed with an error count of 3 and two which are pending, but have already failed twice.

    1. If some nodes are not fully "configured", find any CFS sessions in progress.

       ```bash
       ncn# kubectl -n services --sort-by=.metadata.creationTimestamp get pods | grep cfs
       ```

       Example output:

       ```text
       cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk                    7/9     Error       0          21m
       cfs-157af6d5-b63d-48ba-9eb9-b33af9a8325d-tfj8x                    3/9     Not Ready   0          11m
       ```

       CFS sessions which are in "Not Ready" status are still in progress. CFS sessions with status "Error" had a failure in one of the layers.
    1. Inspect all layers of Ansible configuration to find a failed layer.

       ```bash
       ncn# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-0
       ncn# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-1
       ncn# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-2
       ncn# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-3
       ncn# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-4
       ncn# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-5
       ncn# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-6
       ncn# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-7
       ncn# kubectl logs -f -n services cfs-51a7665d-l63d-41ab-e93e-796d5cb7b823-czkhk ansible-8
       ```

    1. If the slingshot-host-software has completed and the COS layer has run, but fails to mount Lustre
       filesystems, then several roles have already been run to load DVS, Lnet, and Lustre kernel modules.
       These need to be unloaded before NCN personalization can be run again.  This is due to a flaw
       in the slingshot-host-software which restarts the openibd service for worker nodes which have
       Mellanox NICs.

       Otherwise, do not continue in this procedure.

1. Check out `cos-config-management` from VCS.

   **Important:** The rest of this procedure is only needed when the Lustre filesystems failed to mount as checked in the previous step.

   Create a branch using the imported branch from the installation to customize COS.

   The imported branch will be reported in the `cray-product-catalog` and can be used as a base branch. The imported branch from
   the installation should not be modified. It is recommended that a branch is created from the imported branch to customize COS
   configuration content as necessary. The following steps create an integration branch to accomplish this.

   1. Obtain the `import_branch` from the `cray-product-catalog`.

      Set the `COS_RELEASE` to the version of COS 2.3 which has been installed.

      ```bash
      ncn# export COS_RELEASE=2.3.101
      ncn# kubectl get cm cray-product-catalog -n services -o yaml \
      | yq r - 'data.cos' | yq r - \"${COS_RELEASE}\"
      ```

      Example output:

      ```text
      2.3.XX:
        configuration:
          clone_url: https://vcs.DOMAIN_NAME.dev.cray.com/vcs/cray/cos-config-management.git
          commit: 215eab2c316fb75662ace6aaade8b8c2ab2d08ee
          import_branch: cray/cos/2.3.XX
          import_date: 2021-02-21 23:01:16.100251
          ssh_url: git@vcs.DOMAIN_NAME.dev.cray.com:cray/cos-config-management.git
        images: {}
        recipes:
          cray-shasta-compute-sles15sp3.x86_64-1.4.64:
            id: 5149788d-4e5d-493d-b259-f56156a58b0d
      ```

   1. Store the import branch for later use.

      ```bash
      ncn# export IMPORT_BRANCH=cray/cos/${COS_RELEASE}
      ```

   1. Obtain the credentials for the `crayvcs` user from a Kubernetes secret. The credentials are required for cloning a branch from
      VCS. Use git to clone the COS configuration content.

      ```bash
      ncn# kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | \
      base64 --decode && echo
      <==password output==>

      ncn# git clone https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git
      Username for 'https://api-gw-service-nmn.local': crayvcs
      Password for 'https://crayvcs@api-gw-service-nmn.local': <password from preceding output>

      ncn# cd cos-config-management/
      ncn# git checkout -b $IMPORT_BRANCH origin/$IMPORT_BRANCH
      Branch 'cray/cos/<X>.<Y>.<Z>' set up to track remote branch 'cray/cos/<X>.<Y>.<Z>' from 'origin'.
      Switched to a new branch 'cray/cos/<X>.<Y>.<Z>'
      ```

   1. If the integration branch exists, run the following command:

      ```bash
      ncn# git checkout -b integration origin/integration
      Branch 'integration' set up to track remote branch 'integration' from 'origin'.
      Switched to a new branch 'integration'
      ```

   1. Merge import branch into integration branch:

      ```bash
      ncn# git merge $IMPORT_BRANCH
      ```

1. Create a new `ncn-powerup.yml` playbook

   Copy the `ncn-upgrade.yml` playbook to `ncn-powerup.yml`.
   Edit the file with two changes.
   * Change serial parameter from `1` node to `100%`
   * Comment all roles after the ones with names ending in uninstall, unmount, and unload. See the example below.

   ```bash
   ncn# cp -p ncn-upgrade.yml ncn-powerup.yml
   ncn# vi ncn-powerup.yml
   ncn# cat ncn-powerup.yml
   ```

   Example output

   ```text
   #!/usr/bin/env ansible-playbook
   # Copyright 2021-2022 Hewlett Packard Enterprise Development LP
   
   ---
   - hosts: Management_Worker
     serial: 100%
     any_errors_fatal: true
     remote_user: root
     roles:
       - configure_fs_unload
       - cray_dvs_unmount
       - cray_dvs_unload
       - cray_lnet_unload
       - cray_dvs_uninstall
       - cray_lnet_uninstall
   #    - cos-services-install
   #    - cos-services-restart
   #    - cray_lnet_install
   #    - cray_dvs_install
   #    - cray_lnet_load
   #    - cray_dvs_load
   #    - lustre_config
   #    - configure_fs
   ```

1. Commit the new `ncn-powerup.yml` to `cos-config-management` VCS repo.

   ```bash
   ncn# git add ncn-powerup.yml
   ncn# git commit -m "Patched with ncn-powerup.yml playbook"
   ncn# git push origin integration

1. Identify the commit hash for this branch. This will be used later when creating the CFS configuration layer.

   ```bash
   ncn# git rev-parse --verify HEAD
   <== commit hash output ==>
   ```

1. Store the commit hash for later use.

   ```bash
   ncn# export COS_CONFIG_COMMIT_HASH=<commit hash output>
   ```

1. Create a CFS configuration which has only a COS layer with this ncn-powerup.yml playbook in it and then run a CFS session with that.

   ```bash
   ncn# vi ncn-powerup.json
   ncn# cat ncn-powerup.json
   {
     "layers": [
       {
         "cloneUrl":"https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git",
         "commit":"<COS_CONFIG_COMMIT_HASH>",
         "name": "cos-integration-2.3.101",
         "playbook":"ncn-powerup.yml"
       }
     ]
   }
   ncn# cray cfs configurations update ncn-powerup --file ncn-powerup.json --format json
   ncn# cray cfs sessions create --name ncn-powerup --configuration-name ncn-powerup
   ```

1. Watch the CFS session run on the worker nodes.

   ```bash
   ncn# kubectl -n services --sort-by=.metadata.creationTimestamp get pods | grep cfs
   ncn# kubectl logs -f -n services POD ansible-0
   ```

   Continue only when there are no errors in the Ansible log.

1. Clear the error counts on all nodes so that CFS batcher can run NCN personalization on all worker nodes. This will have the SHS openibd restart, then will see all of the COS stuff as never been done and should load lnet, dvs, and Lustre just fine.

   ```bash
   ncn# cray cfs components update --enabled true --state '[]' --error-count 0 --format json $XNAME
   ```

1. Watch the CFS NCN personaliation run on the worker nodes to ensure that the configuration completes with no further errors.

   ```bash
   ncn# kubectl -n services --sort-by=.metadata.creationTimestamp get pods | grep cfs
   ncn# kubectl logs -f -n services POD ansible-0
   ```
