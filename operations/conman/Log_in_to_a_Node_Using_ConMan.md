# Log in to a Node Using ConMan

This procedure shows how to connect to the node's Serial Over LAN (SOL) via ConMan.

## Prerequisites

* The Cray CLI is configured.
    * See [Configure the Cray CLI](../configure_cray_cli.md).

## Limitations

* Encryption of compute node logs is not enabled, so the passwords may be passed in clear text.
* Tenant access restriction requires use of the Cray CLI method. Direct access to ConMan within a Kubernetes pod does not restrict access by tenant.
* If the user is a member of a tenant, then only the consoles for that tenant are available when using the CLI.

## Log in using the Cray CLI

### Sensitive input echoed when using CLI to access console

**`IMPORTANT`** When using the `cray` CLI for access and a password is required, it will be visible on the screen as it is
being typed. The websocket connection is secure and the password will not be recorded in the console logs but it will be
visible on the screen and will be captured by a `screen` session. If this is a concern, use the procedure to
[log in using ConMan directly within a Kubernetes pod](#log-in-using-conman-directly-within-a-kubernetes-pod).

### Procedure to log in using Cray CLI

> **`NOTE`** this procedure has changed since the CSM 1.6.x releases.

1. Log on to a Kubernetes master or worker node.

1. (`ncn-mw#`) Connect to the node's console.

    ```bash
    cray console interact $XNAME
    ```

    Example output:

    ```text
    Connected to wss://api-gw-service-nmn.local/apis/console-operator/console-operator/interact/x3000c0s19b1n0
    <ConMan> Connection to console [x3000c0s19b1n0] opened.

    nid000001 login:
    ```

    Using the command above, a user can also attach to an already active SOL session that is being used by another user, so both can access the node's SOL simultaneously.

1. Exit the connection to the console with the `&.``[Enter]` command.

    Example output:

    ```text
    <ConMan> Connection to console [x3000c0s19b1n0] opened.

    nid000001 login:&.
    &.
    <ConMan> Connection to console [x3000c0s19b1n0] closed.
    Connection closed by the server.
    ```

## Log in using ConMan directly within a Kubernetes pod

> **`NOTE`** this procedure has changed since the CSM 0.9 release.

1. Log on to a Kubernetes master or worker node.

1. (`ncn-mw#`) Find the `cray-console-operator` pod.

    ```bash
    OP_POD=$(kubectl get pods -n services -o wide|grep cray-console-operator|awk '{print $1}'); echo $OP_POD
    ```

    Example output:

    ```text
    cray-console-operator-6cf89ff566-kfnjr
    ```

1. (`ncn-mw#`) Set the `XNAME` variable to the component name (xname) of the node whose console is to be opened.

    ```bash
    XNAME=x123456789s0c0n0
    ```

1. (`ncn-mw#`) Find the `cray-console-node` pod that is connected to that node.

    ```bash
    NODEPOD=$(kubectl -n services exec $OP_POD -c cray-console-operator -- sh -c "/app/get-node $XNAME" | jq .podname | sed 's/"//g')
    echo $NODEPOD
    ```

    Example output:

    ```text
    cray-console-node-1
    ```

1. (`ncn-mw#`) Connect to the node's console using ConMan on the `cray-console-node` pod which was found.

    ```bash
    kubectl exec -it -n services $NODEPOD -c cray-console-node -- conman -j $XNAME
    ```

    Example output:

    ```text
    <ConMan> Connection to console [x3000c0s25b1] opened.

    nid000009 login:
    ```

    Using the command above, a user can also attach to an already active SOL session that is being used by another user, so both can access the node's SOL simultaneously.

1. Exit the connection to the console with the `&.` command.
