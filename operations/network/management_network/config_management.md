# Configuration Management

This page is designed for:

- Showing users how initially save switch configurations so they can be used again.
- Switching between saved configurations.

> **CAUTION** All of these steps should be done using an out of band connection. This process is disruptive and will require downtime.

All this information can be found in the switch user guides, available from the specific switch manufacturer.

## Prerequisites

It is recommended to do a `show run` on each switch and save that configuration before attempting the following procedures.

## Aruba

### Change configuration

Maximum number of checkpoints:

1. Maximum checkpoints: 64 (including the startup configuration)
1. Maximum user checkpoints: 32
1. Maximum system checkpoints: 32

#### Save the current configuration into a checkpoint

> This needs be done when in both `CSM1.0` and `CSM1.2`

1. (`sw(config)#`) Save the configuration to a checkpoint.

    ```console
    copy running-config checkpoint CSM1_0
    ```

    Example output:

    ```text
    Note: checkpoint name with special characters not allowed (only
    alphanumeric, hyphen, and underscore are allowed)
    ```

1. (`sw(config)#`) Check on the saved checkpoints.

    ```console
    show checkpoint
    ```

    Example output:

    ```text
    NAME TYPE WRITER DATE(YYYY/MM/DD) IMAGE VERSION
    CSM1_0 latest User 2022-01-13T16:51:37Z GL.10.08.1021
    CSM1_2 latest User 2022-01-13T16:51:48Z GL.10.08.1021
    startup-config startup User 2021-12-20T17:35:58Z GL.10.08.1021
    ```

1. Copying the existing checkpoint point to the startup configuration to switch between CSM 1.0 and CSM 1.2 configuration.

   1. (`sw(config)#`) Copying the checkpoint to startup:

      ```console
      copy checkpoint CSM1_2 startup-config
      ```

   1. (`sw(config)#`) Boot the system to start with configuration from different CSM version.

      ```console
      boot system
      ```

The switch will now boot to the desired configuration.

## Dell

### Save the configuration file from running system

> This is done when going from one CSM release to the other for the first time

This should only need to be done once (unless hardware is added or PoR configuration has changed). Once this configuration file has been saved, the administrator should be able to switch between the two configuration files.

The following example is a 1.0 system that is going to 1.2.

1. (`sw(config)#`) Save the startup configuration to new XML configuration.

   ```console
   copy config://startup.xml config://csm1.0.xml
   ```

1. (`sw(config)#`) Erase the startup configuration and reboot.

   1. Erase the startup configuration.

      ```console
      delete startup-configuration
      ```

      Example output:

      ```text
      Proceed to delete startup-configuration [confirm yes/no(default)]:yes
      ```

   1. Reboot after erasing the configuration.

      ```console
      reload
      ```

      Example output:

      ```text
      System configuration has been modified. Save? [yes/no]:no
      Continuing without saving system configuration
      Proceed to reboot the system? [confirm yes/no]:yes
      ```

      This will boot the switch to factory defaults.

1. Paste in the new CANU-generated configuration once the switch boots into the factory defaults.

1. (`sw(config)#`) Save the configuration.

   ```console
   do write memory
   copy config://startup.xml config://csm1.2.xml
   ```

   `Copy completed` will be returned if successful.

1. (`sw(config)#`) Verify that both configurations exist.

   ```console
   dir config
   ```

   Example output:

   ```text
   Directory contents for folder: config
   Date (modified) Size (bytes) Name
   --------------------- ------------
   ------------------------------------------
   2022-01-12T22:21:35Z 53441 csm1.0.xml
   2022-01-12T22:34:03Z 97654 csm1.2.xml
   2022-01-12T22:33:47Z 97654 startup.xml
   ```

### Reload the switch to a different CSM version configuration

This process should be used when configuration files for the desired CSM version are currently on the switch.

The following example shows going from CSM 1.2 to CSM 1.0 switch configuration.

1. (`sw(config)#`) View the current switch configuration files.

    ```console
    dir config
    ```

    Example output:

    ```text
    Directory contents for folder: config
    Date (modified) Size (bytes) Name
    --------------------- ------------
    ------------------------------------------
    2022-01-12T22:21:35Z 53441 csm1.0.xml
    2022-01-12T22:34:03Z 97654 csm1.2.xml
    2022-01-12T22:40:58Z 53441 startup.xml
    ```

1. (`sw(config)#`) Copy the desired switch configuration to the startup configuration and reload.

    ```console
    copy config://csm1.0.xml config://startup.xml
    reload
    ```

    When prompted `System configuration has been modified. Save?`, enter `no`.

The switch will then boot to the desired configuration.

## Mellanox

### Save a configuration file from running system

> This is done when going from one CSM release to the other for the first time

This should only need to be done once (unless hardware is added or PoR configuration has changed). Once this configuration file has been saved, the administrator should be able to switch between the two configuration files.

The following example is a 1.0 system that is going to 1.2.

1. (`sw(config)#`) Write the current configuration to a file. This copies the current running configuration to a binary configuration file.

    ```console
    configuration write to csm1.0
    ```

1. (`sw(config)#`) Verify the new configuration file was created.

    ```console
    show configuration
    ```

    Example output:

    ```text
    files
    csm1.0 (active)
    initial
    initial.bak
    Active configuration: csm1.0
    Unsaved changes : no
    ```

1. (`sw(config)#`) Create a new configuration file for CSM 1.2.

    When a new configuration file is created, no data is written to it. The administrator will boot to this new configuration file and paste the CANU-generated configuration to it.

    ```console
    configuration new csm1.2
    ```

1. (`sw(config)#`) Check that the configuration files contain the new `csm1.2` blank configuration that was just created.

    ```console
    show configuration
    ```

    Example output:

    ```text
    files
    csm1.0 (active)
    csm1.2
    initial
    initial.bak
    Active configuration: csm1.0
    Unsaved changes : no
    ```

1. (`sw(config)#`) Switch to the new configuration, which requires a reboot.

    ```console
    configuration switch-to csm1.2
    ```

    Example output:

    ```text
    This requires a reboot.
    Type 'yes' to confirm:
    ```

    Enter `yes` in response to the prompt.

1. (`sw(config)#`) Once the switch is rebooted, verify the configuration file is correct. It should reboot without any configuration.

    ```console
    show configuration files
    ```

    Example output:

    ```text
    csm1.0
    csm1.2 (active)
    initial
    initial.bak
    Active configuration: csm1.2
    Unsaved changes : yes
    ```

1. Paste in the new CANU-generated 1.2 configuration.

1. (`sw(config)#`) Save the configuration.

    ```console
    write memory
    ```

### Reload a switch to a different CSM version configuration

This process should be used when configuration files for the desired CSM version are currently on the switch.

In the following example, the switch configuration will go from CSM 1.2 to CSM 1.0.

1. (`sw(config)#`) Verify that the correct configuration file exists on the switch.

    ```console
    show configuration files
    ```

    Example output:

    ```text
    csm1.0
    csm1.2 (active)
    csm1.2.bak
    initial
    initial.bak
    Active configuration: csm1.2
    Unsaved changes : no
    ```

1. (`sw(config)#`) Switch to desired configuration version, which requires a reboot.

    ```console
    configuration switch-to csm1.0
    ```

    Example output:

    ```text
    This requires a reboot.
    Type 'yes' to confirm:
    ```

    Enter `yes` in response to the prompt.

    The switch should boot to the configuration version typed in the previous command.

1. (`sw(config)#`) Verify the configuration version after the switch is booted.

    ```console
    show configuration files
    ```

    Example output:

    ```text
    csm1.0 (active)
    csm1.2
    csm1.2.bak
    initial
    initial.bak
    Active configuration: csm1.0
    Unsaved changes : yes
    ```
