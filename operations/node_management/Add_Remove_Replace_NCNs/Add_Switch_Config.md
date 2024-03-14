# Add Switch Configuration for NCN

## Description

Update the network switches for the NCN that is being added.

## Procedure

### Update Networking to Add NCN

1. Validate SHCD with CANU.
2. Validate cabling with CANU.
3. Generate new switch configurations with CANU and updated SLS.
4. Review generated switch configurations.
5. Apply switch configurations.

For more information on CANU, see the [CANU documentation](https://cray-hpe.github.io/canu).

**DISCLAIMER:** This procedure is for standard network configurations and does not account for any site customizations that have been made to the management network.
Site administrators and support teams are responsible for knowing the customizations in effect in Shasta/CSM and configuring CANU to respect them when generating new network configurations.

See examples of using CANU custom switch configurations and examples of other CSM features that require custom configurations in the following documentation:

- [Manual Switch Configuration Example](../network/management_network/manual_switch_config.md)
- [Custom Switch Configuration Example](https://github.com/Cray-HPE/canu/blob/7e0cb58b6253b4c02be1bd420a619befab1f33ca/docs/network_configuration_and_upgrade/custom_config.md)

## Next Step

Proceed to the next step to [Add NCN Data](Add_NCN_Data.md) or return to the main [Add, Remove, Replace, or Move NCNs](Add_Remove_Replace_NCNs.md) page.
