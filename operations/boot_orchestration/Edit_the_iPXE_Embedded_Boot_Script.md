# Edit the iPXE Embedded Boot Script

Manually adjust the iPXE embedded boot script to change the order of network interfaces for DHCP request. Changing the order of network interfaces for DHCP requests helps improve boot time performance.

## Prerequisites

This procedure requires administrative privileges.

## Procedure

1. (`ncn-mw#`) Edit the ConfigMap using one of the following options.

    > **`NOTE`** Save a backup of the ConfigMap before making any changes.

    The following is an example of creating a backup:

    ```bash
    kubectl get configmap -n services cray-ipxe-bss-ipxe \
            -o yaml > /root/cray-ipxe-bss-ipxe-backup.yaml
    ```

    Administrators can add, remove, or reorder sections in the ConfigMap related to the interface being used.

    In the following example, the `net2` section is located before the `net0` section. If an administrator wants `net0` to be run first, they could move the `net0` section to be located before the `net2` section.

    ```text
    :net2
    dhcp net2 || goto net2_stop
    echo net2 IPv4 lease: ${ip} mac: ${net2/mac}
    chain --timeout 10000 https://api-gw-service-nmn.local/apis/bss/boot/v1/bootscript?mac=${net2/mac} || echo Failed to retrieve next chain from Boot Script Service over net2 (https://api-gw-service-nmn.local/apis/bss/boot/v1/bootscript?mac=${net2/mac} && goto net2_stop
    :net2_stop
    ifclose net2 || echo No routes to drop.

    :net0
    dhcp net0 || goto net0_stop
    echo net0 IPv4 lease: ${ip} mac: ${net0/mac}
    chain --timeout 10000 https://api-gw-service-nmn.local/apis/bss/boot/v1/bootscript?mac=${net0/mac} || echo Failed to retrieve next chain from Boot Script Service over net0 (https://api-gw-service-nmn.local/apis/bss/boot/v1/bootscript?mac=${net0/mac} && goto net0_stop
    :net0_stop
    ifclose net0 || echo No routes to drop.
    ```

    - **Option 1:** Edit the `cray-ipxe-bss-ipxe` ConfigMap directly.

        ```bash
        kubectl edit configmap -n services cray-ipxe-bss-ipxe
        ```

    - **Option 2:** Edit the ConfigMap by saving the file, editing it, and reloading the ConfigMap.

        1. Save the file.

            ```bash
            kubectl get configmap -n services cray-ipxe-bss-ipxe -o yaml > /root/cray-ipxe-bss-ipxe.yaml
            ```

        1. Edit the `cray-ipxe-bss-ipxe.yaml` file.

        1. Reload the ConfigMap.

            Deleting and recreating the ConfigMap will reload it.

            ```bash
            kubectl delete configmap -n services cray-ipxe-bss-ipxe
            kubectl create -f /root/cray-ipxe-bss-ipxe.yaml
            ```

1. (`ncn-mw#`) Delete the iPXE pod to ensure the updated ConfigMap will be used.

    1. Find the pod ID.

        ```bash
        kubectl -n services get pods|grep cray-ipxe
        ```

        Example output:

        ```text
        cray-ipxe-5dddfc65f-qfmrr           2/2     Running        2       39h
        ```

    1. Delete the pod.

        Replace `CRAY-IPXE_POD_ID` with the value returned in the previous step. In this example, the pod ID is `cray-ipxe-5dddfc65f-qfmrr`.

        ```bash
        kubectl -n services delete pod CRAY-IPXE_POD_ID
        ```

Wait about 30 seconds for the iPXE binary to be regenerated, and then the nodes will pick up the new `ipxe.efi` binary.
