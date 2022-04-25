# Adding a Ceph Node to the Ceph Cluster

**NOTE:** This operation can be done to add more than one node at the same time.

## Add Join Script

1. Copy join script from `ncn-m001` to the storage node that was rebuilt or added.

    > Run this command on the storage node that was rebuilt or added.

    ```bash
    ncn-s# mkdir -pv /usr/share/doc/csm/scripts &&
           scp -p ncn-m001:/usr/share/doc/csm/scripts/join_ceph_cluster.sh /usr/share/doc/csm/scripts
    ```

1. Start monitoring the Ceph health alongside the main procedure.

    In a separate window, run the following command on `ncn-s001`, `ncn-s002`, or `ncn-s003` (but not the same node that was rebuilt or added):

    ```bash
    ncn-s# watch ceph -s
    ```

1. Execute the script from the first step.

    > Run this command on the storage node that was rebuilt or added.

    ```bash
    ncn-s# /usr/share/doc/csm/scripts/join_ceph_cluster.sh
    ```

    **IMPORTANT:** In the output from `watch ceph -s` the health should go to a `HEALTH_WARN` state. This is expected. Most commonly you will see an alert about `failed to probe daemons or devices`, but this should clear on its own. In addition, it may take up to 5 minutes for the added OSDs to report as `up`.  This is dependent on the Ceph Orchestrator performing an inventory and completing batch processing to add the OSDs.

## Zapping OSDs

**IMPORTANT:** Only do this if you are 100% certain you need to erase data from a previous install.

**NOTE:** The commands in this section will need to be run from a node running `ceph-mon`. Typically `ncn-s001`, `ncn-s002`, or `ncn-s003`.

1. Find the devices on the node being rebuilt.

   ```bash
   ncn-s# ceph orch device ls $NODE
   ```

   Example Output:

   ```screen
   Hostname  Path      Type  Serial          Size   Health   Ident  Fault  Available
   ncn-s003  /dev/sdc  ssd   S455NY0MB42493  1920G  Unknown  N/A    N/A    No
   ncn-s003  /dev/sdd  ssd   S455NY0MB42482  1920G  Unknown  N/A    N/A    No
   ncn-s003  /dev/sde  ssd   S455NY0MB42486  1920G  Unknown  N/A    N/A    No
   ncn-s003  /dev/sdf  ssd   S455NY0MB51808  1920G  Unknown  N/A    N/A    No
   ncn-s003  /dev/sdg  ssd   S455NY0MB42473  1920G  Unknown  N/A    N/A    No
   ncn-s003  /dev/sdh  ssd   S455NY0MB42468  1920G  Unknown  N/A    N/A    No
   ```

   **IMPORTANT:** In the above example the drives on our rebuilt node are showing `Available = no`. This is expected because the check is based on the presence of an LVM on the volume.

   **NOTE:** The `ceph orch device ls $NODE` command excludes the drives being used for the OS. Please double check that you are not seeing OS drives. These will have a size of `480G`.

1. Zap the drives.

   ```bash
   ncn-s# for drive in $(ceph orch device ls $NODE --format json-pretty |jq -r '.[].devices[].path') ; do
             ceph orch device zap $NODE $drive --force
          done
   ```

1. Validate that the drives are being added to the cluster.

   ```bash
   ncn-s# watch ceph -s
   ```

   The OSD `up` and `in` counts should increase. If the `in` count increases but does not reflect the amount of drives being added back in, then fail over the `ceph-mgr` daemon. This is a known bug and is addressed in newer releases.

   If you need to fail over the `ceph-mgr` daemon, run:

   ```bash
   ncn-s# ceph mgr fail
   ```

## Regenerate Rados-GW Load Balancer Configuration for the Rebuilt Nodes

   **IMPORTANT:** `radosgw` by default is deployed to the first 3 storage nodes. This includes `haproxy` and `keepalived`. This is automated as part of the install, but you may have to regenerate the configuration if you are not running on the first 3 storage nodes or all nodes.

1. Deploy Rados Gateway containers to the new nodes.

   - If running Rados Gateway on all nodes is the desired configuration then run:

      ```bash
      ncn-s00(1/2/3)# ceph orch apply rgw site1 zone1 --placement="*" --port=8080
      ```

   - If deploying to select nodes then do:

     ```bash
     ncn-s00(1/2/3)# ceph orch apply rgw site1 zone1 --placement="<num-daemons> <node1 node2 node3 node4 ... >" --port=8080
     ```

1. Verify that Rados Gateway is running on the desired nodes.

    ```bash
    ncn-s00(1/2/3)# ceph orch ps --daemon_type rgw
    NAME                             HOST      STATUS         REFRESHED  AGE  VERSION  IMAGE NAME                         IMAGE ID      CONTAINER ID
    rgw.site1.zone1.ncn-s001.kvskqt  ncn-s001  running (41m)  6m ago     41m  15.2.8   registry.local/ceph/ceph:v15.2.8   553b0cb212c   6e323878db46
    rgw.site1.zone1.ncn-s002.tisuez  ncn-s002  running (41m)  6m ago     41m  15.2.8   registry.local/ceph/ceph:v15.2.8   553b0cb212c   278830a273d3
    rgw.site1.zone1.ncn-s003.nnwuqy  ncn-s003  running (41m)  6m ago     41m  15.2.8   registry.local/ceph/ceph:v15.2.8   553b0cb212c   a9706e6d7a69
    ```

1. Add nodes into HAproxy and KeepAlived. Adjust the command based on the number of storage nodes.

   - If the node was rebuilt:

     ```bash
     ncn-s# source /srv/cray/scripts/metal/update_apparmor.sh; reconfigure-apparmor
     ncn-s# pdsh -w ncn-s00[1-(end node number)] -f 2 \
                '/srv/cray/scripts/metal/generate_haproxy_cfg.sh > /etc/haproxy/haproxy.cfg
                systemctl restart haproxy.service
                /srv/cray/scripts/metal/generate_keepalived_conf.sh > /etc/keepalived/keepalived.conf
                systemctl restart keepalived.service'
     ```

   - If the node was added:

     Determine the IP address of the added node.

     ```bash
     ncn-s# cloud-init query ds | jq -r ".meta_data[].host_records[] | select(.aliases[]? == \"$(hostname)\") | .ip" 2>/dev/null
     ```

     Example Output:

     ```
     10.252.1.13
     ```

     Update the HAproxy config to include the added node. Select a storage node `ncn-s00x` from `ncn-s001`, `ncn-s002`, or `ncn-s003`. This cannot be done from the added node.

     ```
     ncn-s00x# vi /etc/haproxy/haproxy.cfg
     ```

     This example adds or updates `ncn-s004` with the IP address `10.252.1.13` to `backend rgw-backend`.

     ```
     ...
     backend rgw-backend
         option forwardfor
         balance static-rr
         option httpchk GET /
             server server-ncn-s001-rgw0 10.252.1.6:8080 check weight 100
             server server-ncn-s002-rgw0 10.252.1.5:8080 check weight 100
             server server-ncn-s003-rgw0 10.252.1.4:8080 check weight 100
             server server-ncn-s004-rgw0 10.252.1.13:8080 check weight 100   <--- Added or updated line
     ...
     ```

     Copy the updated HAproxy config to all the storage nodes. Adjust the command based on the number of storage nodes.

     ```bash
     ncn-s00x# pdcp -w ncn-s00[1-(end node number)] /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg
     ```

     Configure `apparmor` and KeepAlived **on the added node** and restart the services across all the storage nodes.

     ```bash
     ncn-s# source /srv/cray/scripts/metal/update_apparmor.sh; reconfigure-apparmor
     ncn-s# /srv/cray/scripts/metal/generate_keepalived_conf.sh > /etc/keepalived/keepalived.conf
     ncn-s# export  PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no"
     ncn-s# pdsh -w ncn-s00[1-(end node number)] -f 2 'systemctl restart haproxy.service; systemctl restart keepalived.service'
     ```

## Next Step

- If rebuilding the storage node, proceed to [Storage Node Validation](../node_management/Rebuild_NCNs/Post_Rebuild_Storage_Node_Validation.md)
- If adding the storage node, proceed to [Boot NCN - Add storage node to the Ceph cluster](../node_management/Add_Remove_Replace_NCNs/Boot_NCN.md#boot-ncn-storage-nodes-only)
