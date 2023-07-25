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

    1. (`ncn-mw#`) Force the connection to become available again.

        The BMC username and password must be known for this command to work.

        > **`NOTE`** `read -s` is used to prevent the password from appearing in the command history.

        ```bash
        IPMI_USERNAME=root
        read -r -s -p "BMC ${IPMI_USERNAME} password: " IPMI_PASSWORD
        ```

        ```bash
        export IPMI_PASSWORD='Actual IMPI Password'
        ipmitool -H <BMC_XNAME> -U "${USERNAME}" -P "${IPMI_USERNAME}" -E -I lanplus sol deactivate
        ```

    1. Retry ConMan to verify that the connection has been reestablished.

1. Ensure that HPE iLO nodes have IPMI enabled.

    HPE iLO nodes sometimes ship with IPMI disabled. If that is the case,
    the console services will not be able to interact with them. To check the state of the BMC,
    follow the directions in
    [Enable IPMI Access on HPE iLO BMCs](../node_management/Enable_ipmi_access_on_HPE_iLO_BMCs.md).

1. (`ncn-mw#`) Ensure that River nodes have IPMI enabled.

    If the error `Error activating SOL payload: Invalid data field in request` is seen, check the
    setting of the `sol payload` on this node.

    ```bash
    ipmitool -H <BMC_XNAME> -U "${USERNAME}" -P "${IPMI_USERNAME}" -I lanplus sol info 3 | grep Enabled
    ```

    This will return the `Enabled` status:

    ```text
    Enabled                         : false
    ```

    or

    ```text
    Enabled                         : true
    ```

    If this is not enabled, then enable it:

    ```bash
    ipmitool -H <BMC_XNAME> -U "${USERNAME}" -P "${IPMI_USERNAME}" -I lanplus sol set enabled true
    ```

    Try the connection to the problematic node again.

1. Reset the node information cached in the node pod.

    The password (for air-cooled nodes only) and IP address of the BMC is cached at the time
    the connection is initially made. Sometimes if this information is changed after a
    connection has been established, it will continue to use the out of date information and
    fail to connect. This information can be reset by forcing a restart of the `conmand`
    process.

    1. (`ncn-mw#`) Exec into the node pod the node is assigned to.

        ```bash
        kubectl -n services exec -it "${NODE_POD}" -c cray-console-node -- bash
        ```

        Expected output:

        ```text
        nobody@cray-console-node-0:/>
        ```

    1. (`pod#`) Find the `conmand` process ID.

        ```bash
        ps -ax | grep conmand | grep -v grep
        ```

        Example output:

        ```text
           97 ?        Sl    45:36 conmand -F -v -c /etc/conman.conf
        ```

    1. Kill the `conmand` process.

        ```bash
        kill PROCESS_ID
        ```

    1. (`pod#`) Wait for the process to restart.

        ```bash
        ps -ax | grep conmand | grep -v grep
        ```

        This command gives no output until the `conmand` process has restarted.
        Do not proceed to the next step until the process has restarted.
        At that point, the output will resemble the following:

        ```text
        81518 ?        Sl     0:00 conmand -F -v -c /etc/conman.conf
        ```

1. Try the connection to the problematic node again.
