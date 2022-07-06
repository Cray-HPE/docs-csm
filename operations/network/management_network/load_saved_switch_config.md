# Load Saved Switch Configuration

> This procedure is intended for internal use only.

This procedure switches between already saved switch configurations. It is used to quickly switch between configurations that are already loaded on the switches.

To save switch configurations, refer to the [Configuration Management](config_management.md) procedure.

When switching between configurations, the procedure must be followed on all management switches.

- Spine switches have three total configuration files/checkpoints.
  - 1.2 fresh install
  - 1.2 upgrade
  - 1.0

- Leaf-BMC switches have have two configuration files/checkpoints.
  - 1.2
  - 1.0

The procedure depends on the switch manufacturer:

- [Aruba](#aruba)
- [Dell](#dell)
- [Mellanox](#mellanox)

## Aruba

1. (`sw#`) List the checkpoint files.

    Ensure that the proper checkpoint files exist.

    ```text
    show checkpoint | include CSM
    ```

    Example output:

    ```text
    CSM1_2_FRESH_INSTALL_CANU_1_3_2                     latest      User    2022-04-01T20:11:57Z  GL.10.09.0010
    CSM1_2_UPGRADE_CANU_1_3_2                           checkpoint  User    2022-04-01T18:57:06Z  GL.10.09.0010
    CSM1_0_CANU_1_2_4                                   checkpoint  User    2022-03-15T21:37:11Z  GL.10.09.0010
    ```

1. (`sw#`) Rollback to desired checkpoint.

    ```text
    checkpoint rollback CSM1_2_UPGRADE_CANU_1_3_2
    ```

1. (`sw#`) Reset ACLs.

    In some rare cases, ACLs will not work as expected. In order to prevent this, run the following command after switching checkpoints.

    ```text
    access-list all reset
    ```

## Dell

1. (`sw#`) List the configuration files.

    Ensure that the proper configuration files exist.

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
    ```

    Example output:

    ```text
    System configuration has been modified. Save? [yes/no]:no
    ```

## Mellanox

1. (`sw#`) View the configuration files.

    Ensure that the proper backup configurations exist.

    ```text
    show configuration files
    ```

    Example output:

    ```text
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

1. (`sw#`) Switch to the desired configuration.

    ```text
    configuration switch-to csm1.2.upgrade_canu1.1.21
    ```

    Example output:

    ```text
    This requires a reboot.
    Type 'yes' to confirm: yes
    ```

    The switch will then reboot to chosen configuration.
