# Management Nodes Rollout

This section updates the kernel running on management NCNs.

1. [Storage Nodes](#1-storage-nodes)
1. [Worker Nodes](#2-worker-nodes)
1. [Master Nodes](#3-master-nodes)
1. [Post Rollout Verification](#4-post-rollout-verification)
1. [Stop typescript](#4-stop-typescript)
1. [Next Steps](#5-next-steps)

> **Important:** Because csm-security includes kernel updates, **all node
> types** must be rebooted into new images. The standard docs-csm
> non-CSM-upgrade workflow (section 2.2) only applies CFS configuration to
> master and storage nodes — it does not reboot them. You must follow the
> full image rollout procedures below for all management node types to ensure
> all management nodes are rebuilt to include these new CSM Security fixes.

> **Note:** The rollout order below (Storage → Worker → Master) follows
> the full image rollout sequence used during CSM upgrades. Because
> csm-security includes kernel updates, this is effectively a full image
> upgrade rather than a simple CFS personalization.

## 1. Storage Nodes

   Roll out the new image and CFS configuration to one storage node at a time.
   Wait for Ceph `HEALTH_OK` before proceeding to the next node.

   2. Determine the number of storage nodes on the system.

      ```bash
      STORAGE_NODES="$(ceph orch host ls | grep ncn-s | awk '{print $1}' | xargs echo)"
      echo "$STORAGE_NODES"
      ```

   > **Important:** Storage nodes use a different CFS configuration than worker
   > nodes. Choose one storage node to be the canary — verify the kernel update and CFS
   > personalization succeeded before proceeding to the remaining storage nodes.

   3. Test this set of commands on the `STORAGE_CANARY` node, then repeat for the remaining storage nodes.

      1. Record the existing kernel version on the first storage node.

         ```bash
         STORAGE_CANARY=ncn-s001
         OLDUNAME=$(ssh $STORAGE_CANARY uname -r)
         echo $OLDUNAME
         ```

      2. Record the xname of the STORAGE_CANARY node.

         ```bash
         XNAME=$(ssh $STORAGE_CANARY 'cat /etc/cray/xname')
         echo "${XNAME}"
         ```

      3. Assign the new image to BSS.

         ```bash
         /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh \
           -p $STORAGE_IMAGE_ID $XNAME
         ```

      6. Follow the steps for one of the two options depending on the status of the storage node.

         1. Option 1: Start a new storage node upgrade if one has not already been started.

            **Note:** if a new CFS configuration is also necessary, append the argument `--desired-cfs-conf <configuration>` to the command below.

            ```bash
            /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh $STORAGE_CANARY --upgrade --image-id $STORAGE_IMAGE_ID
            ```

         2. Option 2: If a storage node has already attempted to boot into a new image and `cloud-init` has failed, manually power cycle the node.

            The following error will be seen in `cloud-init` if a storage node has already been attempted to be upgraded without setting rd.live.dir to a new
            unique value. This error can be seen for the node’s console.
            See [log in to a node using ConMan](https://cray-hpe.github.io/docs-csm/en-16/operations/conman/log_in_to_a_node_using_conman/).

            ```bash
            [ TIME ] Timed out waiting for device /dev/disk/by-label/CEPHETC.
            [DEPEND] Dependency failed for File System Check on /dev/disk/by-label/CEPHETC.
            [DEPEND] Dependency failed for /etc/ceph.
            [DEPEND] Dependency failed for Local File Systems.
            [DEPEND] Dependency failed for Early Kernel Boot Messages.
            [ TIME ] Timed out waiting for device /dev/disk/by-label/CEPHVAR.
            [DEPEND] Dependency failed for /var/lib/ceph.
            [DEPEND] Dependency failed for File System Check on /dev/disk/by-label/CEPHVAR.
            ```

            1. (ncn-m001#) Power cycle the storage node. Follow the steps in [Power Cycle and Rebuild Nodes](https://cray-hpe.github.io/docs-csm/en-16/operations/node_management/rebuild_ncns/power_cycle_and_rebuild_nodes/)
                to power cycle the node. Do not perform steps after “wait for cloud-init”. These steps are unnecessary and will be completed by the remaining steps of the storage node upgrade Argo Workflow.

            2. (ncn-m001#) Perform this step only if the Argo workflow for the storage node upgrade was stopped. Resume the workflow by simply rerunning the same command that initiated the upgrade workflow. When a workflow is in-progress or a workflow has failed, that same workflow will be resumed and no new workflow will be started by running the command.

               ```bash
               /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh $STORAGE_CANARY --upgrade --image-id $STORAGE_IMAGE_ID
               ```

      7. (ncn-m001#) Monitor the Argo Workflow using the Argo UI. See [using the Argo UI for instructions to access the Argo UI](https://cray-hpe.github.io/docs-csm/en-17/operations/argo/using_the_argo_ui/).

      8. After the node boots, verify the node:

         1. Verify that the kernel version has changed.

            ```bash
            NEWUNAME=$(ssh $STORAGE_CANARY uname -r)
            echo "Old: $OLDUNAME"
            echo "New: $NEWUNAME"
            ```

         2. Verify CFS configuration status shows `configured`.

            ```bash
            sat status --filter subrole=Storage --fields xname,aliases,desired,configuration | grep $STORAGE_CANARY
            ```

            Example output:

            ```bash
            | x3000c0s7b0n0 | ncn-s001 | management-26.3.1 | configured           |
            ```

         3. Verify Ceph health reports `HEALTH_OK` before continuing.

            ```bash
            ceph health
            ```

            Use this command to get more detail about Ceph health status.

            ```bash
            ceph -s
            ```

      7. Clean up old images on the node:

         ```bash
         ssh $STORAGE_CANARY /srv/cray/scripts/metal/cleanup-live-images.sh -y -o
         ```

   3. Repeat the above steps changing STORAGE_CANARY one at a time to be each of the remaining storage nodes.

   4. Verify that all storage nodes are now configured.

      ```bash
      for ncn in $(cray hsm state components list --subrole Storage --type Node \
      --format json | jq -r .Components[].ID | grep b0n | sort); do cray cfs components describe \
      $ncn --format json | jq -r ' .id+" "+.desiredConfig+" status="+.configurationStatus'; done
      ```

   5. Verify Ceph health reports `HEALTH_OK` before continuing.

      ```bash
      ceph health
      ```

      Use this command to get more detail about Ceph health status.

      ```bash
      ceph -s
      ```

## 2. Worker Nodes
Roll out the new image and CFS configuration to one worker node, validate the change, then proceed to the rest of the worker nodes.

1. Verify there is no "iuf-prevent-rollout" label set on worker-nodes.
   ```bash
   kubectl get nodes --show-labels | grep iuf-prevent-rollout
   ```
2. If there are nodes with "iuf-prevent-rollout" label, remove the label using:
   ```bash
   kubectl label nodes "NODE" --overwrite iuf-prevent-rollout-
   ```
   Here replace NODE with the name of the node being labelled.

3. Select a node to be the `WORKER_CANARY`. This node can be any worker node and does not have to be `ncn-w001`.
   **Note:** Choose the canary node wisely, don't use one running slingshot-fabric-manager or nexus. The worker canary node can be any worker node and does not have to be ncn-w001.
   ```bash
   WORKER_CANARY=ncn-w001 
   ```

4. SSH to `WORKER_CANARY` and get the current/existing kernel version.
   
   ```bash
   OLDUNAME=$(ssh $WORKER_CANARY uname -r)
   echo $OLDUNAME
   ```
   Sample output:

   ```bash
   6.4.0-150700.53.52-default
   ```

5. Use a canary pattern — rebuild one worker first, verify it, then roll out
the rest:

   ```bash
   # Canary: rebuild a single worker
   iuf -a ${ACTIVITY_NAME} -m ${MEDIA_DIR} \
     run -r management-nodes-rollout \
     --limit-management-rollout $WORKER_CANARY
   ```

1. After reboot, ssh to canary node and get the new kernel version to compare to value of $OLDUNAME

   ```bash
   NEWUNAME=$(ssh $WORKER_CANARY uname -r)
   echo $OLDUNAME
   echo $NEWUNAME
   # Verify CFS configuration status:
   sat status --filter subrole=Worker --fields xname,aliases,desired,configuration \
     | grep $WORKER_CANARY
   ```

   Sample output:

   ```bash
   6.4.0-150700.53.52-default
   6.4.0-150700.53.78-default

   ```
2. Ensure to [follow these steps after worker node rollout is complete](https://cray-hpe.github.io/docs-csm/en-17/operations/iscsi_sbps/iscsi_steps_post_rollout/) for iSCSI SBPS.

   **Important**: The iSCSI LUNs mapping to rootfs/PE images before worker node rebuild can get mapped to different rootfs/PE images after the rebuild and get different LUN numbers. The iSCSI client nodes will send the I/O’s to the iSCSI LUNs that were created before rebuild and I/O’s fail as those LUNs may not exist with the same LUN number or mapped to different images after rebuild.

3. Once verified, roll out the remaining workers:

   1. Label the canary node to prevent it from being rebuilt again
   
      ```bash
      kubectl label nodes "${WORKER_CANARY}" --overwrite iuf-prevent-rollout=true
      ```   
   
   2. When using the option --limit-management-rollout to pass the list of nodes for management-nodes-rollout, ensure that the label iuf-prevent-rollout=true is not set on any of the nodes passed in the list.
   
      ```bash
      kubectl get nodes --show-labels | grep iuf-prevent-rollout
      ```
   
      If necessary, use kubectl to remove the iuf-prevent-rollout=true label from the node.
   
      ```bash
      kubectl label nodes "${NODE}" --overwrite iuf-prevent-rollout-
      ```
   
   3. Execute the management-nodes-rollout stage on all remaining worker nodes.

      **NOTE** During the worker node rollout, ensure that at least two worker nodes (iSCSI SBPS targets) remain healthy after each rollout batch to maintain high availability for iSCSI SBPS. You can rollout one more worker node other than the worker canary node to be labeled with `iuf-prevent-rollout=true` followed by rolling out the rest of the worker nodes. Verify the health of these nodes before proceeding to the next batch of worker node rollouts. Continue this process until the rollout of all remaining worker nodes is complete.

      **NOTE** For this step, the argument to --limit-management-rollout can be `Management_Worker` or a list of worker node names separated by spaces. If `Management_Worker` is supplied, all worker nodes that are not labeled with `iuf-prevent-rollout=true` will be rebuilt/upgraded. If a list of worker node names is supplied, then those worker nodes will be rebuilt/upgraded.
      
      **Choose one** of the following two options. The difference between the options is the limit-management-rollout argument, but the two options do the same thing.
      Option 1:
      ```bash
      iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout Management_Worker
      ```
      Option 2:
      Execute management-nodes-rollout on a group of worker nodes. The list of worker nodes can be manually edited if it is undesirable to rebuild/upgrade all of the workers with one execution.
      
      ```bash
      WORKER_NODES=$(kubectl get node | grep -P 'ncn-w\d+' | grep -v $WORKER_CANARY |  awk '{print $1}' | xargs)
      echo $WORKER_NODES
      iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout $WORKER_NODES
      ```
   
   4. Remove the "iuf-prevent-rollout" label set on worker nodes which were rebuild in the previous step.
      ```bash
      kubectl label nodes "${WORKER_NODES}" --overwrite iuf-prevent-rollout-
      ```

   5. Verify the rollout label is removed on all the worker nodes.
      ```bash
      kubectl get nodes --show-labels | grep iuf-prevent-rollout
      ```
      The above command should not return any values.
   
   6. Verify that all worker nodes configured successfully.

      ```bash
      for ncn in $(cray hsm state components list --subrole Worker --type Node \
          --format json | jq -r .Components[].ID | grep b0n | sort)
      do
          cray cfs components describe $ncn --format json | jq -r ' .id+" "+.desiredConfig+" status="+.configurationStatus'
      done
      ```
   7. Ensure to [follow these steps after worker nodes rollout is complete](https://cray-hpe.github.io/docs-csm/en-17/operations/iscsi_sbps/iscsi_steps_post_rollout/) for iSCSI SBPS.
      

## 3. Master Nodes

> **Important:** Master nodes require a full disk-wipe rebuild. A no-wipe
> reboot leaves stale kernels on BOOTRAID and mismatched etcd/Kubernetes PKI
> certificates from the original install.

Rebuild one master at a time: `ncn-m003` → `ncn-m002` → `ncn-m001`.
The rebuild script handles first-master promotion automatically.

1. Verify `/etc/cray/upgrade/csm/myenv` exists and sets `CSM_RELEASE` and `CSM_ARTI_DIR`.

   ```bash
   . /etc/cray/upgrade/csm/myenv
   echo $CSM_RELEASE
   echo $CSM_ARTI_DIR
   ```

1. Update ncn-m003 and ncn-m002 while running commands on ncn-m001.

   1. Record the xname of the MASTER node.

      ```bash
      MASTER=ncn-m003
      XNAME=$(ssh $MASTER 'cat /etc/cray/xname')
      echo "${XNAME}"
      ```

   2. Assign the new image to BSS. The rebuild script sets
      `rd.live.dir=${CSM_RELEASE}` but relies on BSS having the correct S3 URLs
      for kernel, initrd, and rootfs.

      ```bash
      /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh -p $MASTER_IMAGE_ID $XNAME
      ```

   4. Check for important files which are not backed up from the node.

      **Warning:** If there are any special local files customized, they will be removed when the storage on the node is wiped.

      Some master nodes have information in these files which is not placed there by CFS Ansible tasks and might disappear if not backed up.

      ```bash
      /etc/hosts
      /etc/motd
      /root/.bashrc
      /root/.config/cray
      /root/.config/sat
      /root/.ssh/authorized_keys
      /root/.ssh/config
      ```

      This list is not exhaustive and there might be other files important for some systems, such as `crontab` entries.

      If SDU and RDA are configured on this node, save the configuration information so it can be restored after the node has the new image.

   3. Rebuild the master node.

      ```bash
      /usr/share/doc/csm/upgrade/scripts/rebuild/ncn-rebuild-master-nodes.sh $MASTER
      ```

   1. Verify that CFS has completed for this node before moving to the next node.

      ```bash
      cray cfs components describe $XNAME
      ```

   1. Record the xname of the next MASTER node.
   
      ```bash
      MASTER=ncn-m002
      XNAME=$(ssh $MASTER 'cat /etc/cray/xname')
      echo "${XNAME}"
      ```

   2. Assign the new image to BSS. The rebuild script sets
      `rd.live.dir=${CSM_RELEASE}` but relies on BSS having the correct S3 URLs
      for kernel, initrd, and rootfs.

      ```bash
      /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh -p $MASTER_IMAGE_ID $XNAME
      ```
   
   4. Check for important files which are not backed up from the node.

      **Warning:** If there are any special local files customized, they will be removed when the storage on the node is wiped.
   
      Some master nodes have information in these files which is not placed there by CFS Ansible tasks and might disappear if not backed up.
   
      ```bash
      /etc/hosts
      /etc/motd
      /root/.bashrc
      /root/.config/cray
      /root/.config/sat
      /root/.ssh/authorized_keys
      /root/.ssh/config
      ```

      This list is not exhaustive and there might be other files important for some systems, such as `crontab` entries.

      If SDU and RDA are configured on this node, save the configuration information so it can be restored after the node has the new image.

   3. Rebuild the master node.

      ```bash
      /usr/share/doc/csm/upgrade/scripts/rebuild/ncn-rebuild-master-nodes.sh $MASTER
      ```

   1. Verify that CFS has completed for this node.

      ```bash
      cray cfs components describe $XNAME
      ```

1. Update ncn-m001.

   1. Determine the SYSTEM_NAME for the system.

      ```bash
      SYSTEM_NAME=kubectl get secret site-init -n loftsman -o jsonpath='{.data.customizations\.yaml}' | base64 -d | grep "external:" | cut -f2 -d: | sed -e 's/ //'
      echo $SYSTEM_NAME
      ```

      Example output
      ```bash
      eniac.dev.hpe.com
      ```

   1. Logout of ncn-m001 and then login to ncn-m002 so ncn-m001 can be rebuilt.

      **Note:** Use the CMN hostname to login to ncn-m002 for the given external name of the system.

      ```bash
      exit
      ssh ncn-m002.cmn.eniac.dev.hpe.com
      ```

   1. Verify `/etc/cray/upgrade/csm/myenv` exists and sets `CSM_RELEASE` and `CSM_ARTI_DIR`.

      ```bash
      . /etc/cray/upgrade/csm/myenv
      echo $CSM_RELEASE
      echo $CSM_ARTI_DIR
      ```

   1. Record the xname of the MASTER node.
   
      ```bash
      MASTER=ncn-m001
      XNAME=$(ssh $MASTER 'cat /etc/cray/xname')
      echo "${XNAME}"
      ```

   2. Assign the new image to BSS. The rebuild script sets
      `rd.live.dir=${CSM_RELEASE}` but relies on BSS having the correct S3 URLs
      for kernel, initrd, and rootfs.

      ```bash
      /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh -p $MASTER_IMAGE_ID $XNAME
      ```
   
   3. Check for important files which are not backed up from the node.

      **Warning:** If there are any special local files customized, they will be removed when the storage on the node is wiped.
   
      Some master nodes have information in these files which is not placed there by CFS Ansible tasks and might disappear if not backed up.
   
      ```bash
      /etc/hosts
      /etc/motd
      /root/.bashrc
      /root/.config/cray
      /root/.config/sat
      /root/.ssh/authorized_keys
      /root/.ssh/config
      ```

      This list is not exhaustive and there might be other files important for some systems, such as `crontab` entries.

      If SDU and RDA are configured on this node, save the configuration information so it can be restored after the node has the new image.

   4. Rebuild the master node.

      ```bash
      /usr/share/doc/csm/upgrade/scripts/rebuild/ncn-rebuild-master-nodes.sh $MASTER
      ```

   1. Verify that CFS has completed for this node.

      ```bash
      cray cfs components describe $XNAME
      ```

1. Verify that all master nodes have completed CFS configuration.

   ```bash
   for ncn in $(cray hsm state components list --role management --type Node \
     --format json | jq -r '.Components[].ID' | grep b0n | sort)
   do
     cray cfs components describe "$ncn" --format json \
       | jq -r '.id + " " + .desiredConfig + " status=" + .configurationStatus'
   done
   ```

## 4. Post-Rollout Verification

After all nodes are rolled out, validate the system:

- **Online:** [Validate CSM Health](https://cray-hpe.github.io/docs-csm/en-17/operations/validate_csm_health/)
- **On-system:** `/usr/share/doc/csm/operations/validate_csm_health.md`

1. Confirm all management nodes are running the expected kernel:

   ```bash
   pdsh -w $(echo $(ceph orch host ls | grep ncn | cut -f1 -d" " | xargs) $(kubectl get nodes | grep ncn | cut -f1 -d" " | xargs) | sed 's/ /,/g') 'uname -r' |dshbak -c
   ```
   Example output:

   ```bash
   ----------------
   ncn-m[001-003],ncn-s[001-003],ncn-w[001-004]
   ----------------
   6.4.0-150700.53.78-default
   ```

1. Verify the csm-security product is registered in the product catalog:

   ```bash
   sat showrev --products | grep csm-security
   ```

   Expected output:

   ```bash
   | csm-security                        | Rapid-Update-sle15-sp7-171-26.09.01 | -                                           | -                                                   |
   ```

## 5. Stop the typescript


## 6. Next steps

- Return to the
  [Deploying Rapid Release Update with IUF](installation_iuf.md)
  workflow to continue the install.
