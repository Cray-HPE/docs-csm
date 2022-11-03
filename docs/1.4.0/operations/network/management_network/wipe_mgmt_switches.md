# Wipe Management Switch Configuration

This procedure describes how to wipe Aruba, Dell, and Mellanox switch configurations.

## Prerequisites

Out-of-band access to the switches (console)

## Aruba

1. (`sw-spine-001#`) Create a checkpoint before erasing the switch configuration.

   More information related to backing up configuration can be found on the [Configuration Management](config_management.md) procedure.

   ```bash
   copy running-config checkpoint CSM1_0
   ```

1. (`sw-spine-001#`)Verify the checkpoint was created.

   ```console
   show checkpoint
   ```

   Example output:

     ```console
     NAME                         TYPE        WRITER  DATE(YYYY/MM/DD)      IMAGE VERSION
     CSM1_0                       latest      User    2022-01-27T18:52:31Z  GL.10.08.1021
     ```

1. (`sw-spine-002#`) Erase the startup configuration.

   - Invoke the purge:

      ```bash
      erase startup-config
      ```

   - Answer `y` to the prompt:

      ```text
      Erase checkpoint startup-config ? (y/n): y
      ```

1. (`sw-spine-001#`) Reboot after erasing the startup configuration.

   - Invoke the reboot:

      ```bash
      boot system   
      ```

   - Answer `n` to the prompt:

      ```text
      Checking if the configuration needs to be saved...

      Do you want to save the current configuration (y/n)? n
      ```

   - This will boot the switch to factory defaults.

   > **`NOTE`** The default user is `admin` without any password.

1. See [Apply Switch Configurations](apply_switch_configurations.md).

## Dell

1. (`sw-leaf-bmc-001#`) Save startup configuration to a new XML configuration file.

   ```bash
   copy config://startup.xml config://csm1.2.xml
   ```

1. (`sw-leaf-bmc-001#`) Erase the startup configuration.

   - Invoke the purge:

      ```bash
      delete startup-configuration
      ```

   - Answer `yes` to the prompt:

      ```text
      Proceed to delete startup-configuration [confirm yes/no(default)]:yes
      ```

1. (``) Reboot after erasing the startup configuration.

   - Invoke the reboot:

      ```bash
      reload
      ```

   - Answer `no` and then answer `yes` on the following prompts:

      ```text
      System configuration has been modified. Save? [yes/no]:no
      Continuing without saving system configuration
      Proceed to reboot the system? [confirm yes/no]:yes
      ```

   - This will boot the switch to factory defaults.

   > **`NOTE`** The default username and password are `admin`.

1. See [Apply Switch Configurations](apply_switch_configurations.md) procedure.

## Mellanox

1. (`(config)`) Create a new configuration file.

   When a new configuration file is created, no data is written to it. We will boot to this new, blank configuration file.

   ```bash
   configuration new csm1.2
   ```

   > **`NOTE`** If that configuration exists already, delete it with `configuration delete csm1.2`, or reset to factory defaults with `reset factory`.

1. (`(config)`) Check that the configuration files contain the new `csm1.2` blank configuration that was just created.

   ```bash
   show configuration files
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

1. (`(config)`) Switch to the new configuration, which requires a reboot.

   - Invoke the switch

      ```bash
      configuration switch-to csm1.2
      ```

   - Answer `yes` to the prompt:

      ```text
      This requires a reboot.
      Type 'yes' to confirm: yes
      ```

   > **`NOTE`** The default username and password are `admin`

1. Follow the prompts as shown below.

   - Answer `no` to using the wizard:

      ```text
      NVIDIA Switch

      Configuration wizard

      Do you want to use the wizard for initial configuration?
      Please answer 'yes' or 'no'.
      Do you want to use the wizard for initial configuration? no
      ```

   - Answer `no` to password hardening:

      ```text
      Enable password hardening: [yes] no
      ```

   - Fill in the new password:

      ```text
      New password for 'admin' account must be typed, please enter new password:
      Confirm:
      New password for 'monitor' account must be typed, please enter new password:
      Confirm:
      ```
