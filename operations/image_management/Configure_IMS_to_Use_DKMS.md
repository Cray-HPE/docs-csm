# Configure IMS to Use DKMS

## Background

Some images require the building and installation of kernel drivers using the Dynamic Kernel Module Support (DKMS)
tool. This allows kernel modules to be built for the specific kernel used in the image. The DKMS tool requires
access to the running kernel that is not usually allowed by the Image Management Service (IMS). In order to safely
allow the expanded access, the IMS configuration must be modified to enable the feature.

## Requirements of DMKS

Many DKMS build and install scripts require access to the system `/proc`, `/dev`, and `/sys` directories which
allows access to running processes and system services. The IMS jobs run as an administrator user since preparing
images requires root access to work properly. Allowing root access to the running system would allow an
unacceptable security vulnerability to the Kubernetes worker node the job is running on.

## Using Kata

To address the security concerns, but also allow the DKMS tool to install kernel modules in image customization,
a Kata Virtual Machine (VM) is used. When DKMS is enabled in IMS, the jobs are modified to run inside a
Kata VM. The DKMS tool then has enhanced access to the running Kata VM kernel, but is unable to interact directly
with the Kubernetes worker the job is running on.

It is required that Kubernetes be configured with Kata. That should be part of the standard NCN worker
configuration, so documentation on how to do that is outside the scope of the IMS documentation.

**NOTE: Since the IMS job is running inside a VM, there will be a performance impact on the runtime of the job
but this is required to provide a secure environment.

## Steps to configure all jobs to run under Kata with DKMS enabled

The following steps will enable DKMS operation for all IMS jobs including those controlled by the Configuration
Management Service (CFS). It will remain in this configuration until manually reverted back to disabling the
DKMS operation.

1. (`ncn-mw#`) Check which Kata runtime class is installed.

    ```bash
    kubectl get runtimeclass
    ```

    Expected output is something like:

    ```text
    NAME        HANDLER     AGE
    kata-qemu   kata-qemu   64d
    ```

    Make note of the kata configuration to use for the IMS jobs.

    **NOTE: if there are no kata runtime classes returned by the above step, then Kata must
    be configured on the system. Instructions for that are beyond the scope of the IMS
    documentation.

1. (`ncn-mw#`) Edit the `ims-config` Kubernetes configuration map to enable DKMS.

    ```bash
    kubectl -n services edit cm ims-config
    ```

    Look for the lines:

    ```yaml
        JOB_ENABLE_DKMS: "False"
        JOB_KATA_RUNTIME: kata-qemu
    ```

    Change the value for `JOB_ENABLE_DKMS` to `True`. If the Kata runtime class on the system is not
    `kata-qemu` then change the `JOB_KATA_RUNTIME` to the desired configuration:

    ```yaml
        JOB_ENABLE_DKMS: "True"
        JOB_KATA_RUNTIME: kata-qemu
    ```

    Exit editing the configmap, saving the new values.

1. (`ncn-mw#`) Restart the IMS pod to pick up the new ConfigMap values.

    Find the current `cray-ims` pod:

    ```bash
    kubectl -n services get pods | grep ims
    ```

    Expected output will look something like:

    ```text
    cray-ims-bc875d949-fffk6            2/2     Running      0      4h29m
    ims-post-upgrade-gkf4t              0/2     Completed    0      2d3h
    ```

    Delete the running pod:

    ```bash
    kubectl -n services delete pod cray-ims-bc875d949-fffk6
    ```

    Then wait until the new pod is in the `2/2 Running` status. New IMS jobs will be created in
    Kata VM's with enhanced kernel access.

## Revert back to non DKMS usage

To revert the settings so the IMS jobs no longer run inside a Kata VM with the enhanced kernel
access change the `ims-config` setting back to `False` and restart the `cray-ims` pod again.

1. (`ncn-mw#`) Edit the `ims-config` Kubernetes configuration map to disable DKMS.

    ```bash
    kubectl -n services edit cm ims-config
    ```

    Look for the lines:

    ```yaml
        JOB_ENABLE_DKMS: "True"
        JOB_KATA_RUNTIME: kata-qemu
    ```

    Change the value for `JOB_ENABLE_DKMS` to `False`. The variable`JOB_KATA_RUNTIME` is not used when
    under this scenario so its value does not matter.

    ```yaml
        JOB_ENABLE_DKMS: "False"
        JOB_KATA_RUNTIME: kata-qemu
    ```

    Exit editing the configmap, saving the new values.

1. (`ncn-mw#`) Restart the IMS pod to pick up the new ConfigMap values.

    Find the current `cray-ims` pod:

    ```bash
    kubectl -n services get pods | grep ims
    ```

    Expected output will look something like:

    ```text
    cray-ims-bc875d949-64fc1            2/2     Running      0      4h29m
    ims-post-upgrade-gkf4t              0/2     Completed    0      2d3h
    ```

    Delete the running pod:

    ```bash
    kubectl -n services delete pod cray-ims-bc875d949-64fc1
    ```

    Then wait until the new pod is in the `2/2 Running` status. Now new IMS jobs will be started running
    directly on the Kubernetes node and without the enhanced kernel access.

## Setting a recipe to run with DKMS enabled

There is a data field for each recipe stored with IMS that can set if that particular recipe requires
DKMS to be enabled to built successfully. If this is set to 'True' it will override the global DKMS
setting described above.

To set the `dkms_required` field for a particular recipe:

1. (`ncn-mw#`) Set a variable with the IMS Recipe ID in the environment:

    ```bash
    IMS_RECIPE_ID=2233c82a-5081-4f67-bec4-4b59a60017a6
    ```

1. (`ncn-mw#`) Look at the current recipe record:

    ``` bash
    cray ims recipes describe $IMS_RECIPE_ID
    ```

    Expected output:

    ```json
    {
        "arch": "x86_64",
        "created": "2023-06-20T08:01:22.819146+00:00",
        "id": "c66f130c-c7c6-46b4-bb58-3fc17f08929f",
        "link": {
            "etag": "",
            "path": "s3://ims/recipes/c66f130c-c7c6-46b4-bb58-3fc17f08929f/myrecipe20June2023.tgz",
            "type": "s3"
        },
        "linux_distribution": "sles15",
        "name": "myrecipe20June2023",
        "recipe_type": "kiwi-ng",
        "require_dkms": false,
        "template_dictionary": []
    }
    ```

1. (`ncn-mw#`) Change the value of `require_dkms` for the recipe:

    ```bash
    cray ims recipes update --require-dkms true $IMS_RECIPE_ID
    ```

    Expected output:

    ```json
    {
        "arch": "x86_64",
        "created": "2023-06-20T08:01:22.819146+00:00",
        "id": "c66f130c-c7c6-46b4-bb58-3fc17f08929f",
        "link": {
            "etag": "",
            "path": "s3://ims/recipes/c66f130c-c7c6-46b4-bb58-3fc17f08929f/myrecipe20June2023.tgz",
            "type": "s3"
        },
        "linux_distribution": "sles15",
        "name": "myrecipe20June2023",
        "recipe_type": "kiwi-ng",
        "require_dkms": true,
        "template_dictionary": []
    }
    ```

## Run a particular IMS Job using DKMS

The call to create a new Job in IMS has a `require-dkms` field that will override the global and
recipe setting. If a value is passed in directly it will always take precedence when the job is
created.

1. (`ncn-mw#`) Use the `require-dkms` option when creating a recipe build job:

    ```bash
    cray ims jobs create \
        --job-type create \
        --image-root-archive-name cray-sles15-barebones \
        --artifact-id $IMS_RECIPE_ID \
        --public-key-id $IMS_PUBLIC_KEY_ID \
        --enable-debug False \
        --require-dkms True
    ```

    Example output:

    ```toml
    status = "creating"
    enable_debug = false
    kernel_file_name = "vmlinuz"
    artifact_id = "2233c82a-5081-4f67-bec4-4b59a60017a6"
    build_env_size = 10
    job_type = "create"
    kubernetes_service = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-service"
    kubernetes_job = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-create"
    id = "ad5163d2-398d-4e93-94f0-2f439f114fe7"
    image_root_archive_name = "cray-sles15-barebones"
    initrd_file_name = "initrd"
    arch = "x86_64"
    require_dkms = true
    created = "2018-11-21T18:22:53.409405+00:00"
    public_key_id = "a252ff6f-c087-4093-a305-122b41824a3e"
    kubernetes_configmap = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-configmap"
    ```

1. (`ncn-mw#`) Use the `require-dkms` option when creating an image customization job:

    ```bash
    cray ims jobs create \
        --job-type customize \
        --image-root-archive-name cray-sles15-barebones \
        --artifact-id $IMS_IMAGE_ID \
        --public-key-id $IMS_PUBLIC_KEY_ID \
        --enable-debug False \
        --require-dkms True
    ```

    Example output:

    ```toml
    status = "creating"
    enable_debug = false
    kernel_file_name = "vmlinuz"
    artifact_id = "2233c82a-5081-4f67-bec4-4b59a60017a6"
    build_env_size = 10
    job_type = "customize"
    kubernetes_service = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-service"
    kubernetes_job = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-create"
    id = "ad5163d2-398d-4e93-94f0-2f439f114fe7"
    image_root_archive_name = "cray-sles15-barebones"
    initrd_file_name = "initrd"
    arch = "x86_64"
    require_dkms = true
    created = "2018-11-21T18:22:53.409405+00:00"
    public_key_id = "a252ff6f-c087-4093-a305-122b41824a3e"
    kubernetes_configmap = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-configmap"
    ```
