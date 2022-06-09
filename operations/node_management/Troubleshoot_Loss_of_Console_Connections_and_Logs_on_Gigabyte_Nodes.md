# Troubleshoot Loss of Console Connections and Logs on Gigabyte Nodes

## Problem

Gigabyte console log information will no longer be collected. If attempting to initiate a console session through Cray
console services, there will be an error reported. This error will occur every time the node is rebooted unless this workaround is applied.

## Prerequisites

Console log information is no longer being collected for Gigabyte nodes or ConMan is reporting an error.

## Procedure

1. Use `ipmitool` to deactivate the current console connection.

    1. Enter `root` user password for the BMC of the affected node.

        > `read -s` is used to prevent the password from being displayed on the screen or preserved in the shell history.

        ```bash
        ncn# read -s IPMI_PASSWORD
        ```

    1. Export the variable.

        ```bash
        ncn# export IPMI_PASSWORD
        ```

    1. Deactivate the SOL session for the node.

        > In the following command, replace `XNAME` with the component name (xname) of the BMC of the affected node.

        ```bash
        ncn# ipmitool -H XNAME -U root -E sol deactivate
        ```

1. Verify that console access to the node is working using the Cray console services.

    See [Log in to a Node Using ConMan](../conman/Log_in_to_a_Node_Using_ConMan.md).
