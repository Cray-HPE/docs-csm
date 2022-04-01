# Configuration Management

This page is designed for:

- Showing users how initially save switch configs so they can be used again
- Switching between saved configurations

> **CAUTION** All of these steps should be done using an out of band connection. This process is disruptive and will require downtime.

All this info can be found in the switch [External User Guides](external_user_guides.md).

### Prerequisites

It is recommended to do a `show run` on each switch and save that configuration before attempting the following procedures.

## Aruba

### Change Configuration

Maximum number of checkpoints:
1. Maximum checkpoints: 64 (including the startup configuration)
1. Maximum user checkpoints: 32
1. Maximum system checkpoints: 32

#### Save the current configuration into a checkpoint (needs be done when in both CSM1.0 and CSM1.2)

1. Save the configuration to a checkpoint.

    ```
    sw-spine-001(config)# copy running-config checkpoint CSM1_0
    ```

    Example output:

    ```
    Note: checkpoint name with special characters not allowed (only
    alphanumeric, hyphen, and underscore are allowed)
    ```

1. Check on the saved checkpoints.

    ```
    sw-spine-001(config)# show checkpoint
    ```

    Example output:

    ```
    NAME TYPE WRITER DATE(YYYY/MM/DD) IMAGE VERSION
    CSM1_0 latest User 2022-01-13T16:51:37Z GL.10.08.1021
    CSM1_2 latest User 2022-01-13T16:51:48Z GL.10.08.1021
    startup-config startup User 2021-12-20T17:35:58Z GL.10.08.1021
    ```

1. Copying the existing checkpoint point to the startup config to switch between CSM 1.0 and CSM 1.2 configuration.

   1. Copying the checkpoint to startup:

      ```
      sw-spine-001(config)# copy checkpoint CSM1_2 startup-config
      ```

   1. Boot the system to start with configuration from different CSM version.

      ```
      sw-spine-001(config)# boot system
      ```

The switch will now boot to the desired configuration.

## Dell

#### Save the configuration file from running system (going from one CSM release to the other for the first time)

This should only need to be done once (unless hardware is added or PoR config has changed). Once this configuration file has been saved, the administrator should be able to switch between the two configuration files.

The following example is a 1.0 system that is going to 1.2.

1. Save the startup config to new XML config.

   ```
   sw-leaf-bmc-001(config)# copy config://startup.xml config://csm1.0.xml
   ```

1. Erase the startup config and reboot.

   1. Erase the startup config.

      ```
      sw-leaf-bmc-001# delete startup-configuration
      ```

      Example output:

      ```
      Proceed to delete startup-configuration [confirm yes/no(default)]:yes
      ```

   1. Reboot after erasing the config.

      ```
      sw-leaf-bmc-001# reload
      ```

      Example output:

      ```
      System configuration has been modified. Save? [yes/no]:no
      Continuing without saving system configuration
      Proceed to reboot the system? [confirm yes/no]:yes
      ```

      This will boot the switch to factory defaults.

1. Paste in the new CANU generated config once the switch boots into the factory defaults.

1. Save the config.

   ```
   sw-cdu-001(config)# do write memory
   sw-cdu-001(config)# copy config://startup.xml config://csm1.2.xml
   ```

   `Copy completed` will be returned if successful.

1. Verify that both configs exist.

   ```
   sw-cdu-001(config)# dir config
   ```

   Example output:

   ```
   Directory contents for folder: config
   Date (modified) Size (bytes) Name
   --------------------- ------------
   ------------------------------------------
   2022-01-12T22:21:35Z 53441 csm1.0.xml
   2022-01-12T22:34:03Z 97654 csm1.2.xml
   2022-01-12T22:33:47Z 97654 startup.xml
   ```

#### Reload the switch to a different CSM version config

This process should be used when config files for the desired CSM version are currently on the switch.

The following example shows going from CSM 1.2 to CSM 1.0 switch config.

1. View the current switch config files.

    ```
    OS10(config)# dir config
    ```

    Example output:

    ```
    Directory contents for folder: config
    Date (modified) Size (bytes) Name
    --------------------- ------------
    ------------------------------------------
    2022-01-12T22:21:35Z 53441 csm1.0.xml
    2022-01-12T22:34:03Z 97654 csm1.2.xml
    2022-01-12T22:40:58Z 53441 startup.xml
    ```

1. Copy the desired switch config to the startup config and reload.

    ```
    (config)# copy config://csm1.0.xml config://startup.xml
    (config)# reload
    System configuration has been modified. Save? [yes/no]:no
    ```

The switch will then boot to the desired config.


## Mellanox

#### Save a configuration file from running system (going from one CSM release to the other for the first time)

This should only need to be done once (unless hardware is added or PoR config has changed). Once this configuration file has been saved, the administrator should be able to switch between the two configuration files.

The following example is a 1.0 system that is going to 1.2.

1. Write the current configuration to a file. This copies the current running config to a binary config file.

    ```
    (config) # configuration write to csm1.0
    ```

1. Verify the new configuration file was created.

    ```
    (config) # show configuration
    ```

    Example output:

    ```
    files
    csm1.0 (active)
    initial
    initial.bak
    Active configuration: csm1.0
    Unsaved changes : no
    ```

1. Create a new config file for CSM 1.2.

    When a new config file is created, no data is written to it. The administrator will boot to this new config file and paste the CANU generated config to it.

    ```
    (config) # configuration new csm1.2
    ```

1. Check that the configuration files contain the new csm1.2 blank config that was just created.

    ```
    (config) # show configuration
    ```

    Example output:

    ```
    files
    csm1.0 (active)
    csm1.2
    initial
    initial.bak
    Active configuration: csm1.0
    Unsaved changes : no
    ```

1. Switch to the new config, which requires a reboot.

    ```
    (config) # configuration switch-to csm1.2
    This requires a reboot.
    Type 'yes' to confirm: yes
    ```

1. Once the switch is rebooted, verify the config file is correct. It should reboot without any configuration.

    ```
    switch-cc30b4 [standalone: master] # show configuration files
    ```

    Example output:

    ```
    csm1.0
    csm1.2 (active)
    initial
    initial.bak
    Active configuration: csm1.2
    Unsaved changes : yes
    ```

1. Paste in the new CANU generated 1.2 config.

1. Save the config.

    ```
    (config) # write memory
    ```

#### Reload a switch to a different CSM version config

This process should be used when config files for the desired CSM version are currently on the switch.

In the following example, the switch config will go from CSM 1.2 to CSM 1.0.

1. Verify that the correct configuration file exists on the switch.

    ```
    sw-spine-001 [mlag-domain: master] (config) # show configuration files
    ```

    Example output:

    ```
    csm1.0
    csm1.2 (active)
    csm1.2.bak
    initial
    initial.bak
    Active configuration: csm1.2
    Unsaved changes : no
    ```

1. Switch to desired config version, which requires a reboot.

    ```
    (config) # configuration switch-to csm1.0
    This requires a reboot.
    Type 'yes' to confirm: yes
    ```

    The switch should boot to the config version typed in the previous command.

1. Verify the config version after the switch is booted.

    ```
    # show configuration files
    ```

    Example output:

    ```
    csm1.0 (active)
    csm1.2
    csm1.2.bak
    initial
    initial.bak
    Active configuration: csm1.0
    Unsaved changes : yes
    ```
