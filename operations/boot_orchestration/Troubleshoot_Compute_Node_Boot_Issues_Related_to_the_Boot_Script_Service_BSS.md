# Troubleshoot Compute Node Boot Issues Related to the Boot Script Service (BSS)

The [Boot Script Service (BSS)](../../glossary.md#boot-script-service-bss) delivers a boot script to a node based on its MAC address.
This boot script tells the node where to obtain its boot artifacts, which include:

- kernel
- `initrd`

In addition, the boot script also contains the kernel boot parameters. This procedure helps resolve issues related to missing boot artifacts.

## Prerequisites

This procedure requires administrative privileges.

## Procedure

1. (`ncn-mw#`) Check that BSS is running.

    ```bash
    kubectl get pods -n services -o wide | grep cray-bss | grep -v -etcd-
    ```

    Example output:

    ```text
    cray-bss-fd888bd54-gvpxq       2/2     Running     0      2d3h    10.32.0.16   ncn-w002   <none>    <none>
    ```

1. (`ncn-mw#`) Check that the boot scripts of the nodes that are failing to boot contain the correct boot artifacts.

    - If nodes are identified by their host names, then execute the following:

        > In the following command, replace `HOST_NAMES` with a comma-separated list of the node component names ([xnames](../../glossary.md#xname)).

        ```bash
        cray bss bootparameters list --hosts HOST_NAMES
        ```

    - If nodes are identified by their node IDs, then execute the following:

        > In the following command, replace `NODE_IDS` with a comma-separated list of the [node IDs](../../glossary.md#node-id-nid).

        ```bash
        cray bss bootparameters list --nids NODE_IDS
        ```

1. (`ncn-mw#`) View the entire BSS contents.

    ```bash
    cray bss dumpstate list
    ```

1. (`ncn-mw#`) View the actual boot script.

    - Using host name:

        ```bash
        cray bss bootscript list --host HOST_NAME
        ```

    - Using the MAC address:

        ```bash
        cray bss bootscript list --mac MAC_ADDRESS
        ```

    - Using node ID:

        ```bash
        cray bss bootscript list --nid NODE_ID
        ```
