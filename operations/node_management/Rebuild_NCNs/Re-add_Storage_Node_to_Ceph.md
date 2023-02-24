# Re-Add a Storage Node to Ceph

Use the following procedure to re-add a Ceph node to the Ceph cluster.

**`NOTE`** This operation can be done to add more than one node at the same time.

## Run the Ceph Join Script

Watch `ceph -s` and run the `ceph_join_cluster.sh` script.

1. In a separate window, log into one of the first three storage nodes (`ncn-s001`, `ncn-s002`, or `ncn-s003`) and execute the following:

   ```bash
   watch ceph -s
   ```

1. (`ncn-s#`) **On the node being rebuilt**, execute the `ceph_join_cluster.sh` script.

   ```bash
   /srv/cray/scripts/common/join_ceph_cluster.sh
   ```

   **IMPORTANT:** While watching the window running `watch ceph -s`, the health will go to a `HEALTH_WARN` state. This is expected. Most commonly, there will be an alert about "failed to probe daemons or devices" and this will clear.

## Zap OSDs

**IMPORTANT:** Only do this if unable to wipe the node prior to rebuild. For example, when a storage node unintentionally goes down and needs to be rebuilt.

**`NOTE`** The commands in the Zapping OSDs section must be run on a node running `ceph-mon`. Typically these are `ncn-s001`, `ncn-s002`, and `ncn-s003`.

1. Find the devices on the node being rebuilt.

   ```bash
   ceph orch device ls $NODE
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

   **IMPORTANT:** In the above example the drives on our rebuilt node are showing "Available = no". This is expected because the check is based on the presence of an LVM on the volume.

   **`NOTE`** The `ceph orch device ls $NODE` command excludes the drives being used for the OS. Please double check that there are no OS drives. These will have a size of 480G.

2. Zap the drives.

   ```bash
   for drive in $(ceph orch device ls $NODE --format json-pretty |jq -r '.[].devices[].path')
   do
     ceph orch device zap $NODE $drive --force
   done
   ```

3. Validate the drives are being added to the cluster.

   ```bash
   watch ceph -s
   ```

   The returned output will have the OSD count `UP` and `IN` counts increase. **If** the `IN` count increases but does not reflect the amount of drives being added back in, an administrator must fail over the `ceph-mgr` daemon.
   This is a known bug and is addressed in newer releases.

   If necessary, fail over the `ceph-mgr` daemon with the following command:

   ```bash
   ceph mgr fail
   ```

## Regenerate Rados-GW Load Balancer Configuration for the Rebuilt Nodes

**IMPORTANT:** `Rados-GW` by default is deployed to the first 3 storage nodes. This includes `HAproxy` and `Keepalived`.
This is automated as part of the install, but administrators may have to regenerate the configuration if they are not running on the first 3 storage nodes or all nodes.

1. (`ncn-s00[1/2/3]#`) Deploy Rados Gateway containers to the new nodes.

   - Configure Rados Gateway containers with the complete list of nodes it should be running on:

     ```bash
     ceph orch apply rgw site1 zone1 --placement="<node1 node2 node3 node4 ... >" --port=8080
     ```

1. (`ncn-s00[1/2/3]#`) Verify Rados Gateway is running on the desired nodes.

    ```bash
    ceph orch ps --daemon_type rgw
    ```

    Example output:

    ```text
    NAME                       HOST      PORTS   STATUS         REFRESHED  AGE  MEM USE  MEM LIM  VERSION  IMAGE ID      CONTAINER ID
    rgw.site1.ncn-s001.bdprnl  ncn-s001  *:8080  running (22h)     7m ago  22h     348M        -  16.2.9   a3d3e58cb809  45b983e1eb23
    rgw.site1.ncn-s002.lxyvkj  ncn-s002  *:8080  running (17h)     6m ago  17h     379M        -  16.2.9   a3d3e58cb809  a79964888adf
    rgw.site1.ncn-s003.szrtek  ncn-s003  *:8080  running (18h)     6m ago  18h     479M        -  16.2.9   a3d3e58cb809  c800dce8d54f
    ```

1. (`ncn-s00[1/2/3]#`) Add nodes into `HAproxy` and `KeepAlived`.

   Set the end node number to deploy `HAproxy` and `KeepAlived` (example: `end_node_number=5` if deploying on `ncn-s001` through `ncn-s005`).

   ```bash
   end_node_number=n
   ```

   ```bash
   pdsh -w ncn-s00[1-${end_node_number}] -f 2 \
                   'source /srv/cray/scripts/metal/update_apparmor.sh
                    reconfigure-apparmor; /srv/cray/scripts/metal/generate_haproxy_cfg.sh > /etc/haproxy/haproxy.cfg
                    systemctl enable haproxy.service
                    systemctl restart haproxy.service
                    /srv/cray/scripts/metal/generate_keepalived_conf.sh > /etc/keepalived/keepalived.conf
                    systemctl enable keepalived.service
                    systemctl restart keepalived.service'
   ```

## Next Step

If executing this procedure as part of an NCN rebuild, return to the main [Rebuild NCNs](Rebuild_NCNs.md#storage-node) page and proceed with the next step.
