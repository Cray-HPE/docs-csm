
## Edit the iPXE Embedded Boot Script

Manually adjust the iPXE embedded boot script to change the order of network interfaces for DHCP request. Changing the order of network interfaces for DHCP requests helps improve boot time performance.

### Prerequisites

This procedure requires administrative privileges.

### Procedure

1.  Edit the config map using one of the following options.

    It is recommended to save a backup of the config map before making any changes. The following is an example of creating a backup:

    ```bash
    ncn-m001# kubectl get configmap -n services cray-ipxe-bss-ipxe \
    -o yaml > /root/k8s/cray-ipxe-bss-ipxe-backup.yaml
    ```

    Administrators can add, remove, or reorder sections in the config map related to the interface being used.

    In the example below, the `net2` section is located before the `net0` section. If an admin wants `net0` to be run first, they could move the `net0` section to be located before the `net2` section.

    ```bash
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

    -   **Option 1:** Edit the cray-ipxe-bss-ipxe config map directly.

        ```bash
        ncn-m001#  kubectl edit configmap -n services cray-ipxe-bss-ipxe
        ```

    -   **Option 2:** Edit the config map by saving the file, editing it, and reloading the config map.
        1.  Save the file.

            ```bash
            ncn-m001# kubectl get configmap -n services cray-ipxe-bss-ipxe \
            -o yaml > /root/k8s/cray-ipxe-bss-ipxe.yaml
            ```

        2.  Edit the cray-ipxe-bss-ipxe.yaml file.

            ```bash
            ncn-m001# vi /root/k8s/cray-ipxe-bss-ipxe.yaml
            ```

        3.  Reload the config map.

            Deleting and recreating the config map will reload it.

            ```bash
            ncn-m001# kubectl delete configmap -n services cray-ipxe-bss-ipxe
            ncn-m001# kubectl create configmap -n services cray-ipxe-bss-ipxe \
            --from-file=/root/k8s/cray-ipxe-bss-ipxe.yaml
            ```

2.  Delete the iPXE pod to ensure the updated config map will be used.

    1.  Find the pod ID.

        ```bash
        ncn-m001# kubectl -n services get pods|grep cray-ipxe
        cray-ipxe-5dddfc65f-qfmrr           2/2     Running        2       39h
        ```

    2.  Delete the pod.

        Replace CRAY-IPXE\_POD\_ID with the value returned in the previous step. In this example, the pod ID would be `cray-ipxe-5dddfc65f-qfmrr`.

        ```bash
        ncn-m001# kubectl -n services delete pod CRAY-IPXE_POD_ID
        ```


Wait about 30 seconds for the iPXE binary to be regenerated and then the nodes will pick up the new ipxe.efi binary.


