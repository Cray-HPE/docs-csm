# Remove Roles

## Description

Remove master, worker, or storage NCN from current roles. Select the procedure below based on the node type, complete the remaining steps to wipe the drives, and then power off the node.

## Procedure

**IMPORTANT:** The following procedures assume you have set the variables from [the prerequisites section](../Add_Remove_Replace_NCNs.md#remove-ncn-prerequisites) 

1. [Remove Roles](#remove-roles)
    - [Master node](#master-node-remove-roles)
    - [Worker node](#worker-node-remove-roles)
    - [Storage node](#storage-node-remove-roles)
1. [Wipe the drives](#wipe-the-drives)
    - [Master node](#wipe-disks-master-node)
    - [Worker node](#wipe-disks-worker-node)
    - [Storage node](#wipe-disks-utility-storage-node)
1. [Power off the node](#power-off-the-node)
1. [Next step](#next-step)

<a name="remove-roles"></a>
## Remove Roles

<a name="master-node-remove-roles"></a>
### Master Node Remove Roles

#### Determine if the master node being removed is the first master node

***IMPORTANT:*** The first master node is the node others contact to join the Kubernetes cluster. If this is the node being removed, promote another master node to the initial node before proceeding.

1. Fetch the defined `first-master-hostname`

    ```bash
    ncn-m# cray bss bootparameters list --hosts Global --format json |jq -r '.[]."cloud-init"."meta-data"."first-master-hostname"'
    ```

    Example Output:

    ```screen
    ncn-m002
    ```
  
    * If the node returned is not the one being removed, skip the substeps here and proceed to the [remove node from the Kubernetes cluster](#remove-the-node-from-the-kubernetes-cluster) step.

1. Reconfigure the Boot Script Service \(BSS\) to point to a new first master node.

    On any master or worker node:

    ```bash
    ncn-mw# cray bss bootparameters list --name Global --format=json | jq '.[]' > Global.json
    ```

1. Edit the `Global.json` file and edit the indicated line.

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

   Use `ssh` to login to the newly promoted master node chosen in the previous steps \(`ncn-m001` in this example\), copy/paste the following script to a file, and then execute it.

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
   cp /srv/cray/resources/common/cronjob_kicker.py /usr/bin/cronjob_kicker.py
   chmod +x /usr/bin/cronjob_kicker.py
   echo "0 */2 * * * root KUBECONFIG=/etc/kubernetes/admin.conf /usr/bin/cronjob_kicker.py >> /var/log/cray/cron.log 2>&1" > /etc/cron.d/cray-k8s-cronjob-kicker
   ```

<a name="reset-kubernetes-on-master"></a>
#### Reset Kubernetes on master node being removed

Run the following command **on the node being removed**. The command can be run from the ConMan console window.

```bash
ncn-m# kubeadm reset --force
```

<a name="stop-running-containers-on-master"></a>
#### Stop running containers on master node being removed

Run the commands in this section **on the node being removed**. The commands can be run from the ConMan console window.

1. List any containers running in `containerd`.

   ```bash
   ncn-m# crictl ps
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
   ncn-m# crictl stop <container id from the CONTAINER column>
   ```

<a name="remove-the-master-node-from-the-kubernetes-cluster"></a>
#### Remove the master node from the Kubernetes cluster

**IMPORTANT:** Run this command from a node ***NOT*** being deleted.

```bash
ncn-mw# kubectl delete node $NODE
```

#### Remove the Node from Etcd

1. Determine the member ID of the master node being removed.

    * Run the following command and find the line with the name of the master being removed. Note the member ID and IP address for use in subsequent steps.
      * The ***member ID*** is the alphanumeric string in the first field of that line.
      * The ***IP address*** is in the URL in the fourth field in the line.

    On any master node:

    ```bash
    ncn-m# etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt  --cert=/etc/kubernetes/pki/etcd/ca.crt \
            --key=/etc/kubernetes/pki/etcd/ca.key --endpoints=localhost:2379 member list
    ```

1. Remove the master node from the etcd cluster backing Kubernetes.

    Replace the `<MEMBER_ID>` value with the value returned in the previous sub-step.

    ```bash
    ncn-m# etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/ca.crt \
            --key=/etc/kubernetes/pki/etcd/ca.key --endpoints=localhost:2379 member remove <MEMBER_ID>
    ```

#### Stop kubelet, containerd and Etcd services ***on the master node being removed***

```bash
ncn-m# systemctl stop kubelet.service ; systemctl stop containerd.service ; systemctl stop etcd.service
```

#### Add the node back into the etcd cluster

This will allow the node to rejoin the cluster automatically when it gets added back.

* The IP address and hostname of the rebuilt node is needed for the following command.
* Replace the `<IP_ADDRESS>` address value with the IP address you noted in an earlier step from the `etcdctl` command.

```bash
ncn-mw# etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/ca.crt \
            --key=/etc/kubernetes/pki/etcd/ca.key --endpoints=localhost:2379 member add $NODE \
            --peer-urls=https://<IP_ADDRESS>:2380
```

#### Remove Etcd data directory ***on the master node being removed***.

```bash
ncn-m# rm -rf /var/lib/etcd/*
```

#### Save a copy of the `lan0` config from `ncn-m001` **only if `ncn-m001` is being removed**

**Skip this step if `ncn-m001` is not being removed.**

```bash
ncn-m001# rsync /etc/sysconfig/network/ifcfg-lan0 ncn-m002:/tmp/ifcfg-lan0-m001
```

#### Master node role removal complete

The master node role removal is complete; proceed to [wipe the drives](#wipe-disks-master-node).

<a name="worker-node-remove-roles"></a>
### Worker Node Remove Roles

#### Drain the node to clear any pods running on the node

**IMPORTANT:** The following command will cordon and drain the node. 

Run the following:

```bash
ncn-mw# kubectl drain --ignore-daemonsets --delete-local-data $NODE
```

You may run into pods that cannot be gracefully evicted due to Pod Disruption Budgets (PDB), for example:

```screen
error when evicting pod "<pod>" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
```

In this case, there are some options. If the service is scalable, you can increase the scale to start up another pod on another node, and then the drain will be able to delete it. However, it will probably be necessary to force the deletion of the pod:

```bash
ncn-mw# kubectl delete pod [-n <namespace>] --force --grace-period=0 <pod>
```

This will delete the offending pod, and Kubernetes should schedule a replacement on another node. You can then rerun the `kubectl drain` command, and it should report that the node is drained

<a name="reset-kubernetes-on-worker"></a>
#### Reset Kubernetes on worker node being removed

Run the following command **on the node being removed**. The command can be run from the ConMan console window.

```bash
ncn-w# kubeadm reset --force
```

<a name="stop-running-containers-on-worker"></a>
#### Stop running containers on worker node being removed

Run the commands in this section **on the node being removed**. The commands can be run from the ConMan console window.

1. List any containers running in `containerd`.

   ```bash
   ncn-w# crictl ps
   ```

   Example output:

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
   ncn-w# crictl stop <container id from the CONTAINER column>
   ```

<a name="remove-the-worker-node-from-the-kubernetes-cluster"></a>
#### Remove the worker node from the Kubernetes cluster after the node is drained

```bash
ncn-mw# kubectl delete node $NODE
```

#### Ensure all pods are stopped on the node

```bash
ncn-mw# kubectl get pods -A -o wide | grep $NODE
```

If no pods are returned, proceed to the next step. Otherwise, wait for any remaining pods to terminate.

#### Ensure there are no mapped `rbd` devices ***on the worker node being removed***

Run the following command **on the node being removed**. The command can be run from the ConMan console window.

```bash
ncn-w# rbd showmapped
```

If mapped devices still exist, perform the [Stop running containers on worker node being removed](#stop-running-containers-on-worker) step again. If devices are still mapped, they can be forcibly unmapped using `rbd unmap -o force /dev/rbd#`, where `/dev/rbd#` is the device that is still returned as mapped.

#### Worker node role removal complete

The worker node role removal is complete; proceed to [wipe the drives](#wipe-disks-worker-node).

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

1. Unmount etcd and `SDU`, and remove the volume group

   ```bash
   ncn-m# umount -v /run/lib-etcd /var/lib/etcd /var/lib/sdu
   ncn-m# vgremove -f -v --select 'vg_name=~metal*'
   ```

1. Wipe the drives

   ```bash
   ncn-m# mdisks=$(lsblk -l -o SIZE,NAME,TYPE,TRAN | grep -E '(sata|nvme|sas)' | sort -h | awk '   {print "/dev/" $2}') ; echo $mdisks
   ncn-m# wipefs --all --force $mdisks
   ```

<a name="wipe-disks-worker-node"></a>
### Wipe Disks: Worker Node

All commands in this section must be run **on the node being removed** \(unless otherwise indicated\). These commands can be done from the ConMan console window.

1. Stop `containerd` and wipe drives.

    ```bash
    ncn-w# systemctl stop containerd.service
    ```

1. Unmount partitions and remove the volume group.

    ```bash
    ncn-w# umount -v /var/lib/kubelet /run/lib-containerd /run/containerd /var/lib/s3fs_cache
    ncn-w# vgremove -f -v --select 'vg_name=~metal*'
    ```

1. Wipe drives

    ```bash
    ncn-w# wipefs --all --force /dev/disk/by-label/*
    ncn-w# wipefs --all --force /dev/sd*
    ```

<a name="wipe-disks-utility-storage-node"></a>
### Wipe Disks: Utility Storage Node

All commands in this section must be run **on the node being removed** \(unless otherwise indicated\). These commands can be done from the ConMan console window.

1. Make sure the OSDs (if any) are not running.

    ```bash
    ncn-s# podman ps
    ```

    Examine the output. There should be no running ceph processes or containers.

1. Remove the Ceph volume groups.

    ```bash
    ncn-s# ls -1 /dev/sd* /dev/disk/by-label/*
    ncn-s# vgremove -f --select 'vg_name=~ceph*'
    ```

1. Unmount and remove the metalvg0 volume group

   ```bash
   ncn-s# umount -v /etc/ceph ; umount -v /var/lib/ceph ; umount -v /var/lib/containers
   ncn-s# vgremove -f metalvg0
   ```

1. Wipe the disks and RAIDs.

    ```bash
    ncn-s# wipefs --all --force /dev/disk/by-label/*
    ncn-s# wipefs --all --force /dev/sd*
    ```

Once the wipe of the drives is complete, proceed to [power off the node](#power-off-the-node).

<a name="power-off-the-node"></a>
## Power Off the Node

**IMPORTANT:** Run these commands from a node ***NOT*** being powered off.

1. Set the BMC variable to the hostname of the BMC of the node being powered off.

   ```bash
   linux# BMC=${NODE}-mgmt
   ```

   1. **For `ncn-m001` only**: Collect and record the BMC IP address for `ncn-m001` and the CAN IP address for `m002` before `ncn-m001` is powered off. These may be needed later.

      1. Record the BMC IP address for `ncn-m001`:

         ```bash
         ncn-m001# BMC_IP=$(ipmitool lan print | grep 'IP Address' | grep -v 'Source'  | awk -F ": " '{print $2}')
         ncn-m001# echo $BMC_IP
         ```

         Example output:

         ```screen
         172.30.52.74
         ```
     
      1. Record the CAN IP address for `ncn-m002`:

         ```bash
         ncn-m002# CAN_IP=$(ip addr show vlan007 | grep "inet " | awk '{print $2}' | cut -f1 -d'/')
         ncn-m002# echo $CAN_IP
         ```

         Example output:

         ```screen
         10.102.4.9 
         ```

1. Export the root password of the BMC.

   > `read -s` is used in order to prevent the password from being echoed to the screen or saved in the shell history.

   ```bash
   linux# read -s IPMI_PASSWORD
   linux# export IPMI_PASSWORD
   ```

1. Power off the node.

   ```bash
   linux# ipmitool -I lanplus -U root -E -H $BMC chassis power off
   ```

1. Verify that the node is off.

   ```bash
   linux# ipmitool -I lanplus -U root -E -H $BMC chassis power status
   ```

   > Ensure the power is reporting as off. This may take 5-10 seconds for this to update. Wait about 30 seconds after receiving the correct power status before issuing any further commands.

<a name="next-step"></a>
## Next Step

Proceed to the next step to [Remove NCN Data](Remove_NCN_Data.md) or return to the main [Add, Remove, Replace, or Move NCNs](../Add_Remove_Replace_NCNs.md) page.
