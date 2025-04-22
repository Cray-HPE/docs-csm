# Access Compute Node Logs

This procedure shows how the ConMan utility can be used to retrieve compute node logs.

## Prerequisites

* The Cray CLI is configured.
  * See [Configure the Cray CLI](../configure_cray_cli.md).

## Limitations

* Encryption of compute node logs is not enabled, so the passwords may be passed in clear text.
* If the user is a member of a tenant only the logs for that tenant are available. 

## Procedure

> **`NOTE`** this procedure has changed since the CSM 1.6.x releases.

1. Log on to a Kubernetes master or worker node.

1. (`ncn-mw#`) Start tailing the console log.

    Execute the `cray conman tail` command to start tailing the console log for a specific node.

    ```bash
    cray conman tail \
        --lines 20 \
        --follow \
        XNAME
    ```

    Example output:

    ```text
    Connected to wss://api-gw-service-nmn.local/apis/console-operator/console-operator/tail/x3000c0s19b1n0
    <ConMan> Console [x3000c0s19b1n0] log at 2025-04-22 11:00:00 UTC.
    <ConMan> Console [x3000c0s19b1n0] log at 2025-04-22 12:00:00 UTC.
    <ConMan> Console [x3000c0s19b1n0] log at 2025-04-22 13:00:00 UTC.
    <ConMan> Console [x3000c0s19b1n0] log at 2025-04-22 14:00:00 UTC.
    <ConMan> Console [x3000c0s19b1n0] log at 2025-04-22 15:00:00 UTC.
    <ConMan> Console [x3000c0s19b1n0] log at 2025-04-22 16:00:00 UTC.
    ```

1. (`ncn-mw#`) Stop the tailing of the console log.

    Press `Ctrl-C` twice to stop the tailing of the console log.

    Example output:

    ```text
    <ConMan> Console [x3000c0s19b1n0] log at 2025-04-22 15:00:00 UTC.
    ^C^C
    Aborted!
    ```
