# Management Node Image Customization

**NOTE:** Some of the documentation linked from this page mentions use of the Boot Orchestration Service (BOS). The use of BOS
is only relevant for booting compute nodes and can be ignored when working with NCN images.

This document describes the configuration of a Kubernetes NCN image. The same steps could be used to modify a Ceph NCN image.

1. (`ncn-mw#`) Locate the NCN image to be modified.

    This example assumes that the administrator wants to modify the Kubernetes image that is currently in use by NCNs. However, the steps are the same for any NCN SquashFS image.

    If the image to be modified is the image currently booted on an NCN, the value for `ARTIFACT_VERSION` can be found by looking
    at the boot parameters for the NCNs, or from `/proc/cmdline` on a booted NCN. The version has the form of `X.Y.Z`.

    ```bash
    ARTIFACT_VERSION=<artifact-version>

    cray artifacts get boot-images "k8s/${ARTIFACT_VERSION}/rootfs" "./${ARTIFACT_VERSION}-rootfs"

    cray artifacts get boot-images "k8s/${ARTIFACT_VERSION}/kernel" "./${ARTIFACT_VERSION}-kernel"

    cray artifacts get boot-images "k8s/${ARTIFACT_VERSION}/initrd" "./${ARTIFACT_VERSION}-initrd"

    export IMS_ROOTFS_FILENAME="${ARTIFACT_VERSION}-filesystem.squashfs"

    export IMS_KERNEL_FILENAME="${ARTIFACT_VERSION}-kernel"

    export IMS_INITRD_FILENAME="${ARTIFACT_VERSION}-initrd"
    ```

1. [Import External Image to IMS](../image_management/Import_External_Image_to_IMS.md).

    This document will instruct the administrator to set several environment variables, including the three set in
    the previous step.

1. Clone the `csm-config-management` repository.

   ```bash
   VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_username}} | base64 --decode)
   VCS_PASS=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
   git clone https://$VCS_USER:$VCS_PASS@api-gw-service-nmn.local/vcs/cray/csm-config-management.git
   ```

   You will need a Git commit hash from this repo in the following step.

1. [Create a CFS Configuration](Create_a_CFS_Configuration.md).

   The first layer in the CFS session should be similar to this:

   ```json
   "layers": [
   {
     "name": "csm-ncn-workers",
     "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
     "playbook": "ncn-worker_nodes.yml",
     "commit": "<git commit hash>"
   },
   ```

   The last layer in the CFS session should be similar to this:

   ```json
   "layers": [
   {
     "name": "csm-ncn-initrd",
     "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
     "playbook": "ncn-initrd.yml",
     "commit": "<git commit hash>"
   }
   ```

1. (`ncn-mw#`) Update NCN boot parameters.

    1. Get the existing `metal.server` setting for the component name (xname) of the node of interest:

        ```bash
        XNAME=<node-xname>
        METAL_SERVER=$(cray bss bootparameters list --hosts "${XNAME}" --format json | jq '.[] |."params"' \
            | awk -F 'metal.server=' '{print $2}' \
            | awk -F ' ' '{print $1}')
        echo "${METAL_SERVER}"
        ```

    1. Update the kernel, `initrd`, and metal server to point to the new artifacts.

        **NOTE:** `${IMS_RESULTANT_IMAGE_ID}` is the `result_id` returned in the output of the last command
        in the "Create an Image Customization CFS Session" procedure, repeated here for convenience:

        ```bash
        cray cfs sessions describe example --format json | jq .status.artifacts
        ```

        ```bash
        S3_ARTIFACT_PATH="boot-images/${IMS_RESULTANT_IMAGE_ID}"
        NEW_METAL_SERVER="s3://${S3_ARTIFACT_PATH}/rootfs"

        PARAMS=$(cray bss bootparameters list --hosts "${XNAME}" --format json | jq '.[] |."params"' | \
            sed "/metal.server/ s|${METAL_SERVER}|${NEW_METAL_SERVER}|" | \
            sed "s/metal.no-wipe=1/metal.no-wipe=0/" | \
            tr -d \")
        echo "${PARAMS}"
        ```

        In the output of the final echo command, verify that the value of `metal.server` was correctly set to `${NEW_METAL_SERVER}`.

    1. Update BSS with the new boot parameters.

        ```bash
        cray bss bootparameters update --hosts "${XNAME}" \
            --kernel "s3://${S3_ARTIFACT_PATH}/kernel" \
            --initrd "s3://${S3_ARTIFACT_PATH}/initrd" \
            --params "${PARAMS}"
        ```

1. (`ncn-mw#`) Prepare for reboot.

   **NOTE**: If the worker node image is being customized as part of a Cray EX initial install or upgrade involving multiple products,
   then refer to the /HPE Cray EX System Software Getting Started Guide/ (S-8000) for details on when to reboot the worker nodes to the new image.

   1. On the nodes being rebooted, run the following command to disable the boot loader and prepare the node to accept a new SquashFS.

      ```bash
      rm -rvf /metal/recovery/*
      ```

   1. Failover any Postgres leader that is running on the worker node being rebooted.

      ```bash
      /usr/share/doc/csm/upgrade/1.2/scripts/k8s/failover-leader.sh <node to be rebooted>
      ```

   1. Cordon and drain the node.

      ```bash
      kubectl drain --ignore-daemonsets=true --delete-local-data=true <node to be rebooted>
      ```

      There may be pods that cannot be gracefully evicted because of Pod Disruption Budgets (PDB). This will result in messages like the following:

      ```text
      error when evicting pod "<pod>" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
      ```

      In this case, there are some options.
      First, if the service is scalable, then increase the scale to start up another pod on another node, and then the drain will be able to delete it.
      However, it will probably be necessary to force the deletion of the pod:

      ```bash
      kubectl delete pod [-n <namespace>] --force --grace-period=0 <pod>
      ```

      This will delete the offending pod, and Kubernetes should schedule a replacement on another node.
      Then rerun the `kubectl drain` command, and it should report that the node is drained.

      ```bash
      kubectl drain --ignore-daemonsets=true --delete-local-data=true <node to be rebooted>
      ```

1. Reboot the NCN.

   ```bash
   shutdown -r now
   ```
