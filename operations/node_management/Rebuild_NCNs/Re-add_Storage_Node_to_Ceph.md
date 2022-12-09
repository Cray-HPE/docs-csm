# Re-Add a Storage Node to Ceph

Use the following procedure to re-add a Ceph node to the Ceph cluster.

**`NOTE`** This operation can be done to add more than one node at the same time.

## Add Join Script

1. Copy and paste the below script into `/srv/cray/scripts/common/join_ceph_cluster.sh`.

   **`NOTE`** This script may also available in the `/usr/share/doc/csm/scripts` directory where the latest ***`docs-csm`*** RPM is installed. If so, it can be copied from that node to the new storage node being rebuilt and skip to step 2.

   ```bash
   #!/bin/bash

   (( counter=0 ))

   host=$(hostname)

   > ~/.ssh/known_hosts

   for node in ncn-s001 ncn-s002 ncn-s003; do
     ssh-keyscan -H "$node" >> ~/.ssh/known_hosts
     pdsh -w $node > ~/.ssh/known_hosts
     if [[ "$host" == "$node" ]]; then
       continue
     fi

     if [[ $(nc -z -w 10 $node 22) ]] || [[ $counter -lt 3 ]]
     then
       if [[ "$host" =~ ^("ncn-s001"|"ncn-s002"|"ncn-s003")$ ]]
       then
         scp $node:/etc/ceph/* /etc/ceph
       else
         scp $node:/etc/ceph/rgw.pem /etc/ceph/rgw.pem
       fi

       if [[ ! $(pdsh -w $node "/srv/cray/scripts/common/pre-load-images.sh; ceph orch host rm $host; ceph cephadm generate-key; ceph cephadm get-pub-key > ~/ceph.pub; ssh-keyscan -H $host >> ~/.ssh/known_hosts ;ssh-copy-id -f -i ~/ceph.pub root@$host; ceph orch host add $host") ]]
       then
         (( counter+1 ))
         if [[ $counter -ge 3 ]]
         then
           echo "Unable to access ceph monitor nodes"
           exit 1
         fi
       else
         break
       fi
     fi
   done

   sleep 30
   (( ceph_mgr_failed_restarts=0 ))
   (( ceph_mgr_successful_restarts=0 ))
   until [[ $(cephadm shell -- ceph-volume inventory --format json-pretty|jq '.[] | select(.available == true) | .path' | wc -l) == 0 ]]
   do
     for node in ncn-s001 ncn-s002 ncn-s003; do
       if [[ $ceph_mgr_successful_restarts > 10 ]]
       then
         echo "Failed to bring in OSDs, manual troubleshooting required."
         exit 1
       fi
       if pdsh -w $node ceph mgr fail
       then
         (( ceph_mgr_successful_restarts+1 ))
         sleep 120
         break
       else
         (( ceph_mgr_failed_restarts+1 ))
         if [[ $ceph_mgr_failed_restarts -ge 3 ]]
         then
           echo "Unable to access ceph monitor nodes."
           exit 1
         fi
       fi
     done
   done

   for service in $(cephadm ls | jq -r '.[].systemd_unit')
   do
     systemctl enable $service
   done
   ```

1. Change the mode of the script.

   ```bash
   chmod u+x /srv/cray/scripts/common/join_ceph_cluster.sh
   ```

1. In a separate window, log into one of the first three storage nodes (`ncn-s001`, `ncn-s002`, or `ncn-s003`) and execute the following:

   ```bash
   watch ceph -s
   ```

1. Execute the script.

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

1. Deploy Rados Gateway containers to the new nodes.

   - Configure Rados Gateway containers with the complete list of nodes it should be running on:

     ```bash
     ceph orch apply rgw site1 zone1 --placement="<node1 node2 node3 node4 ... >"
     ```

1. Verify Rados Gateway is running on the desired nodes.

    ```bash
    ncn-s00(1/2/3)# ceph orch ps --daemon_type rgw
    ```

    Example output:

    ```text
    NAME                             HOST      STATUS         REFRESHED  AGE  VERSION  IMAGE NAME                        IMAGE     D              CONTAINER ID
    rgw.site1.zone1.ncn-s001.kvskqt  ncn-s001  running (41m)  6m ago     41m  15.2.8   registry.local/ceph/ceph:v15.2.8      553b0cb212c          6e323878db46
    rgw.site1.zone1.ncn-s002.tisuez  ncn-s002  running (41m)  6m ago     41m  15.2.8   registry.local/ceph/ceph:v15.2.8      553b0cb212c          278830a273d3
    rgw.site1.zone1.ncn-s003.nnwuqy  ncn-s003  running (41m)  6m ago     41m  15.2.8   registry.local/ceph/ceph:v15.2.8           553b0cb212c      a9706e6d7a69
    ```

1. Add nodes into `HAproxy` and `KeepAlived`.

   ```bash
   pdsh -w ncn-s00[1-(end node number)] -f 2 \
                   'source /srv/cray/scripts/metal/update_apparmor.sh
                    reconfigure-apparmor; /srv/cray/scripts/metal/generate_haproxy_cfg.sh > /etc/haproxy/haproxy.cfg
                    systemctl enable haproxy.service
                    systemctl restart haproxy.service
                    /srv/cray/scripts/metal/generate_keepalived_conf.sh > /etc/keepalived/keepalived.conf
                    systemctl enable keepalived.service
                    systemctl restart keepalived.service'
   ```

## Next Step

Proceed to the next step to perform [Storage Node Validation](Post_Rebuild_Storage_Node_Validation.md). Otherwise, return to the main [Rebuild NCNs](Rebuild_NCNs.md) page.
