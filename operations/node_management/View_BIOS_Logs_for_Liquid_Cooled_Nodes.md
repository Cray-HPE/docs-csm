## View BIOS Logs for Liquid Cooled Nodes

SSH to a Liquid Cooled node and view the BIOS logs. The BIOS logs for Liquid Cooled node controllers \(nC\) are stored in the `/var/log/n0/current` and `/var/log/n1/current` directories.

The BIOS logs for Liquid Cooled nodes are helpful for troubleshooting boot-related issues.

### Prerequisites

This procedure requires administrative privileges.

### Procedure

1.  Log in to the node.

    `ssh` into the node controller for the host component name (xname). For example, if the host component name (xname) \(as defined in `/etc/hosts`\) is `x5000c1s0b0n0`, the node controller would be `x5000c1s0b0`.

    ```bash
    ncn# ssh XNAME
    ```

2.  Confirm the hostname is correct for the node being used.

    ```bash
    # hostname
    x1000c2s5b0
    ```

3.  Change to the `/var/log/n0` directory.

    ```bash
    # cd /var/log/n0
    ```

4.  View the logs for `n0`.

    `n0` is node 0 on the BMC.

    ```bash
    # tail current
    ```

5.  Change to the `/var/log/n1` directory.

    ```bash
    # cd /var/log/n1
    ```

6.  View the logs for `n1`.

    `n1` is node 1 on the BMC.

    ```bash
    # tail current
    ```


