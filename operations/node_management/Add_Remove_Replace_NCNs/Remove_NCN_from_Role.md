# Remove Roles

## Description

Remove master, worker or storage NCN from current roles. Select the procedure below based on the node type, then complete the remaining steps to wipe the drives and power off the node.

## Procedure

**IMPORTANT:** The following procedures assume you have set the variables from [the prerequisites section](../Add_Remove_Replace.md#remove-prerequisites)

- [Remove Role](#remove-roles)
  - [Master node](#master-node-remove-roles)
  - [Worker node](#worker-node-remove-roles)
  - [Storage node](#storage-node-remove-roles)
- [Wipe the drives](#wipe-the-drives)
  - [Master node](#wipe-disks-master-node)
  - [Worker node](#wipe-disks-worker-node)
  - [Storage node](#wipe-disks-utility-storage-node)
- [Power off the node](#power-off-the-node)


<a name="remove-roles"></a>
## Remove Roles

<a name="master-node-remove-roles"></a>
### Master Node Remove Roles

#### Step 1 - Determine if the master node being removed is the first master node.

***IMPORTANT:*** The first master node is the node others contact to join the Kubernetes cluster. If this is the node being removed, promote another master node to the initial node before proceeding.

1. Fetch the defined first-master-hostname

   ```bash
   ncn-m# cray bss bootparameters list --hosts Global --format json |jq -r '.[]."cloud-init"."meta-data"."first-master-hostname"'
   ```

   Example Output:

   ```screen
   ncn-m002
   ```
  
    * If the node returned is not the one being removed, proceed to the step which [removes the node from the Kubenertes cluster](#remove-the-node-from-the-kubernetes-cluster) and skip the substeps here.

1. Reconfigure the Boot Script Service \(BSS\) to point to a new first master node.

    On any master or worker node:

    ```bash
    cray bss bootparameters list --name Global --format=json | jq '.[]' > Global.json
    ```

1. Edit the Global.json file and edit the indicated line.

    Change the `first-master-hostname` value to another node that will be promoted to the first master node. For example, if the first node is changing from `ncn-m002` to `ncn-m001`, the line would be changed to the following:

   ```text
   "first-master-hostname": "ncn-m001",
   ```

1. Get a token to interact with BSS using the REST API.

   ```bash
   ncn# TOKEN=$(curl -s -S -d grant_type=client_credentials \
        -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
        -o jsonpath='{.data.client-secret}' | base64 -d` \
        https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
        | jq -r '.access_token')
   ```

1. Do a PUT action for the new JSON file.

   ```bash
   ncn# curl -i -s -H "Content-Type: application/json" -H "Authorization: Bearer ${TOKEN}" \
   "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters" -X PUT -d @./Global.json
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

<a name="reset-kubernetes-on-master"></a>
#### Step 2 - Reset Kubernetes on master node being removed.

  ```bash
  kubeadm reset --force
  ```
<a name="stop-running-containers-on-master"></a>
#### Step 3 - Stop running containers on master node being removed.
 
1. List any containers running in `containerd`.

   ```bash
   crictl ps
   ```

   Example Output:

   ```screen
   CONTAINER           IMAGE               CREATED              STATE               NAME                                                ATTEMPT             POD ID
   66a78adf6b4c2       18b6035f5a9ce       About a minute ago   Running             spire-bundle                                        1212                6d89f7dee8ab6
   7680e4050386d       c8344c866fa55       24 hours ago         Running             speaker                                             0                   5460d2bffb4d7
   b6467c907f063       8e6730a2b718c       3 days ago           Running             request-ncn-join-token                              0                   a3a9ca9e1ca78
   e8ce2d1a8379f       64d4c06dc3fb4       3 days ago           Running             istio-proxy                                         0                   6d89f7dee8ab6
   c3d4811fc3cd0       0215a709bdd9b       3 days ago           Running             weave-npc                                    0                   f5e25c12e617e
   ```

1. If there are any running containers from the output of the `crictl ps` command, stop them.

   ```bash
   crictl stop <container id from the CONTAINER column>
   ```

<a name="remove-the-master-node-from-the-kubernetes-cluster"></a>
#### Step 4 - Remove the master node from the Kubernetes cluster.

**IMPORTANT:** Run this command from a node ***NOT*** being deleted.

  ```bash
  ncn-mw# kubectl delete node $NODE
  ```

#### Step 5 - Remove the Node from Etcd.

1. Determine the member ID of the master node being removed.

    * Run the following command and find the line with the name of the master being removed. Note the member ID and IP address for use in subsequent steps.
      * The ***member ID*** is the alphanumeric string in the first field of that line.
      * The ***IP address*** is in the URL in the fourth field in the line.

    On any master node:

    ```bash
    ncn-m# etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt  --cert=/etc/kubernetes/pki/etcd/ca.crt --key=/etc/kubernetes/pki/etcd/ca.key --endpoints=localhost:2379 member list
    ```

1. Remove the master node from the etcd cluster backing Kubernetes.

    Replace the `<MEMBER_ID>` value with the value returned in the previous sub-step.

    ```bash
    ncn-m# etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/ca.crt --key=/etc/kubernetes/pki/etcd/ca.key --endpoints=localhost:2379 member remove <MEMBER_ID>
    ```

#### Step 6 - Stop kubelet, containerd and Etcd services ***on the master node being removed***.

  ```bash
  systemctl stop kubelet.service
  systemctl stop containerd.service
  systemctl stop etcd.service
  ```

#### Step 7 - Add the node back into the etcd cluster

  This will allow the node to rejoin the cluster automatically when it gets added back.

  * The IP and hostname of the rebuilt node is needed for the following command.
  * Replace the `<IP_ADDRESS>` address value with the IP address you noted in an earlier step from the `etcdctl` command.

  ```bash
  etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/ca.crt --key=/etc/kubernetes/pki/etcd/ca.key --endpoints=localhost:2379 member add $NODE --peer-urls=https://<IP_ADDRESS>:2380
  ```

#### Step 8 - Remove Etcd data directory ***on the master node being removed***.

  ```bash
  rm -rf /var/lib/etcd/*
  ```

#### Step 9 - Save a copy the lan0 config from m001 **only if ncn-m001 is being removed**

  ```bash
  ncn-m001# rsync /etc/sysconfig/network/ifcfg-lan0 ncn-m002:/tmp/ifcfg-lan0-m001
  ```

  The master node role removal is complete; proceed to [wipe the drives](#wipe-disks-master-node).

<a name="worker-node-remove-roles"></a>
### Worker Node Remove Roles

#### Step 1 - Drain the node to clear any pods running on the node.

**IMPORTANT:** The following command will cordon and drain the node.

Run the following:

  ```bash
  ncn-mw# kubectl drain --ignore-daemonsets --delete-local-data $NODE
  ```

* You may run into pods that cannot be gracefully evicted due to Pod Disruption Budgets (PDB), for example:

    ```screen
      error when evicting pod "<pod>" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
    ```

* In this case, there are some options. First, if the service is scalable, you can increase the scale to start up another pod on another node, and then the drain will be able to delete it. However, it will probably be necessary to force the deletion of the pod:

    ```bash
    ncn-mw# kubectl delete pod [-n <namespace>] --force --grace-period=0 <pod>
    ```

* This will delete the offending pod, and Kubernetes should schedule a replacement on another node. You can then rerun the `kubectl drain` command, and it should report that the node is drained

<a name="reset-kubernetes-on-worker"></a>
#### Step 2 - Reset Kubernetes on worker node being removed.

  ```bash
  kubeadm reset --force
  ```
<a name="stop-running-containers-on-worker"></a>
#### Step 3 - Stop running containers on worker node being removed.
 
1. List any containers running in `containerd`.

   ```bash
   crictl ps
   ```

   Example Output:

   ```screen
   CONTAINER           IMAGE               CREATED              STATE               NAME                                                ATTEMPT             POD ID
   66a78adf6b4c2       18b6035f5a9ce       About a minute ago   Running             spire-bundle                                        1212                6d89f7dee8ab6
   7680e4050386d       c8344c866fa55       24 hours ago         Running             speaker                                             0                   5460d2bffb4d7
   b6467c907f063       8e6730a2b718c       3 days ago           Running             request-ncn-join-token                              0                   a3a9ca9e1ca78
   e8ce2d1a8379f       64d4c06dc3fb4       3 days ago           Running             istio-proxy                                         0                   6d89f7dee8ab6
   c3d4811fc3cd0       0215a709bdd9b       3 days ago           Running             weave-npc                                    0                   f5e25c12e617e
   ```

1. If there are any running containers from the output of the `crictl ps` command, stop them.

   ```bash
   crictl stop <container id from the CONTAINER column>
   ```

<a name="remove-the-worker-node-from-the-kubernetes-cluster"></a>
#### Step 4 - Remove the worker node from the Kubernetes cluster after the node is drained.

  ```bash
  ncn-mw# kubectl delete node $NODE
  ```
#### Step 5 - Ensure all pods are stopped.

  ```bash
  ncn-mw# kubectl get pods -A -o wide | grep $NODE
  ```

  If no pods are returned, proceed to the next step, otherwise wait for any remaining pods to Terminate.

#### Step 6 - Ensure there are no mapped rbd devices ***on the worker node being removed***.

  ```bash
  rbd showmapped
  ```

  If no devices are returned, then the worker node role removal is complete; proceed to [wipe the drives](#wipe-disks-worker-node). If mapped devices still exist, re-check Step 3, then Step 4 again. If devices are still mapped, they can be forceability unmapped using `rbd unmap -o force /dev/rbd#`, where /dev/rbd# is the device that is still returned as mapped.

<a name="storage-node-remove-roles"></a>
### Storage Node Remove Roles

Open a new tab and follow [Remove Ceph Node](../../utility_storage/Remove_Ceph_Node.md) to remove Ceph role from the storage node.

Once the storage node role removal is complete; proceed to [wipe the drives](#wipe-disks-utility-storage-node).

<a name="wipe-the-drives"></a>
## Wipe the Drives

<a name="wipe-disks-master-node"></a>
### Wipe Disks: Master Node

**NOTE:** etcd should already be stopped as part of the "Remove NCN from Role" steps.

All commands in this section must be run **on the node being removed** \(unless otherwise indicated\). These commands can be done from the ConMan console window.

1. Unmount etcd and `SDU` and remove the volume group

   ```bash
   umount -v /run/lib-etcd /var/lib/etcd /var/lib/sdu
   vgremove -f -v --select 'vg_name=~metal*'
   ```

1. Wipe the drives

   ```bash
   mdisks=$(lsblk -l -o SIZE,NAME,TYPE,TRAN | grep -E '(sata|nvme|sas)' | sort -h | awk '   {print "/dev/" $2}')
   wipefs --all --force $mdisks
   ```

<a name="wipe-disks-worker-node"></a>
### Wipe Disks: Worker Node

All commands in this section must be run **on the node being removed** \(unless otherwise indicated\). These commands can be done from the ConMan console window.

1. Stop contianerd and wipe drives.

    ```bash
    systemctl stop containerd.service
    ```

1. Unmount partitions and remove the volume group.

    ```bash
    umount /var/lib/kubelet /run/lib-containerd /run/containerd /var/lib/sdu
    vgremove -f -v --select 'vg_name=~metal*'
    ```

1. Wipe Drives

    ```bash
    wipefs --all --force /dev/disk/by-label/*
    wipefs --all --force /dev/sd*
    ```

<a name="wipe-disks-utility-storage-node"></a>
### Wipe Disks: Utility Storage Node

All commands in this section must be run **on the node being removed** \(unless otherwise indicated\). These commands can be done from the ConMan console window.

1. Make sure the OSDs (if any) are not running.

    ```bash
    podman ps
    ```

    Examine the output. There should be no running ceph processes or containers.

2. Remove the Volume Groups.

    ```bash
    ls -1 /dev/sd* /dev/disk/by-label/*
    vgremove -f --select 'vg_name=~ceph*'
    ```

3. Unmount and remove the metalvg0 volume group

   ```bash
   umount /etc/ceph
   umount /var/lib/ceph
   umount /var/lib/containers
   vgremove -f metalvg0
   ```

4. Wipe the disks and RAIDs.

    ```bash
    wipefs --all --force /dev/disk/by-label/*
    wipefs --all --force /dev/sd*
    ```

Once the wipe of the drives is complete; proceed to [power off the node](#power-off-the-node).

<a name="power-off-the-node"></a>
## Power Off the Node

**IMPORTANT:** Run these commands from a node ***NOT*** being powered off.

1. Set the BMC variable to the hostname of the BMC of the node being powered off.

   ```bash
   BMC=${NODE}-mgmt
   ```

   1. **For ncn-m001 only** : Collect and record the BMC IP for ncn-m001 and the CAN IP for m002 before the node is powered off. These may be needed later.

      ```bash
      ncn-m001# BMC_IP=$(ipmitool lan print | grep 'IP Address' | grep -v 'Source'  | awk -F ": " '{print $2}')
      ncn-m001# echo $BMC_IP
      ```

      Example output:

      ```screen
      172.30.52.74
      ```
     
      ```bash
      ncn-m001# ssh ncn-m002
      ncn-m002# CAN_IP=$(ip addr show vlan007 | grep "inet " | awk '{print $2}' | cut -f1 -d'/')
      ncn-m002# echo $CAN_IP
      ```

      Example output:

      ```screen
      10.102.4.9 
      ```

2. Export the root password of the BMC.

   ```bash
   export IPMI_PASSWORD=changeme
   ```

3. Power off the node.

   ```bash
   ipmitool -I lanplus -U root -E -H $BMC chassis power off
   ```

4. Verify that the node is off.

   ```bash
   ipmitool -I lanplus -U root -E -H $BMC chassis power status
   ```

   * Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing any further commands.

Proceed to the next step to [Remove NCN Data](Remove_NCN_Data.md) or return to the main [Add, Remove, Replace or Move NCNs](../Add_Remove_Replace_NCNs.md) page.
