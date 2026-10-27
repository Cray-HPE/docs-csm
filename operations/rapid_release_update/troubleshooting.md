# Troubleshooting RRU Deploy

## Known Issues

1. [Storage node `cloud-init` fails with 'Timed out waiting for device' error](#1-storage-node-cloud-init-fails-with-timed-out-waiting-for-device-error)
1. [Master node `assign-ncn-images.sh` fails with 'Error: Error received from server: 403 Forbidden'](#2-master-node-assign-ncn-imagessh-fails-with-error-error-received-from-server-403-forbidden)
1. [Secret `kubeadm-certs` was not found in the `kube-system` Namespace](#3-secret-kubeadm-certs-was-not-found-in-the-kube-system-namespace)

## 1. Storage node `cloud-init` fails with 'Timed out waiting for device' error

## 1.1. Observed Error

This error can be observed from a storage node's console.

```text
[ TIME ] Timed out waiting for device /dev/disk/by-label/CEPHETC.
[DEPEND] Dependency failed for File System Check on /dev/disk/by-label/CEPHETC.
[DEPEND] Dependency failed for /etc/ceph.
[DEPEND] Dependency failed for Local File Systems.
[DEPEND] Dependency failed for Early Kernel Boot Messages.
[ TIME ] Timed out waiting for device /dev/disk/by-label/CEPHVAR.
[DEPEND] Dependency failed for /var/lib/ceph.
[DEPEND] Dependency failed for File System Check on /dev/disk/by-label/CEPHVAR.
```

## 1.2. Description

This error happens when a storage node is being upgraded to a new image outside of the normal CSM major release upgrade.
This happens because `rd.live.dir` still exists after the node reboots and the node does not pull the new image.

## 1.3. Procedure

1. (`ncn-m001#`) Set `TARGET_NCN` to the storage node hostname for the node that will be booted into a new image.

    ```bash
    TARGET_NCN=ncn-s00X
    ```

1. (`ncn-m001#`) Set the image ID of the image that the node should be booted into.

    ```bash
    STORAGE_NODE_IMAGE_ID=<image_id>
    ```

1. (`ncn-m001#`) Set the `TOKEN` and `TARGET_XNAME` variables. These variables are needed in subsequent steps.

    ```bash
    export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
    -d client_id=admin-client \
    -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) \
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

    TARGET_XNAME=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Management" \
    | jq -r ".[] | select(.ExtraProperties.Aliases[] | contains(\"$TARGET_NCN\")) | .Xname")
    echo "TARGET_XNAME: $TARGET_XNAME"
    ```

1. (`ncn-m001#`) Set the `rd.live.dir` on the `TARGET_NCN` to the `STORAGE_NODE_IMAGE_ID`. This ensures `rd.live.dir` will be a unique value.

    ```bash
    csi handoff bss-update-param --delete rd.live.dir --limit "${TARGET_XNAME}"
    csi handoff bss-update-param --set rd.live.dir=${STORAGE_NODE_IMAGE_ID} --limit "${TARGET_XNAME}"
    ```

1. (`ncn-m001#`) Follow the steps for one of the two options depending on the status of the storage node.

    * **Option 1:** Start a new storage node upgrade if one has not already been started.

        > Note: if a new CFS configuration is also necessary, append the argument `--desired-cfs-conf <configuration>` to the command below.

        ```bash
        /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh $TARGET_NCN --upgrade --image-id $STORAGE_NODE_IMAGE_ID
        ```

    * **Option 2:** If a storage node has already attempted to boot into a new image and `cloud-init` has failed, manually power cycle the node.

        The following error will be seen in `cloud-init` if a storage node has already been attempted to be upgraded without setting `rd.live.dir` to a new unique value.
        This error can be seen for the node's console. See [log in to a node using ConMan](../conman/Log_in_to_a_Node_Using_ConMan.md).

        ```text
        [ TIME ] Timed out waiting for device /dev/disk/by-label/CEPHETC.
        [DEPEND] Dependency failed for File System Check on /dev/disk/by-label/CEPHETC.
        [DEPEND] Dependency failed for /etc/ceph.
        [DEPEND] Dependency failed for Local File Systems.
        [DEPEND] Dependency failed for Early Kernel Boot Messages.
        [ TIME ] Timed out waiting for device /dev/disk/by-label/CEPHVAR.
        [DEPEND] Dependency failed for /var/lib/ceph.
        [DEPEND] Dependency failed for File System Check on /dev/disk/by-label/CEPHVAR.
        ```

        1. (`ncn-m001#`) Power cycle the storage node. Follow the steps in [Power Cycle and Rebuild Nodes](../node_management/Rebuild_NCNs/Power_Cycle_and_Rebuild_Nodes.md) to power cycle the node. Do not perform steps after "wait for `cloud-init`".
        These steps are unnecessary and will be completed by the remaining steps of the storage node upgrade Argo Workflow.

        1. (`ncn-m001#`) Perform this step only if the Argo workflow for the storage node upgrade was stopped.
        Resume the workflow by simply rerunning the same command that initiated the upgrade workflow.
        When a workflow is in-progress or a workflow has failed, that same workflow will be resumed and no new workflow will be started by running the command.

            ```bash
            /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh $TARGET_NCN --upgrade --image-id $STORAGE_NODE_IMAGE_ID
            ```

1. (`ncn-m001#`) Monitor the Argo Workflow using the Argo UI. See [using the Argo UI](../argo/Using_the_Argo_UI.md) for instructions to access the Argo UI.

1. (`ncn-m001#`) Once the upgrade has succeeded, remove old images on the storage node.

    ```bash
    ssh $TARGET_NCN '/srv/cray/scripts/metal/cleanup-live-images.sh -y -o'
    ```

1. (`ncn-m001#`) Check that Ceph is healthy.

    ```bash
    ceph -s
    ```

## 2. Master node `assign-ncn-images.sh` fails with 'Error: Error received from server: 403 Forbidden'

## 2.1. Observed Error

```bash
/usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh -p $MASTER_IMAGE_ID $XNAME
Updating [1] hosts with
rootfs URL: s3://boot-images/a70de793-859a-44e0-8d53-f27893097158/rootfs
initrd URL: s3://boot-images/a70de793-859a-44e0-8d53-f27893097158/initrd
kernel URL: s3://boot-images/a70de793-859a-44e0-8d53-f27893097158/kernel
x3000c0s1b0n0  : 
Usage: cray bss bootparameters list [OPTIONS]
Try 'cray bss bootparameters list -h' for help.

Error: Error received from server: 403 Forbidden
```

## 2.2. Description

Cray Command Line Interface (`cray` CLI) is not configured

## 2.3. Procedure

1. (`ncn-mws#`) Initialize the `cray` CLI

    ```bash
    cray init
    ```

    Expected output (including responses to the prompts):

    ```text
    Overwrite configuration file at: MY_HOME_DIR/.config/cray/configurations/default ? [y/N]: y
    Cray Hostname: api-gw-service-nmn.local
    Username: MY_DCIPA_USER_NAME
    Password: MY_PASSWORD
    Success!

    Initialization complete.
    ```

1. (`ncn-mws#`) The `cray` CLI may need to be authenticated to complete the setup.

    Use the same Keycloak username and password from the above initialization command. To authenticate to the `cray` CLI:

    ```bash
    cray auth login
    ```

    Expect the following prompts:

    ```text
    Username: MY_DCIPA_USER_NAME
    Password: MY_PASSWORD
    Success!
    ```

## 3. Secret `kubeadm-certs` was not found in the `kube-system` Namespace

## 3.1. Observed Error

**Warning:**  While watching the console for `ncn-m003`, you might see an error like this as part of a set of looping messages.

```bash
2026-10-20 14:50:09 [ 1617.920705] cloud-init[12514]: error execution phase control-plane-prepare/download-certs: error downloading
certs: error downloading the secret: Secret "kubeadm-certs" was not found in the "kube-system" Namespace. This Secret might have expired.
Please, run `kubeadm init phase upload-certs --upload-certs` on a control plane to generate a new one
```

## 3.2. Description

`Kubeadm` join token missing during NCN rebuild

## 3.3. Procedure

If this happens, then follow the [`Kubeadm` join token missing during NCN rebuild](https://github.com/Cray-HPE/docs-csm/blob/release/1.7/troubleshooting/known_issues/kubeadm_join_token_missing_during_ncn_rebuild.md)
procedure which includes steps to promote the initial master script which clears the Kubernetes bootstrap tokens, loads them into a `cluster-info` config map
and regenerates the Kubernetes join scripts in `/etc/cray/kubernetes`, then configures an hourly cronjob to create/update the tokens.  After that the node being rebuilt will have to be power cycled to attempt the rebuild again.
