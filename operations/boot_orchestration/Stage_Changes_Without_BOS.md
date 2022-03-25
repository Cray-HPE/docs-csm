# Stage Changes Without BOS

Sometimes there is a need to stages changes to take place on a reboot, without immediately rebooting a node. When this is called for, users can bypass BOS, and set boot artifacts or configuration that will only take place when a node is later booted, whether that occurs manually, or triggered by a task manager.

### Stage Boot Artifacts

For information on staging boot artifacts, see the section [Upload Node Boot Information to Boot Script Service (BSS)](Upload_Node_Boot_Information_to_Boot_Script_Service_BSS.md).

### Stage a Configuration

1. Disable CFS for all nodes receiving the staged configuration. Nodes will automatically re-enable configuration when they are rebooted and will be configured with any staged changes.

    ```bash
    ncn-m001# cray cfs components update <xname> --enabled false
    ```

1. Either set the new desired configuration, or update the existing configuration.

    If an entirely new configuration is being used, or if no configuration was previously set for a component, update the configuration name with the following:

    ```bash
    ncn-m001# cray cfs components update <xname> --configuration-name <configuration_name>
    ```

    If all nodes that share a configuration are being staged with an update, updating the shared configuration will stage the change for all relevant nodes. Be aware that if this step is taken and not all nodes that use the configuration are disabled in CFS, the configuration will automatically and immediately apply to all enabled nodes that are using it.

    ```bash
    ncn-m001# cray cfs configurations update <configuration_name> --file <file_path>
    ```

    Users also have the option of specifying branches rather than commits in configurations. If this feature is used, the configuration can also be updated by telling CFS to update the commits for all layers of a configuration that specify branches. Like with updating the configuration from a file, this will automatically start configuration on any enabled nodes that are using this configuration. For information on using branches, see the section ([Use Branches in Configuration Layers](../configuration_management/Configuration_Layers.md#use-branches-in-configuration-layers))
