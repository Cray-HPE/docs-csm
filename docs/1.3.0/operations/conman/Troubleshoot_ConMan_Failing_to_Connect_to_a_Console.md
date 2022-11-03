# Troubleshoot ConMan Failing to Connect to a Console

There are many reasons that ConMan may not be able to connect to a specific console. This procedure outlines several things to check that may impact the connectivity with a console.

## Prerequisites

This procedure requires administrative privileges.

## Procedure

1. (`ncn-mw#`) Find the `cray-console-operator` pod.

    ```bash
    OP_POD=$(kubectl get pods -n services -o wide|grep cray-console-operator|awk '{print $1}')
    echo ${OP_POD}
    ```

    Example output:

    ```text
    cray-console-operator-6cf89ff566-kfnjr
    ```

1. (`ncn-mw#`) Set the `XNAME` variable to the component name (xname) of the node whose console is of interest.

    ```bash
    XNAME=<xname>
    ```

1. (`ncn-mw#`) Find the `cray-console-node` pod that is connecting with the console.

    ```bash
    NODE_POD=$(kubectl -n services exec "${OP_POD}" -c cray-console-operator -- sh -c "/app/get-node ${XNAME}" | jq .podname | sed 's/"//g')
    echo ${NODE_POD}
    ```

    Example output:

    ```text
    cray-console-node-2
    ```

1. Check for general network availability.

    If the Kubernetes worker node hosting a `cray-console-node` pod cannot access the network address
    of a console, then the connection will fail.

    1. (`ncn-mw#`) Find the worker node on which this pod is running.

        ```bash
        WNODE=$(kubectl get pods -o custom-columns=:.spec.nodeName -n services --no-headers "${NODE_POD}")
        echo ${WNODE}
        ```

        Example output:

        ```text
        ncn-w003
        ```

    1. (`ncn-mw#`) SSH to the worker node that the pod is running on.

        ```bash
        ssh "${WNODE}"
        ```

    1. (`ncn-w#`) Check that the BMC for this node is accessible from this worker.

        The component name (xname) of the BMC is the same as the node, but with the node designation at the
        end removed. For example, if the node is `x3000c0s15b0n0`, then the BMC is `x3000c0s15b0`.

        ```bash
        ping BMC_XNAME
        ```

        Example output:

        ```text
        PING x3000c0s7b0.hmn (10.254.1.7) 56(84) bytes of data.
        From ncn-m002.hmn (10.254.1.18) icmp_seq=1 Destination Host Unreachable
        From ncn-m002.hmn (10.254.1.18) icmp_seq=2 Destination Host Unreachable
        From ncn-m002.hmn (10.254.1.18) icmp_seq=3 Destination Host Unreachable
        From ncn-m002.hmn (10.254.1.18) icmp_seq=4 Destination Host Unreachable
        ```

        This indicates that there is a network issue between the worker node and the node of
        interest. When the issue is resolved, the console connection will be reestablished
        automatically.

1. Check for something else using the serial console connection.

    For IPMI-based connections, there can only be one active connection at a time. If
    something else has taken that connection, then ConMan will not be able to connect to it.

    1. (`ncn-mw#`) Check the log information for the node.

        ```bash
        kubectl -n services logs "${NODE_POD}" cray-console-node | grep "${XNAME}"
        ```

        If something else is using the connection, then there will be log entries like the following:

        ```text
        2021/05/20 15:42:43 INFO:      Console [x3000c0s15b0n0] disconnected from <x3000c0s15b0>
        2021/05/20 15:43:23 INFO:      Unable to connect to <x3000c0s15b0> via IPMI for [x3000c0s15b0n0]: connection timeout
        2021/05/20 15:44:24 INFO:      Unable to connect to <x3000c0s15b0> via IPMI for [x3000c0s15b0n0]: SOL in use
        2021/05/20 15:45:23 INFO:      Unable to connect to <x3000c0s15b0> via IPMI for [x3000c0s15b0n0]: SOL in use
        2021/05/20 16:13:25 INFO:      Unable to connect to <x3000c0s15b0> via IPMI for [x3000c0s15b0n0]: SOL in use
        ```

    1. (`ncn#`) Force the connection to become available again.

        The BMC username and password must be known for this command to work.

        > **`NOTE`** `read -s` is used to prevent the password from appearing in the command history.

        ```bash
        USERNAME=root
        read -r -s -p "BMC ${USERNAME} password: " IPMI_PASSWORD
        ```

        ```bash
        export IPMI_PASSWORD
        ipmitool -H <BMC_XNAME> -U "${USERNAME}" -E -I lanplus sol deactivate
        ```

    1. Retry ConMan to verify that the connection has been reestablished.
