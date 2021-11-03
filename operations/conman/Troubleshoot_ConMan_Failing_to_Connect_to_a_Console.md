## Troubleshoot ConMan Failing to Connect to a Console

There are many reasons that conman may not be able to connect to a specific console. This procedure outlines several things to check that may impact the connectivity with a console.

### Prerequisites

This procedure requires administrative privileges.

### Procedure

1. Check for general network availability.

    If the Kubernetes worker node the cray-console-node pod that is attempting to connect with
    a console cannot access that network address the connection will fail.

    1. Find the cray-console-node pod that is connecting with the console of interest.

        ```
        ncn-m001# CONPOD=$(kubectl get pods -n services \
        -o wide|grep cray-console-operator|awk '{print $1}')
        ncn-m001# kubectl -n services exec $CONPOD -c cray-console-operator -- sh -c \
        '/app/get-node XNAME' | jq .podname | sed 's/"//g'
        cray-console-node-2
        ```

    2. Find the worker node this pod is running on.

        ```
        ncn-m001# kubectl -n services get pods -o wide | grep cray-console-pod-2
        cray-console-node-2   3/3  Running 0 28h  10.42.0.49  ncn-w003   <none>  <none>
        ```

    3. SSH to the worker node that the pod is running on.

        ```
        ncn-m001# ssh ncn-w003
        ncn-w003#
        ```

    4. Check that the BMC for this node is accessible from this worker.

        The xname of the BMC is the same as the node, but with the node designation at the
        end removed. For example if the node is x3000c0s15b0n0, the BMC is x3000c0s15b0.

        ```
        ncn-w003# ping BMC_XNAME
        PING x3000c0s7b0.hmn (10.254.1.7) 56(84) bytes of data.
        From ncn-m002.hmn (10.254.1.18) icmp_seq=1 Destination Host Unreachable
        From ncn-m002.hmn (10.254.1.18) icmp_seq=2 Destination Host Unreachable
        From ncn-m002.hmn (10.254.1.18) icmp_seq=3 Destination Host Unreachable
        From ncn-m002.hmn (10.254.1.18) icmp_seq=4 Destination Host Unreachable
        ```

        This indicates there is a network issue between the worker node and the node of
        interest. When the issue is resolved the console connection will be reestablished
        automatically.

2. Check for something else using the serial console connection.

    For IPMI-based connections, there can only be one active connection at a time. If
    something else has taken that connection, ConMan will not be able to connect to it.

    1. Find the cray-console-node pod that is connecting with the console of interest.

        ```
        ncn-m001# CONPOD=$(kubectl get pods -n services \-o wide|grep cray-console-operator|awk '{print $1}')
        ncn-m001# kubectl -n services exec $CONPOD -c cray-console-operator -- sh -c '/app/get-node XNAME' \
        | jq .podname | sed 's/"//g'
        cray-console-node-2
        ```

    2. Check the log information for the node.

        ```
        ncn-m001# kubectl -n services logs cray-console-node-2 cray-console-node | grep XNAME
        ```

        If something else is using the connection, there will be log entries like the following:

        ```
        2021/05/20 15:42:43 INFO:      Console [x3000c0s15b0n0] disconnected from <x3000c0s15b0>
        2021/05/20 15:43:23 INFO:      Unable to connect to <x3000c0s15b0> via IPMI for [x3000c0s15b0n0]: connection timeout
        2021/05/20 15:44:24 INFO:      Unable to connect to <x3000c0s15b0> via IPMI for [x3000c0s15b0n0]: SOL in use
        2021/05/20 15:45:23 INFO:      Unable to connect to <x3000c0s15b0> via IPMI for [x3000c0s15b0n0]: SOL in use
        2021/05/20 16:13:25 INFO:      Unable to connect to <x3000c0s15b0> via IPMI for [x3000c0s15b0n0]: SOL in use
        ```

    3. Force the connection to become available again.

        The BMC username and password must be known for this command to work.

        ```
        ncn-m001# export USERNAME=root
        ncn-m001# export IPMI_PASSWORD=changeme
        ncn-m001# ipmitool -H XNAME -U $USERNAME -E -I lanplus sol deactivate
        ```

    4. Retry conman to verify the connection has been reestablished.

