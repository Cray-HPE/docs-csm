# Quick management network install guide

> ***IMPORTANT*** Please refer to the ***Management Network User Guide***; i.e. if you have ***not***
> validated your SHCD and cabling in prior or have a more complex installation that requires special configuration before
> proceeding with the network installation. Topic "install scenarios" contains more in depth instructions.

* [Management Network User Guide](README.md)

## Network install guide

***NOTE:*** It is recommended to backup your previous configuration (if installed) and wipe your switch
configuration prior to fresh install of the network (steps to do this are defined in the fresh install guide in the
management network guide). If you are doing a reinstall of the system, please refer to [reinstall guide](reinstall.md) guide.

1. Upgrade switch firmware to specified firmware version.

   Refer to [Update Management Network Firmware](firmware/update_management_network_firmware.md).

1. Generate the switch configuration file(s).

   Refer to [Generate Switch Configurations](generate_switch_configs.md).
   * ***NOTE*** If any [Custom configuration](canu/custom_config.md) needs to be added please see CANU example here.

1. Apply the configuration to switch.

    Refer to [Apply Switch Configurations](apply_switch_configurations.md).

1. Setup connection to the site. ***You can skip this step if you have already created this via CANU custom config above***

   Refer to [Setup Site Connection](../customer_accessible_networks/Customer_Accessible_Networks.md).

   To manually apply custom configuration:

   * [Apply Custom Switch Configurations 1.2](apply_custom_config_1.2.md)

1. Run a suite of tests against the management network switches.

    Refer to [Network Tests](network_tests.md).

Note that the configuration of the management network is an advanced task that may require the help of a networking subject matter expert.
