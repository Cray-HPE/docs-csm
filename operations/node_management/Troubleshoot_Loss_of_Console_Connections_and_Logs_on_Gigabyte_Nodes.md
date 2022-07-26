# Troubleshoot Loss of Console Connections and Logs on Gigabyte Nodes

## Problem

Gigabyte console log information will no longer be collected. If attempting to initiate a console session through Cray
console services, there will be an error reported. This error will occur every time the node is rebooted unless this workaround is applied.

## Prerequisites

Console log information is no longer being collected for Gigabyte nodes or ConMan is reporting an error.

## Procedure

1. (`ncn-mw#`) Deactivate the current console connection.

    1. Enter `root` user password for the BMC of the affected node.

        > **`NOTE`** `read -s` is used to prevent the password from being displayed on the screen or preserved in the shell history.

        ```bash
        USERNAME=root
        read -r -s -p "BMC ${USERNAME} password: " IPMI_PASSWORD
        ```

    1. Deactivate the SOL session for the node.

        > **`NOTE`** In the following command, replace `XNAME` with the component name (xname) of the BMC of the affected node.

        ```bash
        export IPMI_PASSWORD
        ipmitool -I lanplus -H XNAME -U "${USERNAME}" -E sol deactivate
        ```

1. Manually open a console connection to the node using the Cray console services.

    This is necessary to force the ConMan reconnection after closing the SOL session.
    See [Log in to a Node Using ConMan](../conman/Log_in_to_a_Node_Using_ConMan.md).
