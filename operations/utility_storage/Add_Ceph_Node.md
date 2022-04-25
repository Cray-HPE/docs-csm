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

    **IMPORTANT:** In the output from `watch ceph -s` the health should go to a `HEALTH_WARN` state. This is expected. Most commonly you will see an alert about `failed to probe daemons or devices`, but this should clear on its own.

## Zapping OSDs

**IMPORTANT:** Only do this if you were not able to wipe the node prior to rebuild.

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
      ceph orch apply rgw site1 zone1 --placement="*"
      ```

   - If deploying to select nodes then do:

     ```bash
     ceph orch apply rgw site1 zone1 --placement="<node1 node2 node3 node4 ... >"
     ```

1. Verify that Rados Gateway is running on the desired nodes.

    ```bash
    ncn-s00(1/2/3)# ceph orch ps --daemon_type rgw
    ```

    Example output:

    ```
    NAME                             HOST      STATUS         REFRESHED  AGE  VERSION  IMAGE NAME                         IMAGE ID      CONTAINER ID
    rgw.site1.zone1.ncn-s001.kvskqt  ncn-s001  running (41m)  6m ago     41m  15.2.8   registry.local/ceph/ceph:v15.2.8   553b0cb212c   6e323878db46
    rgw.site1.zone1.ncn-s002.tisuez  ncn-s002  running (41m)  6m ago     41m  15.2.8   registry.local/ceph/ceph:v15.2.8   553b0cb212c   278830a273d3
    rgw.site1.zone1.ncn-s003.nnwuqy  ncn-s003  running (41m)  6m ago     41m  15.2.8   registry.local/ceph/ceph:v15.2.8   553b0cb212c   a9706e6d7a69
    ```

1. Add nodes into HAproxy and KeepAlived. Adjust the command based on the number of storage nodes.

     ```bash
     ncn-s# source /srv/cray/scripts/metal/update_apparmor.sh; reconfigure-apparmor
     ncn-s# pdsh -w ncn-s00[1-(end node number)] -f 2 \
                '/srv/cray/scripts/metal/generate_haproxy_cfg.sh > /etc/haproxy/haproxy.cfg
                systemctl restart haproxy.service
                /srv/cray/scripts/metal/generate_keepalived_conf.sh > /etc/keepalived/keepalived.conf
                systemctl restart keepalived.service'
     ```

## Next Step

Proceed to [Storage Node Validation](../node_management/Rebuild_NCNs/Post_Rebuild_Storage_Node_Validation.md)
