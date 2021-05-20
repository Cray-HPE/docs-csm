# Master Specific Steps

These are steps specific to upgrading a master node.

1. If the node being upgraded is ncn-m001, you should backup the site link configuration files:

    ```
    ncn-m001# cat /etc/sysconfig/network/ifcfg-lan0
    
    NAME='External Site-Link'
    
    # Select the NIC(s) for direct, external access.
    BRIDGE_PORTS='em1'
    
    # Set static IP (becomes "preferred" if dhcp is enabled)
    # NOTE: IPADDR's route will override DHCPs.
    BOOTPROTO='static'
    IPADDR='172.30.52.183/20'    # i.e. 10.100.10.1/24
    PREFIXLEN='20' # i.e. 24
    
    # DO NOT CHANGE THESE:
    ONBOOT='yes'
    STARTMODE='auto'
    BRIDGE='yes'
    BRIDGE_STP='no'
    ```

    ```
    ncn-m001# cat /etc/sysconfig/network/ifroute-lan0
    default 172.30.48.1 - -
    ```

2. Open a new terminal window to the stable NCN to watch the etcd cluster status, as well as the Kubernetes node
   listing.  This will be useful to watch the progress of the node being upgraded, so leave it up and running.

   > NOTE: if you have CAN enabled you are access nodes via that address.
   >> example:
   >>> ncn # ip -o -4 addr list vlan007|awk -F" |/" '{print $7}'

   ```bash
   ncn# watch 'etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/ca.crt  \
        --key=/etc/kubernetes/pki/etcd/ca.key \
        --endpoints=localhost:2379 member list; echo ""; kubectl get nodes'
   ```

3. Determine if the master node being upgraded is the "first master" node.  This is the node others contact to join the
   Kubernetes cluster, and if this is the node being upgraded, we'll need to re-assign this role to another master
   before proceeding.  Run the following command:

    > **`NOTE`** If the node returned ***IS NOT*** the one being rebuilt, proceed to step 5 *(see below example)*.

    ```bash
    ncn# curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters?name=Global | \
         jq '.[] | ."cloud-init"."meta-data"."first-master-hostname"'
    "ncn-m002"
    ```

4. **If necessary**, reconfigure BSS to point to a different master node than we will be upgrading.

    1. In this case, we'll change from ncn-m001 to ncn-m002. You can do the reverse when rebuilding ncn-m001.

        ```bash
        ncn# csi handoff bss-update-cloud-init --set meta-data.first-master-hostname=$STABLE_NCN --limit Global
        ```

    2. Install the docs-csm-install repo on the node we are promoting to be the new `first master` (if not already installed there), and execute the promote script:

       ```bash
       ncn# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm
       ncn# /usr/share/doc/csm/upgrade/1.0/scripts/k8s/promote-initial-master.sh
            CONTROL_PLANE_HOSTNAME has been set to 10.252.1.2
            CONTROL_PLANE_ENDPOINT has been set to 10.252.1.2:6442
            Setting K8S_NODE_IP to 10.252.1.6 for KUBELET_EXTRA_ARGS and kubeadm config
            FIRST_MASTER_HOSTNAME has been set to ncn-m002
            IMAGE_REGISTRY has been set to docker.io
       ```

        **Note** the `FIRST_MASTER_HOSTNAME` in the output above might not match the node you desire. This is not an
       error, this master hostname is not the one that BSS uses and therefore is fine.

5. Stop the etcd service on the master node being upgraded.

   ```bash
   ncn# ssh $UPGRADE_NCN systemctl stop etcd.service
   ```

6. Get the member ID of the node to be upgraded:

    ```bash
    ncn# export MEMBER_ID=$(etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt \
         --cert=/etc/kubernetes/pki/etcd/ca.crt \
         --key=/etc/kubernetes/pki/etcd/ca.key \
         --endpoints=localhost:2379 member list | \
         grep $UPGRADE_NCN | cut -d ',' -f1)
    ```

7. Using the member ID, remove the etcd member for the node being upgraded:

   ```bash
   ncn# etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/ca.crt \
        --key=/etc/kubernetes/pki/etcd/ca.key \
        --endpoints=localhost:2379 member remove $MEMBER_ID
   ```

8. Prepare the etcd cluster to receive a request to join from the NCN to be upgraded:

    ```bash
     ncn# etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt \
          --cert=/etc/kubernetes/pki/etcd/ca.crt  \
          --key=/etc/kubernetes/pki/etcd/ca.key \
          --endpoints=localhost:2379 \
          member add $UPGRADE_NCN --peer-urls=https://$UPGRADE_IP_NMN:2380
    ```

9. To cordon/drain the node run the below script in the example below.  This will evacuate pods running on the node.

   ```bash
   ncn# rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm
   
   ncn# /usr/share/doc/csm/upgrade/1.0/scripts/k8s/remove-k8s-node.sh $UPGRADE_NCN
   ```

Proceed to [Common Upgrade Steps](../common/upgrade-steps.md)
