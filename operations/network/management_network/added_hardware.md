# Added Hardware

Follow this procedure when new hardware is added to the system.

## Procedure

1. Validate the SHCD.

   The SHCD defines the topology of a Shasta system, this is needed when generating switch configurations.

   Refer to [Validate the SHCD](validate_shcd.md).

1. Generate the switch configuration file(s).

   Refer to [Generate Switch Configs](generate_switch_configs.md).

1. Check the differences between the generated configurations and the configurations on the system.

   Refer to [Validate Switch Configs](validate_switch_configs.md).

1. Run a suite of tests against the management network switches.

   Refer to [Network Tests](network_tests.md).
