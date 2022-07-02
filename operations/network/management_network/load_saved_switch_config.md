# Load Saved Switch Configuration

This procedure shows how to switch between already saved switch configurations.

To save switch configurations, refer to the [Configuration Management](config_management.md) procedure.

This procedure is intended for internal use only. It is used to quickly switch between configurations that are already loaded on the switches.

This procedure needs to be done on all management switches.

- Spine switches will have three total configuration files/checkpoints.
  - 1.2 fresh install
  - 1.2 upgrade
  - 1.0

- Leaf-BMC switches will have have two configuration files/checkpoints.
  - 1.2
  - 1.0

## Aruba

1. (`sw#`) Ensure that the proper checkpoint files exist. `CSM1_0_CANU_1_2_4` and `CSM1_2_UPGRADE_CANU_1_3_2` are used in this example.

    Example:

    ```text
    show checkpoint | include CSM
    CSM1_2_FRESH_INSTALL_CANU_1_3_2                     latest      User    2022-04-01T20:11:57Z  GL.10.09.0010
    CSM1_2_UPGRADE_CANU_1_3_2                           checkpoint  User    2022-04-01T18:57:06Z  GL.10.09.0010
    CSM1_0_CANU_1_2_4                                   checkpoint  User    2022-03-15T21:37:11Z  GL.10.09.0010
    ```

1. (`sw#`) Rollback to desired checkpoint.

    ```text
    checkpoint rollback CSM1_2_UPGRADE_CANU_1_3_2
    ```

1. (`sw#`) In some rare cases ACLs will not work as expected, to prevent this the following command should be entered after switching checkpoints.

    ```text
    access-list all reset
    ```

## Dell

1. (`sw#`) Ensure that the proper configuration files exist. `CSM1_0` and `CSM1_2` are used in this example.

    ```text
    dir config
    ```

    Example output:

    ```text
    Directory contents for folder: config
    Date (modified)        Size (bytes)  Name
    ---------------------  ------------  ------------------------------------------
    2022-02-08T16:31:42Z   112189        csm1.0.xml
    2022-02-08T16:28:31Z   112189        csm1.2.xml
    2022-02-08T16:30:23Z   112189        startup.xml
    ```

1. (`sw#`) Copy the desired configuration to the startup configuration.

    ```text
    copy config://csm1.0.xml config://startup.xml
    ```

    `Copy completed` will be returned if successful.

1. (`sw#`) Reboot the switch without saving configuration.

    ```text
    reload
    System configuration has been modified. Save? [yes/no]:no
    ```

## Mellanox

1. (`sw#`) View the configuration files.

    Ensure that the proper backup configuration exists. `CSM1_0` and `CSM1_2` are used in this example.

    ```text
    show configuration files
    ```

    Example output:

    ```text
    show configuration files

    csm1.0.canu1.1.21 (active)
    csm1.0.canu1.1.21.bak
    csm1.2.fresh_install_canu1.1.21
    csm1.2.fresh_install_canu1.1.21.bak
    csm1.2.upgrade_canu1.1.21
    csm1.2.upgrade_canu1.1.21.bak
    initial
    initial.bak

    Active configuration: csm1.0.canu1.1.21
    Unsaved changes     : yes
    ```

1. (`sw#`) Switch to desired configuration.

    ```text
    configuration switch-to csm1.2.upgrade_canu1.1.21
    ```

    Example output:

    ```text
    This requires a reboot.
    Type 'yes' to confirm: yes
    ```

    The switch will then reboot to chosen configuration.
