# Change Air-Cooled Node BMC Credentials Using SAT

This procedure describes how to use the System Admin Toolkit's (SAT) `sat bmccreds`
command to set a global credential for all BMCs on air-cooled nodes.

## Limitations

All air-cooled and liquid-cooled BMCs share the same global credentials. The air-cooled Slingshot switch controllers (Router BMCs) must have the same credentials as the liquid-cooled Slingshot switch controllers.

The `sat bmccreds` command is only able to target specific Node BMCs by their component name (xname). To target just the air-cooled node BMCs, a list of their xnames must be passed into the command.

## Prerequisites

SAT is installed and configured.

## Procedure

1. Get the xnames for all air-cooled nodes.

    The following operation will store the xnames in a variable named `RIVER_NODEBMC_XNAMES`.

    ```bash
    RIVER_NODEBMC_XNAMES=$(cray hsm state components list --class River --type NodeBMC \
        --format json | jq -r '[.Components[] | .ID ]| join(",")')
    ```

1. Set the same random password for every BMC on an air-cooled node.

    ```bash
    sat bmccreds --xnames $RIVER_NODEBMC_XNAMES --random-password --pw-domain system
    ```
