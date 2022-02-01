# Apply switch configs

:exclamation: All of these steps should be done using an out of band connection. This process is disruptive and will require downtime :exclamation:  

If the switch is wiped you should be able to copy and paste the generated switch configs into the terminal.  See the [generate switch config](generate_switch_configs.md) page for more info on this.

If you did not backup user and SNMP configuration you will need to manually configure these.  See [manual switch config](manual_switch_config.md) for more information.

Be sure to type `auto-confirm` before pasting in the configuration.
This will automatically accept prompts.

`switch(config)# auto-confirm`

Once this is complete for all the switches, you should validate that the switch configs match what is generated.  [validate switch configs](validate_switch_configs.md)

