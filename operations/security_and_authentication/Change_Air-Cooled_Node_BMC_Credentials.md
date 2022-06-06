# Change Air-Cooled Node BMC Credentials

This procedure describes how to use the System Adminostrator Toolkit's `sat bmccreds`
command to set a global credential for all BMCs on air-cooled nodes.

### Limitations

All air-cooled and liquid-cooled BMCs share the same global credentials. The air-cooled Slingshot switch controllers (Router BMCs) must have the same credentials as the liquid-cooled Slingshot switch controllers.

The `sat bmccreds` command is not able to target air-cooled nodes directly. It can, however, target nodes by their xname. The following procedure uses xnames to target nodes.

### Prerequisites

The System Administrator Toolkit is installed and configured.

### Procedure

1. Get the xnames for all air-cooled nodes.

    The following operation will store the xnames in a variable named `RIVER_NODEBMC_XNAMES`.

    ```
    RIVER_NODEBMC_XNAMES=$(cray hsm state components list --class River --type NodeBMC \
        --format json | jq -r '[.Components[] | .ID ]| join(",")')
    ```

2. Set the same random password for every BMC on an air-cooled node.

    ```
    sat bmccreds --xnames $RIVER_NODEBMC_XNAMES --random-password --pw-domain bmc
    ```
