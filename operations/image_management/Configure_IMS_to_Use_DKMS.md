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

## Steps to configure jobs to run under Kata

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
    kata-clh    kata-clh    64d
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
    under this scenario so it's value does not matter.

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
