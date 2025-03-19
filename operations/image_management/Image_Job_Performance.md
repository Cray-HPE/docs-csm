# Image Job Performance

Starting in CSM 1.5, image build and customization jobs in the Image Management Service (IMS) generally have
longer durations when compared to previous CSM releases. This is a consequence of intentional design choices,
and a need to ensure that the default behavior will work on all systems. There are steps that administrators
may use to reduce these durations in some cases. This document explains the reasons behind the longer durations,
and includes options for speeding up the jobs.

- [Emulation](#emulation)
- [Remote build nodes](#remote-build-nodes)
- [Kata](#kata)
- [PVCs](#pvcs)
- [Different content](#different-content)

## Emulation

In CSM 1.5, support for ARM (`aarch64`) hardware was added. Because the [worker NCNs](../../glossary.md#management-nodes)
do not use ARM hardware, IMS by default uses an emulation environment when working with ARM images. This adds a significant performance
penalty, and drastically increases the duration of the jobs. On systems that have ARM [compute nodes](../../glossary.md#compute-node-cn),
IMS can be configured to use one of these nodes as a remote build node, avoiding the emulation layer. This bypasses the extreme
performance penalties caused by running under emulation, and is strongly encouraged.

See:

- [Working With `aarch64` Images](Working_With_aarch64_Images.md)
- [Configure a Remote Build Node](Configure_a_Remote_Build_Node.md)

## Remote build nodes

Even in cases where architecture emulation is not taking place, the use of a remote build node may offer a performance benefit.
Administrators may wish to experiment with configuring an `x86` remote build node, to see if it offers performance improvements
for `x86` IMS image builds and customizations.

See [Configure a Remote Build Node](Configure_a_Remote_Build_Node.md).

## Kata

In order to provide a secure, isolated environment to work on images, IMS jobs run inside a Kata Container starting in CSM 1.5.
This does incur a performance penalty, and it is possible to disable this behavior, but **this is not recommended**.
For more information on Kata Containers, see the [Kata Containers home page](https://katacontainers.io/).

Kata may be disabled by using the following procedure:

1. (`ncn-mw#`) Edit the `cray-configmap-ims-v2-image-customize` Kubernetes ConfigMap in the `services` namespace.

    > This will disable Kata for IMS image customization jobs. Skip this step in order to leave Kata enabled
    > for image customizations.

    ```bash
    kubectl -n services edit cm cray-configmap-ims-v2-image-customize
    ```

    Edit it by commenting the following line:

    ```yaml
              runtimeClassName: $runtime_class
    ```

    After the edit, the line should be:

    ```yaml
              #runtimeClassName: $runtime_class
    ```

1. (`ncn-mw#`) Edit the `cray-configmap-ims-v2-image-create-kiwi-ng` Kubernetes ConfigMap in the `services` namespace.

    > This will disable Kata for IMS image build jobs. Skip this step in order to leave Kata enabled
    > for image builds.

    ```bash
    kubectl -n services edit cm cray-configmap-ims-v2-image-create-kiwi-ng
    ```

    Make the same edit as the previous step.

1. (`ncn-mw#`) Restart IMS.

    ```bash
    kubectl -n services rollout restart deployment cray-ims && kubectl -n services rollout status deployment cray-ims
    ```

To re-enable Kata, perform the same procedure, but reverse the edits.

## PVCs

In order to reliably handle large images, in CSM 1.5, IMS pods started using Kubernetes Persistent Volume Claims (PVCs)
for image storage, instead of in-memory volumes. This incurs a modest performance penalty, and it is possible to
disable this behavior. However, doing so runs the risk of exhausting storage space on the worker NCNs, causing problems.
As such, this is not recommended.

The use of these PVCs may be disabled by using the following procedure:

1. (`ncn-mw#`) Edit the `cray-configmap-ims-v2-image-customize` Kubernetes ConfigMap in the `services` namespace.

    > This will disable PVCs for IMS image customization jobs. Skip this step in order to continue to use PVCs
    > for image customizations.

    ```bash
    kubectl -n services edit cm cray-configmap-ims-v2-image-customize
    ```

    Edit the following section:

    ```yaml
          volumes:
          - name: image-vol
            persistentVolumeClaim:
              claimName: cray-ims-$id-job-claim
    ```

    Edit it to be the following:

    ```yaml
          volumes:
          - name: image-vol
            emptyDir: {}
            #persistentVolumeClaim:
            #  claimName: cray-ims-$id-job-claim
    ```

1. (`ncn-mw#`) Edit the `cray-configmap-ims-v2-image-create-kiwi-ng` Kubernetes ConfigMap in the `services` namespace.

    > This will disable PVCs for IMS image build jobs. Skip this step in order to continue to use PVCs
    > for image builds.

    ```bash
    kubectl -n services edit cm cray-configmap-ims-v2-image-create-kiwi-ng
    ```

    Make the same edit as the previous step.

1. (`ncn-mw#`) Restart IMS.

    ```bash
    kubectl -n services rollout restart deployment cray-ims && kubectl -n services rollout status deployment cray-ims
    ```

To re-enable PVCs, perform the same procedure, but reverse the edits.

## Different content

Prior to CSM 1.5, there were some configuration tasks which could only be performed on a live node (not during image customization).
These tasks would be run after the node booted by the
[Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs) as part of the live node personalization.
Because of improvements to IMS in CSM 1.5, many of these tasks are able to run during image customization. This leads to the image
customization jobs taking longer to run. This is preferable to the previous behavior. Instead of every single node having to run those
steps after they boot, the steps can be done just once to the image used by those nodes. This means that after the images are customized,
the time required for a node to boot and begin doing work is usually significantly less than it was prior to CSM 1.5.
