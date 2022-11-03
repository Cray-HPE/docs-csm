# Troubleshoot Compute Node Boot Issues Related to the Boot Script Service \(BSS\)

Boot Script Service \(BSS\) delivers a boot script to a node based on its MAC address. This boot script tells the node where to obtain its boot artifacts, which include:

- `kernel`
- `initrd`

In addition, the boot script also contains the kernel boot parameters. This procedure helps resolve issues related to missing boot artifacts.

### Prerequisites

This procedure requires administrative privileges.

### Limitations

Encryption of compute node logs is not enabled, so the passwords may be passed in clear text.

### Procedure

1.  Log onto a non-compute node \(NCN\) as root.

2.  Check that BSS is running.

    ```bash
    ncn-m001# kubectl get pods -n services -o wide | grep cray-bss | grep -v -etcd-
    ```

    Example output:

    ```
    cray-bss-fd888bd54-gvpxq       2/2     Running     0      2d3h    10.32.0.16   ncn-w002   <none>    <none>
    ```

3.  Check that the boot script of the node that is failing to boot contains the correct boot artifacts.

    -   If nodes are identified by their host names, execute the following:

        ```bash
        ncn-m001# cray bss bootparameters list --hosts HOST_NAME
        ```

    -   If nodes are identified by their node IDs, execute the following:

        ```bash
        ncn-m001# cray bss bootparameters list --nids NODE_ID
        ```

4.  View the entire BSS contents.

    ```bash
    ncn-m001# cray bss dumpstate list
    ```

5.  View the actual boot script.

    Using hosts:

    ```bash
    ncn-m001# cray bss bootscript list --host HOST_NAME
    ```

    Using the MAC address to get the actual boot script:

    ```bash
    ncn-m001# cray bss bootscript list --mac MAC_ADDRESS
    ```

    Using node IDs to retrieve boot parameters:

    ```bash
    ncn-m001# cray bss bootscript list --nid NODE_ID
    ```

