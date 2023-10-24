# View BIOS Logs for Liquid-Cooled Nodes

SSH to a liquid-cooled node and view the BIOS logs. The BIOS logs for liquid-cooled node controllers \(nC\) are stored in the `/var/log/n0/current` and `/var/log/n1/current` directories.

The BIOS logs for liquid-cooled nodes are helpful for troubleshooting boot-related issues.

## Prerequisites

This procedure requires administrative privileges.

## Procedure

1. Log in to the node.

    SSH into the node controller for the host component name (xname). For example, if the host xname \(as defined in `/etc/hosts`\) is `x5000c1s0b0n0`, then the node controller would be `x5000c1s0b0`.

    ```bash
    ssh XNAME
    ```

1. Confirm that the hostname is correct for the node being used.

    ```bash
    hostname
    ```

    Example output:

    ```text
    x1000c2s5b0
    ```

1. View the logs for `n0`.

    `n0` is node 0 on the BMC.

    ```bash
    tail /var/log/n0/current
    ```

1. View the logs for `n1`.

    `n1` is node 1 on the BMC.

    ```bash
    tail /var/log/n1/current
    ```
