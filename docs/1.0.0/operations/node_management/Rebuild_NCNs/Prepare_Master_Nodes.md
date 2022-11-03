# Prepare Master Node

## Description

Prepare a master node before rebuilding it.

## Procedure

### Step 1 - Confirm what the Configuration Framework Service (CFS) `configurationStatus` is for the `desiredConfig` before shutting down the node

1. The following command will indicate if a CFS job is currently in progress for this node. This command assumes you have set the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites).

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

1. If the `configurationStatus` is **pending**, wait for the job finish before rebooting this node.
   If the `configurationStatus` is **failed**, this means the failed CFS job `configurationStatus` preceded this worker rebuild, and that can be addressed independent of rebuilding this worker.
   If the `configurationStatus` is **unconfigured** and the NCN personalization procedure has not been done as part of an install yet, this can be ignored.

### Step 2 - Determine if the master node being rebuilt is the first master node

***IMPORTANT:*** The first master node is the node others contact to join the Kubernetes cluster. If this is the node being rebuilt, promote another master node to the initial node before proceeding.

1. Fetch the defined first-master-hostname

    ```bash
    ncn-m# craysys metadata get first-master-hostname
    ncn-m002
    ```

    * If the node returned is not the one being rebuilt, proceed to the step which [stops etcd](#stop-the-etcd-service-on-the-master-node-being-removed) and skip the substeps here.

1. Reconfigure the Boot Script Service \(BSS\) to point to a new first master node.

    On any master or worker node:

    ```bash
   cray bss bootparameters list --name Global --format=json | jq '.[]' > Global.json
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

    export KUBECONFIG=/etc/kubernetes/admin.conf

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

### Step 3 - Remove the Node from etcd

1. Determine the member ID of the master node being removed.

    * Run the following command and find the line with the name of the master being removed. Note the member ID and IP address for use in subsequent steps.
      * The ***member ID*** is the alphanumeric string in the first field of that line.
      * The ***IP address*** is in the URL in the fourth field in the line.

    On any master node:

    ```bash
    etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt  --cert=/etc/kubernetes/pki/etcd/ca.crt --key=/etc/kubernetes/pki/etcd/ca.key --endpoints=localhost:2379 member list
    ```

1. Remove the master node from the etcd cluster backing Kubernetes.

    Replace the `<MEMBER_ID>` value with the value returned in the previous sub-step.

    ```bash
    etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/ca.crt --key=/etc/kubernetes/pki/etcd/ca.key --endpoints=localhost:2379 member remove <MEMBER_ID>
    ```

### Step 4 - Stop the etcd service ***on the master node being removed***

```bash
systemctl stop etcd.service
```

### Step 5 - Remove the node from the Kubernetes cluster

* This command should not be run on the node being deleted.
* This command assumes you have set the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites).

    ```bash
    kubectl delete node $NODE
    ```

### Step 6 - Add the node back into the etcd cluster

This will allow the node to rejoin the cluster automatically when it rebuilds.

* The IP and hostname of the rebuilt node is needed for the following command.
* Replace the `<IP_ADDRESS>` address value with the IP address you noted in an earlier step from the `etcdctl` command.

**IMPORTANT:** This command assumes you have set the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites)

```bash
etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/ca.crt --key=/etc/kubernetes/pki/etcd/ca.key --endpoints=localhost:2379 member add $NODE --peer-urls=https://<IP_ADDRESS>:2380
```

[Click Here to Proceed to the Next Step](Identify_Nodes_and_Update_Metadata.md)

Or [Click Here to Return to Main page](../Rebuild_NCNs.md)
