# Fresh Install

This is either a first time install or the previous CSM was wiped and requires a new install.

:exclamation: All of these steps should be done using an out of band connection. This process is disruptive and will require downtime :exclamation: 


1. [Update management network firmware](firmware/update_management_network_firmware.md)
    - Upgrade switch firmware to specified firmware version.
1. [Wipe mgmt switches](wipe_mgmt_switches.md)
    - If the switches have any configuration, it is recommenced to erase it before adding any new configuration.
1. [Validate the SHCD](validate_shcd.md)
    - The SHCD defines the topology of a Shasta system, this is needed when generating switch configs.
1. [Generate switch configs](generate_switch_configs.md)
    - Generate the switch configuration file(s)
1. [Apply switch configs](apply_switch_configs.md)
    - Applying the configuration to switch.
1. [Setup Site Connection](Customer_Access_network_CAN.md)
    - Instruction on how to setup connection to the site.
1. [Validate switch configs](validate_switch_configs.md) 
    - Checks differences between generated configs and the configs on the system.
1. [Network tests](network_tests.md)
    - Run a suite of tests against the management network switches.