# Management Nodes Rollout

This section updates the kernel running on management NCNs.

1. [Storage Nodes](#1-storage-nodes)
1. [Worker Nodes](#2-worker-nodes)
1. [Master Nodes](#3-master-nodes)
1. [References](#4-references)
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

   3. Test this set of commands on the `STORAGE_CANARY` node

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
      
      **NOTE** The `management-nodes-rollout` stage creates additional separate Argo workflows when rebuilding NCN storage nodes. The Argo workflow names will include the string `ncn-lifecycle-rebuild`.
      If monitoring progress with the Argo UI, remember to include these workflows.

      > **Known Issue:** If `cloud-init` fails on the storage node with a timed out error, see [storage node `cloud-init` fails with 'Timed out waiting for device' error](../../../troubleshooting/known_issues/storage_node_cloud_init_fails_with_timed_out.md).


      3. (ncn-m001#) Execute the management-nodes-rollout stage with a single NCN storage node.

         ```bash
        iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout ${STORAGE_CANARY}
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
            | x3000c0s13b0n0 | ncn-s001 | storage-26.3.0-rru     | configured           |
            ```

            The desired value for `configuration` is `configured`. If it is `pending`, then wait for the status to change to `configured`.

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

   3. Get OLDUNAME of remaining storage nodes.

       ```bash
      STORAGE_NODES="$(ceph orch host ls | grep ncn-s | grep -v "$STORAGE_CANARY" | awk '{print $1}' | xargs echo)"
      echo "$STORAGE_NODES"
      for node in $STORAGE_NODES
      do
         OLDUNAME=$(ssh $node 'uname -r')
         echo $OLDUNAME
      done
      ```
   4. Execute the management-nodes-rollout stage on the remaining storage nodes.

      ```bash
      iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout ${STORAGE_NODES}
      ```

   4. Verify that all storage nodes are now configured and the kernel version is changed.

      ```bash
      for ncn in $(cray hsm state components list --subrole Storage --type Node \
      --format json | jq -r .Components[].ID | grep b0n | sort); do cray cfs components describe \
      $ncn --format json | jq -r ' .id+" "+.desiredConfig+" status="+.configurationStatus'; done

      for node in $STORAGE_NODES
      do
         NEWUNAME=$(ssh $node 'uname -r')
         echo $NEWUNAME
      done
      ```

   5. Verify Ceph health reports `HEALTH_OK` before continuing.

      ```bash
      ceph health
      ```

      Use this command to get more detail about Ceph health status.

      ```bash
      ceph -s
      ```

   6. Clean up old images on the storage nodes:

      ```bash
      for node in $STORAGE_NODES
      do
         echo $node
         ssh $node /srv/cray/scripts/metal/cleanup-live-images.sh -y -o
      done
      ```

## 2. Worker Nodes

Roll out the new image and CFS configuration to one worker node, validate the change, then a second worker node, then proceed to the rest of the worker nodes.

   1. If the iscsi_worker group is present then selective iSCSI worker node personalizatiuon feature is enabled else all worker nodes by default are enabled as iSCSI targets.
   
      Identify which worker nodes are configured as iSCSI targets.

      ```bash
      ncn-m001:~ # cray hsm groups list | grep iscsi_worker
      label = "iscsi_worker"
      ```

      If label is not found then skip to next step.

      ```
      ncn-m001:~ # cray hsm groups members list iscsi_worker
      ids = [ "x3000c0s7b0n0", "x3000c0s9b0n0", "x3000c0s11b0n0",]
      ```

   1. Set `iscsid.safe_logout=No` for iSCSI clients on the application and compute nodes.
      
      > **Important:** The iSCSI LUNs mapping to `rootfs/PE` images before worker node rebuild can get mapped to different `rootfs/PE` images after the
      > rebuild and get different LUN numbers. The iSCSI client nodes will send the I/O’s to the iSCSI LUNs that were created before rebuild and I/O’s
      > fail as those LUNs may not exist with the same LUN number or mapped to different images after rebuild.

      1. Determine the hostnames of the application nodes.

         ```bash
         APPNODES="$(sat status --filter role=application --filter Enabled=true --fields aliases --no-borders --no-headings | xargs | sed 's/ /,/g')"
         echo $APPNODES
         ```

      1. Determine the hostnames for the compute nodes.  Two different methods are shown.  Use the one which produces a more compact list in the variable.

         **Note:** The compute node hostnames should have "-nmn" as the suffix so that they can be reached from a master node using the `NMN`. The master nodes are not on the `HSN`.

         ```bash
         COMPUNODES=nid[001000-001255]-nmn
         COMPUNODES="$(sat status --filter role=compute --filter Enabled=true --fields aliases --no-borders --no-headings | xargs | sed 's/ /-nmn,/g' | sed 's/$/-nmn/')"
         echo $COMPUNODES
         ```

      1. Copy the `iscsi_post_rollout.sh` script to all application and compute nodes.

         ```bash
         pdsh -t2 -f256 -w $APPNODES,$COMPUNODES 'zypper --non-interactive install pdsh' | dshbak -c
         pdcp -t2 -f256 -w $APPNODES,$COMPUNODES /usr/share/doc/csm/scripts/operations/iscsi_sbps/iscsi_post_rollout.sh /tmp/
         pdsh -t2 -f256 -w $APPNODES,$COMPUNODES "sed -ri 's/^iscsid.safe_logout =.*/iscsid.safe_logout = No/g' /etc/iscsi/iscsid.conf && systemctl restart iscsid.service && echo Success || echo Fail" 2>/dev/null | dshbak -c
         ```

   1. Select a node to be the `WORKER_CANARY`. This node can be any worker node and does not have to be `ncn-w001`.

      **Note:** Choose the canary node wisely, don't use one running slingshot-fabric-manager or nexus.

      ```bash
      WORKER_CANARY=ncn-w001 
      ```

   1. Ssh to `WORKER_CANARY` and get the current/existing kernel version.

      ```bash
      OLDUNAME=$(ssh $WORKER_CANARY uname -r)
      echo $OLDUNAME
      ```
      Sample output:

      ```bash
      6.4.0-150700.53.52-default
      ```

   1. Execute the `management-nodes-rollout` stage of `IUF` with the `WORKER_CANARY`.

      **Warning:** To maintain health of the iSCSI clients on application and compute nodes, watch the rebuild workflow for each node including the console log for the node being rebuilt with a new image. After each worker node has powered off Linux and then the node powers on and begins to show POST/BIOS messages, there is an action in the next step which must be done on the application and compute nodes to run the `iscsi_post_rollout.sh` script on all `iSCSI` clients.

      ```bash
      iuf -a ${ACTIVITY_NAME} -m ${MEDIA_DIR} run -r management-nodes-rollout --limit-management-rollout $WORKER_CANARY
      ```

   1. If the selected `WORKER_CANARY` is an iSCSI target node then execute `iscsi_post_rollout.sh` script to help the `iSCSI` clients on the application and compute nodes to adjust to the new LUNs on the worker node.

      **Important:** Ensure that the hostname REPLACEHOST is replaced with the actual value of the worker node hostname before running these commands.

      ```bash
      pdsh -t2 -f256 -w $APPNODES,$COMPUNODES 'iscsiadm -m session -P 3 | grep -A20 REPLACEHOST | grep "State: L"' 2>/dev/null
      pdsh -t2 -f256 -w $APPNODES,$COMPUNODES "sh /tmp/iscsi_post_rollout.sh $WORKER_CANARY && echo Success" 2>/dev/null | dshbak -c
      pdsh -t2 -f256 -w $APPNODES,$COMPUNODES 'iscsiadm -m session -P 3 | grep -A20 REPLACEHOST | grep "State: L"' 2>/dev/null
      ```

   1. (ncn-m001#) Verify that the node booted successfully with the desired image and CFS configuration.

      ```bash
      XNAME=$(ssh $WORKER_CANARY 'cat /etc/cray/xname')
      echo "${XNAME}"
      cray cfs components describe "${XNAME}"
      ```

   1. Verify that the kernel version has changed.

      ```bash
      NEWUNAME=$(ssh $WORKER_CANARY uname -r)
      echo $OLDUNAME
      echo $NEWUNAME
      ```

      Sample output:

      ```bash
      6.4.0-150700.53.52-default
      6.4.0-150700.53.78-default
      ```

   1. ncn-m001#) Use kubectl to apply the iuf-prevent-rollout=true label to the node to prevent it from unnecessarily rebuilding again.

      ```bash
      kubectl label nodes "${WORKER_CANARY}" --overwrite iuf-prevent-rollout=true
      ```

   1. (ncn-m001#) Verify that the IUF node label is present on the worker canary node.

      ```bash
      kubectl get nodes "${WORKER_CANARY}" --show-labels | grep iuf-prevent-rollout
      ```

   1. When using the option --limit-management-rollout to pass the list of nodes for management-nodes-rollout, ensure that the label iuf-prevent-rollout=true is not set on any of the nodes passed in the list.
   
      ```bash
      kubectl get nodes --show-labels | grep iuf-prevent-rollout
      ```
   
      If necessary, use kubectl to remove the iuf-prevent-rollout=true label from the node.
   
      ```bash
      kubectl label nodes "${NODE}" --overwrite iuf-prevent-rollout-
      ```
   
   1. Select a second node to be the `WORKER_CANARY2`. This node can be any worker node and does not have to be `ncn-w002`.

      **NOTE** During the worker node rollout, ensure that at least two worker nodes (iSCSI SBPS targets) remain healthy after each rollout batch to maintain high availability for iSCSI SBPS. You can rollout one more worker node other than the worker canary node to be labeled with `iuf-prevent-rollout=true` followed by rolling out the rest of the worker nodes.

      **Note:** Choose the canary node wisely, don't use one running slingshot-fabric-manager or nexus.

      ```bash
      WORKER_CANARY2=ncn-w002 
      ```

   1. Ssh to `WORKER_CANARY2` and get the current/existing kernel version.

      ```bash
      OLDUNAME=$(ssh $WORKER_CANARY2 uname -r)
      echo $OLDUNAME
      ```
      Sample output:

      ```bash
      6.4.0-150700.53.52-default
      ```

   1. Execute the `management-nodes-rollout` stage of `IUF` with the `WORKER_CANARY2`.

      **Warning:** To maintain health of the iSCSI clients on application and compute nodes, watch the rebuild workflow for each node including the console log for the node being rebuilt with a new image. After each worker node has powered off Linux and then the node powers on and begins to show POST/BIOS messages, there is an action in the next step which must be done on the application and compute nodes to run the `iscsi_post_rollout.sh` script on all `iSCSI` clients.

      ```bash
      iuf -a ${ACTIVITY_NAME} -m ${MEDIA_DIR} run -r management-nodes-rollout --limit-management-rollout $WORKER_CANARY2
      ```

   1. Only if the selected `WORKER_CANARY2` is an iSCSI target node then execute `iscsi_post_rollout.sh` script to help the `iSCSI` clients on the application and compute nodes to adjust to the new LUNs on the worker node.


      **Important:** Ensure that the hostname REPLACEHOST is replaced with the actual value of the worker node hostname before running these commands.

      ```bash
      pdsh -t2 -f256 -w $APPNODES,$COMPUNODES 'iscsiadm -m session -P 3 | grep -A20 REPLACEHOST | grep "State: L"' 2>/dev/null
      pdsh -t2 -f256 -w $APPNODES,$COMPUNODES "sh /tmp/iscsi_post_rollout.sh $WORKER_CANARY2 && echo Success" 2>/dev/null | dshbak -c
      pdsh -t2 -f256 -w $APPNODES,$COMPUNODES 'iscsiadm -m session -P 3 | grep -A20 REPLACEHOST | grep "State: L"' 2>/dev/null
      ```

   1. (ncn-m001#) Verify that the node booted successfully with the desired image and CFS configuration.

      ```bash
      XNAME=$(ssh $WORKER_CANARY2 'cat /etc/cray/xname')
      echo "${XNAME}"
      cray cfs components describe "${XNAME}"
      ```

   1. Verify that the kernel version has changed.

      ```bash
      NEWUNAME=$(ssh $WORKER_CANARY2 uname -r)
      echo $OLDUNAME
      echo $NEWUNAME
      ```

      Sample output:

      ```bash
      6.4.0-150700.53.52-default
      6.4.0-150700.53.78-default
      ```

   1. ncn-m001#) Use kubectl to apply the iuf-prevent-rollout=true label to the node to prevent it from unnecessarily rebuilding again.

      ```bash
      kubectl label nodes "${WORKER_CANARY2}" --overwrite iuf-prevent-rollout=true
      ```

   1. (ncn-m001#) Verify that the IUF node label is present on the worker canary node.

      ```bash
      kubectl get nodes "${WORKER_CANARY2}" --show-labels | grep iuf-prevent-rollout
      ```

   1. When using the option --limit-management-rollout to pass the list of nodes for management-nodes-rollout, ensure that the label iuf-prevent-rollout=true is not set on any of the nodes passed in the list.
   
      ```bash
      kubectl get nodes --show-labels | grep iuf-prevent-rollout
      ```
   
      If necessary, use kubectl to remove the iuf-prevent-rollout=true label from the node.
   
      ```bash
      kubectl label nodes "${NODE}" --overwrite iuf-prevent-rollout-
      ```
   
   1. Execute the management-nodes-rollout stage on all remaining worker nodes.

      **NOTE** For this step, the argument to --limit-management-rollout can be `Management_Worker` or a list of worker node names separated by spaces. If `Management_Worker` is supplied, all worker nodes that are not labeled with `iuf-prevent-rollout=true` will be rebuilt/upgraded. If a list of worker node names is supplied, then those worker nodes will be rebuilt/upgraded.
      
      **Warning:** To maintain health of the iSCSI clients on application and compute nodes, watch the rebuild workflow for each node including the console log for the node being rebuilt with a new image. After each worker node has powered off Linux and then the node powers on and begins to show POST/BIOS messages, there is an action in the next step which must be done on the application and compute nodes to run the `iscsi_post_rollout.sh` script on all `iSCSI` clients.

      1. Choose one of the following two options. The difference between the options is the limit-management-rollout argument, but the two options do the same thing.
      
         1. Option 1:

            ```bash
            iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout Management_Worker
            ```

         2. Option 2:

            Execute management-nodes-rollout on a group of worker nodes. The list of worker nodes can be manually edited if it is undesirable to rebuild/upgrade all of the workers with one execution.
      
            ```bash
            WORKER_NODES=$(kubectl get node | grep -P 'ncn-w\d+' | grep -v $WORKER_CANARY |  awk '{print $1}' | xargs)
            echo $WORKER_NODES
            iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout $WORKER_NODES
            ```

      1. Execute `iscsi_post_rollout.sh` script to help the `iSCSI` clients on the application and compute nodes to adjust to the new LUNs on the worker node.

         **Warning:** as each node from the previous `IUF management-nodes-rollout` command gets to the point where Linux has powered off and the node powers on to show POST/BIOS messages, then run these `pdsh` commands on all `iSCSI` clients.

         **Important:** Ensure that the hostname REPLACEHOST is replaced with the actual value of the worker node hostname which has just started powering on before running these commands.

         ```bash
         pdsh -t2 -f256 -w $APPNODES,$COMPUNODES 'iscsiadm -m session -P 3 | grep -A20 REPLACEHOST | grep "State: L"' 2>/dev/null
         pdsh -t2 -f256 -w $APPNODES,$COMPUNODES "sh /tmp/iscsi_post_rollout.sh REPLACEHOST && echo Success" 2>/dev/null | dshbak -c
         pdsh -t2 -f256 -w $APPNODES,$COMPUNODES 'iscsiadm -m session -P 3 | grep -A20 REPLACEHOST | grep "State: L"' 2>/dev/null
         ```

   1. After all worker nodes have finished their image rollout, set `iSCSI` `iscsid.safe_logout=Yes` again and restart `iscsid.service` on all application and compute nodes.

      ```bash
      pdsh -t2 -f256 -w $APPNODES,$COMPUNODES "sed -ri 's/^iscsid.safe_logout =.*/iscsid.safe_logout = Yes/g' /etc/iscsi/iscsid.conf && systemctl restart iscsid.service"
      ```

   1. (ncn-m001#) Use kubectl to remove the iuf-prevent-rollout=true label from the canary node.

      ```bash
      kubectl label nodes "${WORKER_CANARY ${WORKER_CANARY2}" --overwrite iuf-prevent-rollout-
      ```

   1. (ncn-m001#) Verify that all worker nodes configured successfully.

      ```bash
      for ncn in $(cray hsm state components list --subrole Worker --type Node \
          --format json | jq -r .Components[].ID | grep b0n | sort)
      do
          cray cfs components describe $ncn --format json | jq -r ' .id+" "+.desiredConfig+" status="+.configurationStatus'
      done
      ```

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
      /root/.screenrc
      /root/.ssh/authorized_keys
      /root/.ssh/config
      ```

      This list is not exhaustive and there might be other files important for some systems, such as `crontab` entries.

      If SDU and RDA are configured on this node, save the configuration information so it can be restored after the node has the new image.

   3. Rebuild the master node.

      ```bash
      /usr/share/doc/csm/upgrade/scripts/rebuild/ncn-rebuild-master-nodes.sh $MASTER
      ```

      **Warning:**  While watching the console for ncn-m003, you might see an error like this as part of a set of looping messages.

      ```bash
      2026-10-20 14:50:09 [ 1617.920705] cloud-init[12514]: error execution phase control-plane-prepare/download-certs: error downloading certs: error downloading the secret: Secret "kubeadm-certs" was not found in the "kube-system" Namespace. This Secret might have expired. Please, run `kubeadm init phase upload-certs --upload-certs` on a control plane to generate a new one
      ```

      If this happens, then follow the [Kubeadm join token missing during NCN rebuild](https://github.com/Cray-HPE/docs-csm/blob/release/1.7/troubleshooting/known_issues/kubeadm_join_token_missing_during_ncn_rebuild.md) procedure which includes steps to promote the initial master script which clears the Kubernetes bootstrap tokens, loads them into a `cluster-info` config map and regenates the Kubernetes join scripts in /etc/cray/kubernetes, then configures an hourly cronjob to create/update the tokens.  After that the node being rebuilt will have to be power cycled to attempt the rebuild again.

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
      /root/.screenrc
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

1. Update `ncn-m001`.

   1. Show the value of the `MASTER_IMAGE_ID`.  This environment variable will need to be set after logging into `ncn-m002`.

      ```bash
      echo $MASTER_IMAGE_ID
      ```

   1. Determine the SYSTEM_NAME for the system.

      ```bash
      SYSTEM_NAME=kubectl get secret site-init -n loftsman -o jsonpath='{.data.customizations\.yaml}' | base64 -d | grep "external:" | cut -f2 -d: | sed -e 's/ //'
      echo $SYSTEM_NAME
      ```

      Example output
      ```bash
      eniac.dev.hpe.com
      ```

   1. Logout of `ncn-m001` and then login to `ncn-m002` so `ncn-m001` can be rebuilt.

      **Note:** Use the CMN hostname to login to `ncn-m002` for the given external name of the system.

      ```bash
      exit
      ssh ncn-m002.cmn.eniac.dev.hpe.com
      ```

   1. Once logged into `ncn-m002`, set the MASTER_IMAGE_ID for the new image to be used on `ncn-m001`.

      ```bash
      export MASTER_IMAGE_ID=d5c99503-096f-4279-a0a9-be4789a1bea5
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
   
   4. Check for important files which are not backed up from the node.

      **Warning:** If there are any special local files customized, they will be removed when the storage on the node is wiped.
   
      Some master nodes have information in these files which is not placed there by CFS Ansible tasks and might disappear if not backed up.
   
      ```bash
      /etc/hosts
      /etc/motd
      /root/.bashrc
      /root/.config/cray
      /root/.config/sat
      /root/.screenrc
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

1. Restore the SDU and RDA configuration on the master node.

1. Verify that all master nodes have completed CFS configuration.

   ```bash
   for ncn in $(cray hsm state components list --subrole Master --type Node \
     --format json | jq -r '.Components[].ID' | grep b0n | sort)
   do
     cray cfs components describe "$ncn" --format json \
       | jq -r '.id + " " + .desiredConfig + " status=" + .configurationStatus'
   done
   ```

## 4. References

- [Management Rollout workflow](https://cray-hpe.github.io/docs-csm/en-17/operations/iuf/workflows/management_rollout/)
- [`management-nodes-rollout` stage](https://cray-hpe.github.io/docs-csm/en-17/operations/iuf/stages/management_nodes_rollout/)
- [Boot storage node into new image](https://cray-hpe.github.io/docs-csm/en-17/operations/node_management/boot_storage_node_into_new_image/)
- [Rebuild NCNs](https://cray-hpe.github.io/docs-csm/en-17/operations/node_management/rebuild_ncns/rebuild_ncns/)

## 5. Next steps

- Return to the
  [Deploying Rapid Release Update with IUF](installation_iuf.md)
  workflow to continue the install.
