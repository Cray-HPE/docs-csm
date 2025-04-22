# Log in to a Node Using ConMan

This procedure shows how to connect to the node's Serial Over LAN (SOL) via ConMan.

## Prerequisites

* The Cray CLI is configured.
  * See [Configure the Cray CLI](../configure_cray_cli.md).

## Limitations

* Encryption of compute node logs is not enabled, so the passwords may be passed in clear text.
* If the user is a member of a tenant only the logs for that tenant are available. 

## Procedure

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
