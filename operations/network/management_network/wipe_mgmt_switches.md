# Wipe Management Switch Config

This procedure describes how to wipe Aruba, Dell, and Mellanox switch configurations.

## Prerequisites

Out-of-band access to the switches (console)

## Aruba

1. Create a checkpoint before erasing the switch configuration.

   More information related to backing up configuration can be found on the [Configuration Management](config_management.md) procedure.

   ```
   sw-spine-001# copy running-config checkpoint CSM1_0
   ```

1. Verify the checkpoint was created.

   ```
   sw-spine-001# show checkpoint
   ```

   Example output:

   ```
   NAME                         TYPE        WRITER  DATE(YYYY/MM/DD)      IMAGE VERSION
   CSM1_0                       latest      User    2022-01-27T18:52:31Z  GL.10.08.1021
   ```

1. Erase the startup configuration.

   ```
   sw-spine-002# erase startup-config
   Erase checkpoint startup-config ? (y/n): y
   ```

1. Reboot after erasing the startup configuration.

   ```
   sw-spine-001# boot system
   Checking if the configuration needs to be saved...

   Do you want to save the current configuration (y/n)? n
   ```

   The switch will reboot without any configuration.

   The default user is `admin` without any password.

1. Follow the [Apply Switch Configs](apply_switch_configs.md) procedure.

## Dell

1. Save startup configuration to a new XML configuration file.

   ```
   sw-leaf-bmc-001# copy config://startup.xml config://csm1.2.xml
   ```

1. Erase the startup configuration.

   ```
   sw-leaf-bmc-001# delete startup-configuration
   Proceed to delete startup-configuration [confirm yes/no(default)]:yes
   ```

1. Reboot after erasing the startup configuration.

   ```
   sw-leaf-bmc-001# reload
   System configuration has been modified. Save? [yes/no]:no
   Continuing without saving system configuration
   Proceed to reboot the system? [confirm yes/no]:yes
   ```

   The default username and password are `admin`.
   This will boot the switch to factory defaults.

1. Follow the [Apply Switch Configs](apply_switch_configs.md) procedure.

## Mellanox

1. Create a new configuration file.

   When a new configuration file is created, no data is written to it. We will boot to this new, blank configuration file.

   ```
   (config) # configuration new csm1.2
   ```

   If that configuration exists already, delete it with `configuration delete csm1.2`, or reset to factory defaults with `reset factory`.

1. Check that the configuration files contain the new `csm1.2` blank configuration that was just created.

   ```
   (config) # show configuration files
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

1. Switch to the new configuration, which requires a reboot.

   ```
   (config) # configuration switch-to csm1.2
   This requires a reboot.
   Type 'yes' to confirm: yes
   ```

   The default username and password are `admin`

1. Follow the prompts as shown below.

   ```
   NVIDIA Switch


   Configuration wizard

   Do you want to use the wizard for initial configuration?
   Please answer 'yes' or 'no'.
   Do you want to use the wizard for initial configuration? no

   Enable password hardening: [yes] no

   New password for 'admin' account must be typed, please enter new password:
   Confirm:
   New password for 'monitor' account must be typed, please enter new password:
   Confirm:
   ```
