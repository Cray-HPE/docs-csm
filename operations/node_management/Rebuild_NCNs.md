# Rebuild NCNs

Rebuild a master, worker, or storage non-compute node (NCN). Use this procedure in the event that a node has a hardware failure, or some other issue with the node has occurred that warrants rebuilding the node.

The following is a high-level overview of the NCN rebuild workflow:
1. [Prepare Node](#prepare_nodes)
    * There is a different procedure for each type of node (worker, master, and storage).
1. [Identify Node and Update Metadata](#identify_node_and_update_metadata)
    * Same procedure for all node types.
1. [Wipe Disks](#wipe_disks)
    * Same for master and worker nodes, but different for storage nodes.
1. [Power Cycle Node](#power_cycle_node)
    * Same procedure for all node types.
1. [Rebuild Storage Node](#rebuild__storage_node)
    * Only needed for storage nodes
1. [Validation](#validation)
    * There is a different procedure for each type of node (worker, master, and storage).

## Prerequisites

The system is fully installed and has transitioned off of the LiveCD.

<a name=set-var></a>
For several of the commands in this section, you will need to have variables set with the name of the node being rebuilt and its xname.

Set NODE to the hostname of the node being rebuilt (e.g. `ncn-w001`, `ncn-w002`, etc).
Set XNAME to the xname of that node.

```bash
ncn# NODE=ncn-w00n
ncn# XNAME=$(ssh $NODE cat /etc/cray/xname)
ncn# echo $XNAME
```

## Procedure

<a name="prepare_nodes"></a>

### 1. Prepare Node

Only follow the steps in the section for the node type that is being rebuilt:

- [Worker node](#prepare-worker-node)
- [Master node](#prepare-master-node)
- [Storage node](#prepare-storage-node)

<a name="prepare-worker-node"></a>

#### 1.1. Prepare Worker Node

Prepare a worker node before rebuilding it.

Skip this section if rebuilding a master or storage node. Unless otherwise noted, these commands can be run on any node in the system.

1. Determine if the worker being rebuilt is running the `cray-cps-cm-pm` pod.

    If the `cray-cps-cm-pm` pod is running, there will be an extra step to redeploy this pod after the node is rebuilt.

    ```bash
    ncn# cray cps deployment list --format json | grep -C1 podname
        "node": "ncn-w002",
        "podname": "cray-cps-cm-pm-j7td7"
      },
    --
        "node": "ncn-w001",
        "podname": "cray-cps-cm-pm-lzbhm"
      },
    --
        "node": "ncn-w003",
        "podname": "NA"
      },
    --
        "node": "ncn-w004",
        "podname": "NA"
      },
    --
        "node": "ncn-w005",
        "podname": "NA"
      }
    ```

    In this case, the `ncn-w001` and `ncn-w002` nodes have the pod.

    A `404 Not Found` error is expected when the Content Projection Service (CPS) is not installed on the system. CPS is part of the COS product so if this worker node is being rebuilt before the COS product has been installed, CPS will not be installed yet.

1. Confirm what the Configuration Framework Service (CFS) configurationStatus is for the desiredConfig before shutting down the node.

    The following command will indicate if a CFS job is currently in progress for this node. This command assumes you have set the variables from [the prerequisites section](#set-var).

    ```bash
    ncn# cray cfs components describe $XNAME --format json
    {
      "configurationStatus": "configured",
      "desiredConfig": "ncn-personalization-full",
      "enabled": true,
      "errorCount": 0,
      "id": "x3000c0s7b0n0",
      "retryPolicy": 3,
    ```

    If the configurationStatus is `pending`, wait for the job finish before rebooting this node. If the configurationStatus is `failed`, this means the failed CFS job configurationStatus preceded this worker rebuild, and that can be addressed independent of rebuilding this worker. If the configurationStatus is `unconfigured` and the NCN personalization procedure has not been done as part of an install yet, this can be ignored.

1. Drain the node to clear any pods running on the node.

    The following command will both cordon and drain the node. If there are messages indicating that the pods cannot be evicted because of a pod distribution budget, note those pod names and manually delete them. This command assumes you have set the variables from [the prerequisites section](#set-var).

    ```bash
    ncn# kubectl drain --ignore-daemonsets --delete-local-data $NODE
    ```

    You may run into pods that cannot be gracefully evicted due to Pod Disruption Budgets (PDB), for example:

    ```
    error when evicting pod "<pod>" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
    ```

    In this case, there are some options. First, if the service is scalable, you can increase the scale to start up another pod on another node, and then the drain will be able to delete it. However, it will probably be necessary to force the deletion of the pod:

    ```bash
    ncn# kubectl delete pod [-n <namespace>] --force --grace-period=0 <pod>
    ```

    This will delete the offending pod, and Kubernetes should schedule a replacement on another node. You can then rerun the `kubectl drain` command, and it should report that the node is drained

1. Remove the node from the cluster after the node is drained.

    This command assumes you have set the variables from [the prerequisites section](#set-var).

    ```bash
    ncn# kubectl delete node $NODE
    ```

<a name="prepare-master-node"></a>

#### 1.2. Prepare Master Node

Prepare a master node before rebuilding it.

Skip this section if rebuilding a worker or storage node. The commands should be run on a master node that is not being rebuilt.

1. Confirm what the Configuration Framework Service (CFS) configurationStatus is for the desiredConfig before shutting down the node.

    The following command will indicate if a CFS job is currently in progress for this node. This command assumes you have set the variables from [the prerequisites section](#set-var).

    ```bash
    ncn-m# cray cfs components describe $XNAME --format json
    {
      "configurationStatus": "configured",
      "desiredConfig": "ncn-personalization-full",
      "enabled": true,
      "errorCount": 0,
      "id": "x3000c0s7b0n0",
      "retryPolicy": 3,
    ```

    If the configurationStatus is `pending`, wait for the job finish before rebooting this node. If the configurationStatus is `failed`, this means the failed CFS job configurationStatus preceded this worker rebuild, and that can be addressed independent of rebuilding this worker. If the configurationStatus is `unconfigured` and the NCN personalization procedure has not been done as part of an install yet, this can be ignored.

1. Determine if the master node being rebuilt is the first master node.

    The first master node is the node others contact to join the Kubernetes cluster. If this is the node being rebuilt, promote another master node to the initial node before proceeding.

    ```bash
    ncn-m# craysys metadata get first-master-hostname
    ncn-m002
    ```

    If the node returned is not the one being rebuilt, proceed to the step which [stops etcd](#stop-etcd) and skip the substeps here.

    1. Reconfigure the Boot Script Service \(BSS\) to point to a new first master node.

        ```bash
        ncn-mw# cray bss bootparameters list --name Global --format=json | jq '.[]' > Global.json
        ```

    1. Edit the Global.json file and edit the indicated line.

        Change the `first-master-hostname` value to another node that will be promoted to the first master node. For example, if the first node is changing from `ncn-m002` to `ncn-m001`, the line would be changed to the following:

        ```bash
        "first-master-hostname": "ncn-m001",
        ```

    1. Get a token to interact with BSS via the REST API.

        ```bash
        ncn# curl -i -s -k -H "Content-Type: application/json" \
                 -H "Authorization: Bearer ${TOKEN}" \
                 "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters" \
                 -X PUT -d @./Global.json
        ```

        Ensure a good response, such as `HTTP CODE 200`, is returned in the `curl` output.

    1. Configure the newly promoted first master node so it is able to have other nodes join the cluster.

        Use `ssh` to login to the newly-promoted master node chosen in the previous steps \(`ncn-m001` in this example\), copy/paste the following script to a file, and then execute it.

        ```bash
        #!/bin/bash

        source /srv/cray/scripts/metal/lib.sh
        export KUBERNETES_VERSION="v$(cat /etc/cray/kubernetes/version)"
        echo $(kubeadm init phase upload-certs --upload-certs 2>&1 | tail -1) > /etc/cray/kubernetes/certificate-key
        export CERTIFICATE_KEY=$(cat /etc/cray/kubernetes/certificate-key)
        export MAX_PODS_PER_NODE=$(craysys metadata get kubernetes-max-pods-per-node)
        export PODS_CIDR=$(craysys metadata get kubernetes-pods-cidr)
        export SERVICES_CIDR=$(craysys metadata get kubernetes-services-cidr)
        envsubst < /srv/cray/resources/common/kubeadm.yaml > /etc/cray/kubernetes/kubeadm.yaml

        kubeadm token create --print-join-command > /etc/cray/kubernetes/join-command 2>/dev/null
        echo "$(cat /etc/cray/kubernetes/join-command) --control-plane --certificate-key $(cat /etc/cray/kubernetes/certificate-key)" > /etc/cray/kubernetes/join-command-control-plane

        mkdir -p /srv/cray/scripts/kubernetes
        cat > /srv/cray/scripts/kubernetes/token-certs-refresh.sh <<'EOF'
        #!/bin/bash

        if [[ "$1" != "skip-upload-certs" ]]; then
            kubeadm init phase upload-certs --upload-certs --config /etc/cray/kubernetes/kubeadm.yaml
        fi
        kubeadm token create --print-join-command > /etc/cray/kubernetes/join-command 2>/dev/null
        echo "$(cat /etc/cray/kubernetes/join-command) --control-plane --certificate-key $(cat /etc/cray/kubernetes/certificate-key)" \
            > /etc/cray/kubernetes/join-command-control-plane

        EOF
        chmod +x /srv/cray/scripts/kubernetes/token-certs-refresh.sh
        /srv/cray/scripts/kubernetes/token-certs-refresh.sh skip-upload-certs
        echo "0 */1 * * * root /srv/cray/scripts/kubernetes/token-certs-refresh.sh >> /var/log/cray/cron.log 2>&1" > /etc/cron.d/cray-k8s-token-certs-refresh
        ```

    1. Determine the member ID of the master node being removed.
    
        Run the following command and find the line with the name of the master being removed. The member ID is the alphanumeric string in the first field of that line. The IP address is in the URL in the fourth field in the line. Note the member ID and IP address for use in subsequent steps.

        ```bash
        ncn# etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt \
                     --cert=/etc/kubernetes/pki/etcd/ca.crt  \
                     --key=/etc/kubernetes/pki/etcd/ca.key \
                     --endpoints=localhost:2379 member list
        ```

    1. Remove the master node from the etcd cluster backing Kubernetes.

        Replace the `<MEMBER_ID>` value with the value returned in the previous sub-step.

        ```bash
        ncn# etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt \
                     --cert=/etc/kubernetes/pki/etcd/ca.crt --key=/etc/kubernetes/pki/etcd/ca.key \
                     --endpoints=localhost:2379 member remove <MEMBER_ID>
        ```
        <a name="stop-etcd"></a>

1. Stop the `etcd` service **on the master node being removed**.

    ```bash
    ncn-m# systemctl stop etcd.service
    ```

1. Remove the node from the Kubernetes cluster. 

    This command should not be run on the node being deleted. This command assumes you have set the variables from [the prerequisites section](#set-var).

    ```bash
    ncn# kubectl delete node $NODE
    ```
   
1. Add the node back into the etcd cluster so when it reboots it can rejoin.

    The IP and hostname of the rebuilt node is needed for the following command. Replace the `<IP_ADDRESS>` address value with the IP address you noted in an earlier step from the `etcdctl` command.
    
    This command assumes you have set the variables from [the prerequisites section](#set-var).

    ```bash
    ncn# etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/ca.crt \
           --key=/etc/kubernetes/pki/etcd/ca.key --endpoints=localhost:2379 member add $NODE \
           --peer-urls=https://<IP_ADDRESS>:2380
    ```

<a name="prepare-storage-node"></a>

#### 1.3. Prepare Storage Node

Prepare a storage node before rebuilding it.

Skip this section if rebuilding a master or worker node.

1. Confirm what the Configuration Framework Service (CFS) configurationStatus is for the desiredConfig before shutting down the node.

    The following command will indicate if a CFS job is currently in progress for this node. This command assumes you have set the variables from [the prerequisites section](#set-var).

    ```bash
    ncn# cray cfs components describe $XNAME --format json
    {
      "configurationStatus": "configured",
      "desiredConfig": "ncn-personalization-full",
      "enabled": true,
      "errorCount": 0,
      "id": "x3000c0s7b0n0",
      "retryPolicy": 3,
    ```

    If the configurationStatus is `pending`, wait for the job finish before rebooting this node. If the configurationStatus is `failed`, this means the failed CFS job configurationStatus preceded this worker rebuild, and that can be addressed independent of rebuilding this worker. If the configurationStatus is `unconfigured` and the NCN personalization procedure has not been done as part of an install yet, this can be ignored.

1. Check the status of Ceph.

    Check the OSD status, weight, and location:

    ```bash
    ncn-s# ceph osd tree
    ID CLASS WEIGHT   TYPE NAME         STATUS REWEIGHT PRI-AFF
    -1       20.95917 root default
    -3        6.98639     host ncn-s001
     2   ssd  1.74660         osd.2         up  1.00000 1.00000
     5   ssd  1.74660         osd.5         up  1.00000 1.00000
     8   ssd  1.74660         osd.8         up  1.00000 1.00000
    11   ssd  1.74660         osd.11        up  1.00000 1.00000
    -7        6.98639     host ncn-s002
     0   ssd  1.74660         osd.0         up  1.00000 1.00000
     4   ssd  1.74660         osd.4         up  1.00000 1.00000
     7   ssd  1.74660         osd.7         up  1.00000 1.00000
    10   ssd  1.74660         osd.10        up  1.00000 1.00000
    -5        6.98639     host ncn-s003
     1   ssd  1.74660         osd.1       down        0 1.00000
     3   ssd  1.74660         osd.3       down        0 1.00000
     6   ssd  1.74660         osd.6       down        0 1.00000
     9   ssd  1.74660         osd.9       down        0 1.00000
    ```

    Check the status of the Ceph cluster:

    ```bash
    ncn-s# ceph -s
      cluster:
        id:     22d01fcd-a75b-4bfc-b286-2ed8645be2b5
        health: HEALTH_WARN
                4 osds down
                1 host (8 osds) down
                Degraded data redundancy: 923/2768 objects degraded (33.345%), 94 pgs degraded
                1/3 mons down, quorum ncn-s001,ncn-s002

      services:
        mon: 3 daemons, quorum ncn-s001,ncn-s002 (age 43s), out of quorum: ncn-s003
        mgr: ncn-s001(active, since 18h), standbys: ncn-s002
        mds: cephfs:1 {0=ncn-s001=up:active} 1 up:standby
        osd: 16 osds: 8 up (since 34s), 12 in (since 34m)
        rgw: 2 daemons active (ncn-s001.rgw0, ncn-s002.rgw0)

      task status:
        scrub status:
            mds.ncn-s001: idle

      data:
        pools:   10 pools, 480 pgs
        objects: 923 objects, 29 KiB
        usage:   12 GiB used, 21 TiB / 21 TiB avail
        pgs:     923/2768 objects degraded (33.345%)
                 369 active+undersized
                 94  active+undersized+degraded
                 17  active+clean
    ```

1. If the node is a ceph-mon node, remove it from the mon map.

    Skip this step if the node is not a ceph-mon node.

    The output in the previous sub-step indicated `out of quorum: ncn-s003`.

    ```bash
    ncn-s# ceph mon dump
    dumped monmap epoch 5
    epoch 5
    fsid 22d01fcd-a75b-4bfc-b286-2ed8645be2b5
    last_changed 2021-03-05 15:14:09.142113
    created 2021-03-04 20:50:38.141908
    min_mon_release 14 (nautilus)
    0: [v2:10.252.1.9:3300/0,v1:10.252.1.9:6789/0] mon.ncn-s001
    1: [v2:10.252.1.10:3300/0,v1:10.252.1.10:6789/0] mon.ncn-s002
    2: [v2:10.252.1.11:3300/0,v1:10.252.1.11:6789/0] mon.ncn-s003
    ```

    Remove the out of quorum node from the mon map. This command assumes you have set the variables from [the prerequisites section](#set-var).

    ```bash
    ncn-s# cd /etc/ansible/ceph-ansible
    ncn-s# ceph mon rm $NODE
    removing mon.ncn-s003 at [v2:10.252.1.11:3300/0,v1:10.252.1.11:6789/0], there will be 2 monitors
    ```

    The Ceph cluster will now show as healthy. However, there will now only be two monitors, which is not an ideal situation because if there is another Ceph mon outage then the cluster will go read-only.

    ```bash
    ncn-s# ceph -s
      cluster:
        id:     22d01fcd-a75b-4bfc-b286-2ed8645be2b5
        health: HEALTH_WARN
                Degraded data redundancy: 588/2771 objects degraded (21.220%), 60 pgs degraded, 268 pgs undersized

      services:
        mon: 2 daemons, quorum ncn-s001,ncn-s002 (age 4m)
        mgr: ncn-s001(active, since 18h), standbys: ncn-s002
        mds: cephfs:1 {0=ncn-s001=up:active} 1 up:standby
        osd: 12 osds: 8 up (since 9m), 8 in (since 42m); 148 remapped pgs
        rgw: 2 daemons active (ncn-s001.rgw0, ncn-s002.rgw0)

      task status:
        scrub status:
            mds.ncn-s001: idle

      data:
        pools:   10 pools, 480 pgs
        objects: 924 objects, 30 KiB
        usage:   8.0 GiB used, 14 TiB / 14 TiB avail
        pgs:     588/2771 objects degraded (21.220%)
                 307/2771 objects misplaced (11.079%)
                 208 active+undersized
                 138 active+clean+remapped
                 74  active+clean
                 60  active+undersized+degraded
    ```

1. Remove Ceph OSDs.

    The `ceph osd tree` capture indicated that there are down OSDs on `ncn-s003`.

    ```
    -5        6.98639     host ncn-s003
     1   ssd  1.74660         osd.1       down        0 1.00000
     3   ssd  1.74660         osd.3       down        0 1.00000
     6   ssd  1.74660         osd.6       down        0 1.00000
     9   ssd  1.74660         osd.9       down        0 1.00000
    ```

    Remove the OSDs to prevent the install from creating new OSDs on the drives, but there is still a reference to them in the crush map. It will time out trying to restart the old OSDs because of that reference.

    This command assumes you have set the variables from [the prerequisites section](#set-var).

    ```bash
    ncn-s# for osd in $(ceph osd ls-tree $NODE); do ceph osd destroy osd.$osd \
        --force; ceph osd purge osd.$osd --force; done
    destroyed osd.1
    purged osd.1
    destroyed osd.3
    purged osd.3
    destroyed osd.6
    purged osd.6
    destroyed osd.9
    purged osd.9
    ```

1. Remove the node from the crush map.

    This command assumes you have set the variables from [the prerequisites section](#set-var).

    ```bash
    ncn-s# ceph osd crush rm $NODE
    ```

<a name="identify_node_and_update_metadata"></a>
#### 2. Identify Nodes and Update Metadata

This section applies to all node types. The commands in this section assume you have set the variables from [the prerequisites section](#set-var).

1. Generate the Boot Script Service \(BSS\) boot parameters JSON file for modification and review.

    ```bash
    ncn# cray bss bootparameters list --name $XNAME --format=json > ${XNAME}.json
    ```

<a name="inspect"></a>
1. Inspect and modify the JSON file.
    1. Remove the outer array brackets.

        Do this by removing the first and last line of the XNAME.json file, indicated with the `[` and `]` brackets.

    1. Remove the leading whitespace on the new first and last lines.

        On the new first and last lines of the file, removing all whitespace characters at the beginning of those lines. The first line should now just be a `{` character and the last line should now just be a `}` character.

    1. Ensure the current boot parameters are appropriate for PXE booting.

        Inspect the `"params": "kernel..."` line. If the line begins with `BOOT_IMAGE` and/or does not contain `metal.server`, the following steps are needed:

        1. Remove everything before `kernel` on the `"params": "kernel"` line.
        1. Re-run steps [Retrieve the xname and Generate BSS JSON](#identify-retrieve) for another node/xname. Look for an example that does not contain `BOOT_IMAGE`.

            Once an example is found, copy a portion of the `params` line for everything including and after `biosdevname`, and use that in the JSON file.

        1. After copying the content after `biosdevname`, change the `"hostname=<hostname>"` to the correct host.

    1. Set the kernel parameters to wipe the disk.

        Locate the portion of the line that contains `"metal.no-wipe"` and ensure it is set to zero `"metal.no-wipe=0"`.

1. Re-apply the boot parameters list for the node using the JSON file.

    1. Get a token to interact with BSS using the REST API.

        ```bash
        ncn# TOKEN=$(curl -s -k -S -d grant_type=client_credentials \
            -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
            -o jsonpath='{.data.client-secret}' | base64 -d` \
            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
            | jq -r '.access_token')
        ```

    1. Do a PUT action for the new JSON file.

        ```bash
        ncn# curl -i -s -k -H "Content-Type: application/json" -H "Authorization: Bearer ${TOKEN}" \
            "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters" -X PUT -d @./${XNAME}.json
        ```

        Ensure a good response \(`HTTP CODE 200`\) is returned in the output.

1. Verify the `bss bootparameters list` command returns the expected information.

    1. Export the list from BSS to a file with a different name.

        ```bash
        ncn# cray bss bootparameters list --name ${XNAME} --format=json > ${XNAME}.check.json
        ```

    1. Compare the new JSON file with what was PUT to BSS.

        ```bash
        ncn# diff ${XNAME}.json ${XNAME}.check.json
        ```

        The only difference between the files should be the square brackets that were removed from the file, and the whitespace changes on the first and last lines with curly braces. Expected output will look similar to:

        ```
        1,2c1
        < [
        <   {
        ---
        > {
        47,48c46
        <   }
        < ]
        ---
        > }
        ```

1. Watch the console for the node being rebuilt.

    Login to a second session to use it to watch the console using the instructions in the following document: [Log in to a Node Using ConMan](../conman/Log_in_to_a_Node_Using_ConMan.md). The first session will be needed to run the commands in the following Rebuild Node steps.

<a name="wipe_disks"></a>

#### 3. Wipe Disks

**Warning:** This is the point of no return. Once the disks are wiped, the node must be rebuilt.

All commands in this section must be run on the node being rebuilt \(unless otherwise indicated\). These commands can be done from the ConMan console window.

Only follow the steps in the section for the node type that is being rebuilt:

- [Wipe Disks: Master or Worker Node](#wipe_disks_master_worker)
- [Wipe Disks: Storage Node](#wipe_disks_storage)

<a name="wipe_disks_master_worker"></a>

##### 3.1. Wipe Disks: Master or Worker

This section applies to master and worker nodes. Skip this section if rebuilding a storage node. 

```bash
ncn-mw# mdisks=$(lsblk -l -o SIZE,NAME,TYPE,TRAN | grep -E '(sata|nvme|sas)' | sort -h | awk '{print "/dev/" $2}')
ncn-mw# wipefs --all --force $mdisks
```

<a name="wipe_disks_storage"></a>

##### 3.2. Wipe Disks: Storage

This section applies to storage nodes. Skip this section if rebuilding a master or worker node. 

1. Delete CEPH Volumes

    ```bash
    ncn-s# systemctl stop ceph-osd.target
    ```

1. Make sure the OSDs (if any) are not running after running the first command.

    ```bash
    ncn-s# ls -1 /dev/sd* /dev/disk/by-label/*
    ncn-s# vgremove -f --select 'vg_name=~ceph*'
    ```

1. Wipe the disks and RAIDs.

    ```bash
    ncn# wipefs --all --force /dev/sd* /dev/disk/by-label/*
    ```

<a name="power_cycle_node"></a>

#### 4. Power Cycle Node

This section applies to all node types. The commands in this section assume you have set the variables from [the prerequisites section](#set-var).

1. Set the PXE boot option and power cycle the node. Run these commands from a node not being rebuilt.

    1. Set the BMC variable to the hostname of the BMC of the node being rebuilt.
    
        This command assumes you have set the variables from [the prerequisites section](#set-var).

        ```bash
        ncn# BMC=${NODE}-mgmt
        ```

    1. Export the root password of the BMC.

        ```bash
        ncn# export IPMI_PASSWORD=changeme
        ```

    1. Set the PXE/efiboot option.

        ```bash
        ncn# ipmitool -I lanplus -U root -E -H $BMC chassis bootdev pxe options=efiboot
        ```

    1. Power off the node.

        ```bash
        ncn# ipmitool -I lanplus -U root -E -H $BMC chassis power off
        ```

    1. Verify that the node is off.

        ```bash
        ncn# ipmitool -I lanplus -U root -E -H $BMC chassis power status
        ```

        Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing the next command.

    1. Power on the node.

        ```bash
        ncn# ipmitool -I lanplus -U root -E -H $BMC chassis power on
        ```

    1. Verify that the node is on.

        Ensure the power is reporting as on. This may take 5-10 seconds for this to update.

        ```bash
        ncn# ipmitool -I lanplus -U root -E -H $BMC chassis power status
        ```

1. Observe the boot.

    After a bit, the node should begin to boot. This can be viewed from the ConMan console window. Eventually, there will be a `NBP file...` message in the console output which indicates that the PXE boot has begun the TFTP download of the ipxe program. Later messages will appear as the Linux kernel loads and then the scripts in the initrd begin to run, including `cloud-init`.

    Wait until `cloud-init` displays messages similar to these on the console to indicate that cloud-init has finished with the module called `modules:final`.

    ```
    [  295.466827] cloud-init[9333]: Cloud-init v. 20.2-8.45.1 running 'modules:final' at Thu, 26 Aug 2021 15:23:20 +0000. Up 125.72 seconds.
    [  295.467037] cloud-init[9333]: Cloud-init v. 20.2-8.45.1 finished at Thu, 26 Aug 2021 15:26:12 +0000. Datasource DataSourceNoCloudNet [seed=cmdline,http://10.92.100.81:8888/][dsmode=net].  Up 295.46 seconds
    ```

    Then press enter on the console to ensure that the the login prompt is displayed including the correct hostname of this node. Then exit the ConMan console (**&** then **.**), and then use `ssh` to log in to the node to complete the remaining validation steps.

    **Troubleshooting:** If the `NBP file...` output never appears, or something else goes wrong, go back to the steps for modifying XNAME.json file (see the step to [inspect and modify the JSON file](#inspect)) and make sure these instructions were completed correctly.

    **Master nodes only:** If `cloud-init` did not complete the newly-rebuilt node will need to have its etcd service definition manually updated. Reconfigure the etcd service, and restart the cloud init on the newly rebuilt master:

    ```bash
    ncn-m# systemctl stop etcd.service; sed -i 's/new/existing/' \
           /etc/systemd/system/etcd.service /srv/cray/resources/common/etcd/etcd.service; \
           systemctl daemon-reload ; rm -rf /var/lib/etcd/member; \
           systemctl start etcd.service; /srv/cray/scripts/common/kubernetes-cloudinit.sh
    ```

1. Confirm `vlan004` is up with the correct IP address on the rebuilt node.

    Run these commands on the rebuilt node.

    1. Find the desired IP address.

        This command assumes you have set the variables from [the prerequisites section](#set-var).

        ```bash
        ncn# dig +short ${NODE}.hmn
        10.254.1.16
        ```

    1. Confirm the output from the dig command matches the interface.

        If the IP addresses match, proceed to the next step. If they do not match, continue with the following sub-steps.

        ```bash
        ncn# ip addr show vlan004
        14: vlan004@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
            link/ether b8:59:9f:2b:2f:9e brd ff:ff:ff:ff:ff:ff
            inet 10.254.1.16/17 brd 10.254.127.255 scope global vlan004
               valid_lft forever preferred_lft forever
            inet6 fe80::ba59:9fff:fe2b:2f9e/64 scope link
               valid_lft forever preferred_lft forever
        ```

        1. Change the IP address for `vlan004` if necessary.

            ```bash
            ncn# vim /etc/sysconfig/network/ifcfg-vlan004
            ```

            Set the `IPADDR` line to the correct IP address with a `/17` mask. For example, if the correct IP address is `10.254.1.16`, the line should be:

            ```
            IPADDR='10.254.1.16/17'
            ```

        1. Restart the `vlan004` network interface.

            ```bash
            ncn# wicked ifreload vlan004
            ```

        1. Confirm the output from the dig command matches the interface.

            ```bash
            ncn# ip addr show vlan004
            ```

1. Confirm that `vlan007` is up with the correct IP address on the rebuilt node.

    Run these commands on the rebuilt node.

    1. Find the desired IP address.
    
        This command assumes you have set the variables from [the prerequisites section](#set-var).

        ```bash
        ncn# dig +short ${NODE}.can
        10.103.8.11
        ```

    1. Confirm the output from the dig command matches the interface.

        If the IP addresses match, proceed to the next step. If they do not match, continue with the following sub-steps.

        ```bash
        ncn# ip addr show vlan007
        15: vlan007@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
            link/ether b8:59:9f:2b:2f:9e brd ff:ff:ff:ff:ff:ff
            inet 10.103.8.11/24 brd 10.103.8.255 scope global vlan007
               valid_lft forever preferred_lft forever
            inet6 fe80::ba59:9fff:fe2b:2f9e/64 scope link
               valid_lft forever preferred_lft forever
        ```

        1. Change the IP address for `vlan007` if necessary.

            ```bash
            ncn# vim /etc/sysconfig/network/ifcfg-vlan007
            ```

            Set the `IPADDR` line to the correct IP address with a `/24` mask. For example, if the correct IP address is `10.103.8.11`, the line should be:

            ```
            IPADDR='10.103.8.11/24'
            ```

        1. Restart the `vlan007` network interface.

            ```bash
            ncn# wicked ifreload vlan007
            ```

        1. Confirm the output from the dig command matches the interface.

            ```bash
            ncn# ip addr show vlan007
            ```

1. Set the wipe flag back so it will not wipe the disk when the node is rebooted.

    1. Edit the XNAME.json file and set the `metal.no-wipe=1` value.

    1. Do a PUT action for the edited JSON file.
    
        This command can be run from any node. This command assumes you have set the variables from [the prerequisites section](#set-var).

        ```bash
        ncn# curl -i -s -k -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${TOKEN}" \
            "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters" \
            -X PUT -d @./${XNAME}.json
        ```

    The output from the `ncnHealthChecks.sh` script \(run later in the "Validation" steps\) can be used to verify the `metal.no-wipe` value on every NCN.

<a name="rebuild_storage_node"></a>

#### 5. Rebuild Storage Node

This section applies to storage nodes. Skip this section if rebuilding a master or worker node. All commands in this section must be run on any storage node that is already in the cluster and is not being rebuilt \(unless otherwise indicated\).

1. Use `ssh` to log in to the node where Ansible will run.

    * If rebuilding `ncn-s001`, log in to either `ncn-s002` or `ncn-s003`.

    * If rebuilding any other storage node, log in to `ncn-s001` and proceed to the next step.

1. Update the Ansible inventory.

    1. Update the number of the last storage node.

        There will be no output returned from the following commands. This step changes LASTNODE into the number of the last storage node. In this example, LASTNODE is changed to `ncn-s003`.

        ```bash
        ncn-s# source /srv/cray/scripts/common/fix_ansible_inv.sh
        ncn-s# fix_inventory
        ```

    1. Verify the Ansible inventory was changed.

        Verify that LASTNODE no longer exists in the inventory file \(`/etc/ansible/hosts`\).

        ```
        [all]
        ncn-s[001:LASTNODE].nmn

        [ceph_all]
        ncn-s[001:LASTNODE].nmn
        ```

        to:

        ```
        [all]
        ncn-s[001:003].nmn

        [ceph_all]
        ncn-s[001:003].nmn
        ```

1. Set the environment variable for the rados gateway vip.

    ```bash
    ncn-s# cd /etc/ansible/group_vars
    ncn-s# export RGW_VIRTUAL_IP=$(craysys metadata get rgw-virtual-ip)
    ncn-s# echo $RGW_VIRTUAL_IP
    10.252.1.3
    ```

1. Run the ceph-ansible playbook to reinstall the node and bring it back into the cluster.

    Run the following commands on the storage node being rebuilt.

    ```bash
    ncn-s# cd /etc/ansible/ceph-ansible
    ncn-s# ansible-playbook /etc/ansible/ceph-ansible/site.yml
    ```

1. Open another SSH session to a storage node that is not currently being rebuilt, and then monitor the build.

    ```bash
    ncn-s# watch ceph -s
    ```

1. Run the radosgw-sts-setup.yml Ansible play on the storage node being rebuilt.

    Ensure Ceph is healthy and the ceph-ansible playbook has finished before running the following Ansible play on the storage node being rebuilt.

    ```bash
    ncn-s# ansible-playbook /etc/ansible/ceph-rgw-users/radosgw-sts-setup.yml
    ```

    On the node that has been rebuilt, verify the sts values are in the ceph.conf file.

    ```bash
    ncn-s# grep sts /etc/ceph/ceph.conf
    rgw_s3_auth_use_sts = True
    rgw_sts_key = <REDACTED_KEY>
    ```

#### 6. Validation

As a result of rebuilding any NCN(s) remove any dynamically assigned interface IPs that did not get released automatically by running the CASMINST-2015 script:

```bash
ncn-m001# /usr/share/doc/csm/scripts/CASMINST-2015.sh
```

Once that is done only follow the steps in the section for the node type that was rebuilt:

- [Validate Worker Node](#validate_worker_node)
- [Validate Master Node](#validate_master_node)
- [Validate Storage Node](#validate_storage_node)

<a name="validate_worker_node"></a>

##### 6.1. Validate Worker Node

Validate the worker node rebuilt successfully.

Skip this section if a master or storage node was rebuilt.

1. Verify the new node is in the cluster.

      Run the following command from any master or worker node that is already in the cluster. It is helpful to run this command several times to watch for the newly rebuilt node to join the cluster. This should occur within 10 to 20 minutes.

      ```bash
      ncn-mw# kubectl get nodes
      NAME       STATUS   ROLES    AGE    VERSION
      ncn-m001   Ready    master   113m   v1.18.6
      ncn-m002   Ready    master   113m   v1.18.6
      ncn-m003   Ready    master   112m   v1.18.6
      ncn-w001   Ready    <none>   112m   v1.18.6
      ncn-w002   Ready    <none>   112m   v1.18.6
      ncn-w003   Ready    <none>   112m   v1.18.6
      ```

1. Ensure there is proper routing set up for liquid-cooled hardware.

1. Confirm /var/lib/containerd is on overlay on the node which was rebooted.

    Run the following command on the rebuilt node.

    ```bash
    ncn-w# df -h /var/lib/containerd
    Filesystem            Size  Used Avail Use% Mounted on
    containerd_overlayfs  378G  245G  133G  65% /var/lib/containerd
    ```

    After several minutes of the node joining the cluster, pods should be in a `Running` state for the worker node.

1. Confirm the pods are beginning to get scheduled and reach a `Running` state on the worker node. 

    Run this command on any master or worker node. This command assumes you have set the variables from [the prerequisites section](#set-var).

    ```bash
    ncn# kubectl get po -A -o wide | grep $NODE
    ```

1. Confirm BGP is healthy.

    Follow the steps in the [Check BGP Status and Reset Sessions](../network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md) to verify and fix BGP if needed.

1. Confirm what the Configuration Framework Service (CFS) configurationStatus is for the desiredConfig after rebooting the node.

    The following command will indicate if a CFS job is currently in progress for this node. This command assumes you have set the variables from [the prerequisites section](#set-var).

    ```bash
    ncn# cray cfs components describe $XNAME --format json
    {
      "configurationStatus": "configured",
      "desiredConfig": "ncn-personalization-full",
      "enabled": true,
      "errorCount": 0,
      "id": "x3000c0s7b0n0",
      "retryPolicy": 3,
    ```

    If the configurationStatus is `pending`, wait for the job to finish before continuing. If the configurationStatus is `failed`, this means the failed CFS job configurationStatus should be addressed now for this node. If the configurationStatus is `unconfigured` and the NCN personalization procedure has not been done as part of an install yet, this can be ignored.
    If configurationStatus is `failed`, See [Troubleshoot Ansible Play Failures in CFS Sessions](../configuration_management/Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md) for how to analyze the pod logs from `cray-cfs` to determine why the configuration may not have completed.

1. Redeploy the `cray-cps-cm-pm` pod.

    This step is only required if the `cray-cps-cm-pm` pod was running on the node before it was rebuilt.
    > The Content Projection Service (CPS) is part of the COS product so if this worker node is being rebuilt before the COS product has been installed, CPS will not be installed yet.
    This command can be run from any node.

    ```bash
    ncn# cray cps deployment update --nodes "ncn-w001,ncn-w002"
    ```

1. Collect data about the system management platform health \(can be run from a master or worker NCN\).

    ```bash
    ncn-mw# /opt/cray/platform-utils/ncnHealthChecks.sh
    ncn-mw# /opt/cray/platform-utils/ncnPostgresHealthChecks.sh
    ```

<a name="validate_master_node"></a>

##### 6.2. Validate Master Node

Validate the master node rebuilt successfully.

Skip this section if a worker or storage node was rebuilt. 

1. Verify the new node is in the cluster.

    Run the following command from any master or worker node that is already in the cluster. It is helpful to run this command several times to watch for the newly rebuilt node to join the cluster. This should occur within 10 to 20 minutes.

    ```bash
    ncn-mw# kubectl get nodes
    NAME       STATUS   ROLES    AGE    VERSION
    ncn-m001   Ready    master   113m   v1.18.6
    ncn-m002   Ready    master   113m   v1.18.6
    ncn-m003   Ready    master   112m   v1.18.6
    ncn-w001   Ready    <none>   112m   v1.18.6
    ncn-w002   Ready    <none>   112m   v1.18.6
    ncn-w003   Ready    <none>   112m   v1.18.6
    ```

1. Ensure there is proper routing set up for liquid-cooled hardware.

1. Confirm the `sdc` disk has the correct lvm on the rebuilt node.

    ```bash
    ncn-m# lsblk | grep -A2 ^sdc
    sdc                   8:32   0 447.1G  0 disk
     └─ETCDLVM           254:0    0 447.1G  0 crypt
       └─etcdvg0-ETCDK8S 254:1    0    32G  0 lvm   /run/lib-etcd
    ```

1. Confirm `etcd` is running and shows the node as a member once again.

    The newly built master node should be in the returned list.

    ```bash
    ncn-m# etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/ca.crt \
                   --key=/etc/kubernetes/pki/etcd/ca.key --endpoints=localhost:2379 member list
    ```

1. Confirm what the Configuration Framework Service (CFS) configurationStatus is for the desiredConfig after rebooting the node.

    The following command will indicate if a CFS job is currently in progress for this node. This command assumes you have set the variables from [the prerequisites section](#set-var).

    ```bash
    ncn# cray cfs components describe $XNAME --format json
    {
      "configurationStatus": "configured",
      "desiredConfig": "ncn-personalization-full",
      "enabled": true,
      "errorCount": 0,
      "id": "x3000c0s7b0n0",
      "retryPolicy": 3,
    ```

    If the configurationStatus is `pending`, wait for the job to finish before continuing. If the configurationStatus is `failed`, this means the failed CFS job configurationStatus should be addressed now for this node. If the configurationStatus is `unconfigured` and the NCN personalization procedure has not been done as part of an install yet, this can be ignored.
    If configurationStatus is `failed`, See [Troubleshoot Ansible Play Failures in CFS Sessions](../configuration_management/Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md) for how to analyze the pod logs from `cray-cfs` to determine why the configuration may not have completed.

1. Collect data about the system management platform health \(can be run from a master or worker NCN\).

    ```bash
    ncn-mw# /opt/cray/platform-utils/ncnHealthChecks.sh
    ncn-mw# /opt/cray/platform-utils/ncnPostgresHealthChecks.sh
    ```

<a name="validate_storage_node"></a>

##### 6.3. Validate Storage Node

Validate the storage node rebuilt successfully.

Skip this section if a master or worker node was rebuilt.

1. Verify there are 3 mons, 3 mds, 3 mgr processes, and rgw.s

    ```bash
    ncn-m# ceph -s
      cluster:
        id:     22d01fcd-a75b-4bfc-b286-2ed8645be2b5
        health: HEALTH_OK

      services:
        mon: 3 daemons, quorum ncn-s001,ncn-s002,ncn-s003 (age 4m)
        mgr: ncn-s001(active, since 19h), standbys: ncn-s002, ncn-s003
        mds: cephfs:1 {0=ncn-s001=up:active} 2 up:standby
        osd: 12 osds: 12 up (since 2m), 12 in (since 2m)
        rgw: 3 daemons active (ncn-s001.rgw0, ncn-s002.rgw0, ncn-s003.rgw0)

      task status:
        scrub status:
            mds.ncn-s001: idle

      data:
        pools:   10 pools, 480 pgs
        objects: 926 objects, 31 KiB
        usage:   12 GiB used, 21 TiB / 21 TiB avail
        pgs:     480 active+clean
    ```

1. Verify the OSDs are back in the cluster.

    ```bash
    ncn-m# ceph osd tree
    ID CLASS WEIGHT   TYPE NAME         STATUS REWEIGHT PRI-AFF
    -1       20.95917 root default
    -3        6.98639     host ncn-s001
     2   ssd  1.74660         osd.2         up  1.00000 1.00000
     5   ssd  1.74660         osd.5         up  1.00000 1.00000
     8   ssd  1.74660         osd.8         up  1.00000 1.00000
    11   ssd  1.74660         osd.11        up  1.00000 1.00000
    -7        6.98639     host ncn-s002
     0   ssd  1.74660         osd.0         up  1.00000 1.00000
     4   ssd  1.74660         osd.4         up  1.00000 1.00000
     7   ssd  1.74660         osd.7         up  1.00000 1.00000
    10   ssd  1.74660         osd.10        up  1.00000 1.00000
    -5        6.98639     host ncn-s003
     1   ssd  1.74660         osd.1         up  1.00000 1.00000
     3   ssd  1.74660         osd.3         up  1.00000 1.00000
     6   ssd  1.74660         osd.6         up  1.00000 1.00000
     9   ssd  1.74660         osd.9         up  1.00000 1.00000
    ```

1. Verify the radosgw and haproxy are correct.

    There will be an output \(without an error\) returned if radosgw and haproxy are correct.

    ```bash
    ncn# curl -k https://rgw-vip.nmn
    <?xml version="1.0" encoding="UTF-8"?><ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/ "><Owner><ID>anonymous</ID><DisplayName></DisplayName></Owner><Buckets></Buckets></ListAllMyBucketsResult
    ```


1. Confirm what the Configuration Framework Service (CFS) configurationStatus is for the desiredConfig after rebooting the node.

    The following command will indicate if a CFS job is currently in progress for this node. This command assumes you have set the variables from [the prerequisites section](#set-var).

    ```bash
    ncn# cray cfs components describe $XNAME --format json
    {
      "configurationStatus": "configured",
      "desiredConfig": "ncn-personalization-full",
      "enabled": true,
      "errorCount": 0,
      "id": "x3000c0s7b0n0",
      "retryPolicy": 3,
    ```

    If the configurationStatus is `pending`, wait for the job to finish before continuing. If the configurationStatus is `failed`, this means the failed CFS job configurationStatus should be addressed now for this node. If the configurationStatus is `unconfigured` and the NCN personalization procedure has not been done as part of an install yet, this can be ignored.
    If configurationStatus is `failed`, See [Troubleshoot Ansible Play Failures in CFS Sessions](../configuration_management/Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md) for how to analyze the pod logs from `cray-cfs` to determine why the configuration may not have completed.

1. Collect data about the system management platform health \(can be run from a master or worker NCN\).

    ```bash
    ncn-mw# /opt/cray/platform-utils/ncnHealthChecks.sh
    ncn-mw# /opt/cray/platform-utils/ncnPostgresHealthChecks.sh
    ```
