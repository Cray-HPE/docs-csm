# Replace Switch

## CAUTION: Do not plug in a switch that is not configured. This can cause unpredictable behavior and network outages.

This can cause unpredicted behavior and network outages.

### Prerequisites 

- Out of band access to the switches (console).
- GA generated switch config or backed-up switch config exists.
  - [Generate Switch Config](generate_switch_configs.md)
  - [Configuration Management](config_management.md)

### Steps

These need to be followed in this order.

1. Update firmware on new switch.
    - [Update management network firmware](firmware/update_management_network_firmware.md)
1. Apply the configuration.
    - [Apply Switch Configs](apply_switch_configs.md)

1. Unplug all the network and power cables and remove the failed switch.
1. Plug in the network cables.
1. Plug in the power cables.
