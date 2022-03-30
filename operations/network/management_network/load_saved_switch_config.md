# Load Saved Switch Configuration

This procedures shows how to switch between saved switch configurations.

To save switch configurations, refer to the [Configuration Management](config_management.md) procedure.

### Aruba

1. View the checkpoints. 
   
    Ensure that `CSM1_0` and `CSM1_2` exist. If they exist, proceed to the next step.

    ```
    sw-spine-001# show checkpoint
    ```

    Example output:

    ```
    NAME TYPE WRITER DATE(YYYY/MM/DD) IMAGE VERSION
    CSM1_0 latest User 2022-01-13T16:51:37Z GL.10.08.1021
    CSM1_2 latest User 2022-01-13T16:51:48Z GL.10.08.1021
    startup-config startup User 2021-12-20T17:35:58Z GL.10.08.1021
    ```

2. Rollback to desired checkpoint.

    ```
    sw-spine-001# checkpoint rollback CSM1_0
    ```

### Dell

1. View the configuration files.
   
    Ensure that `csm1.0` and `csm1.2` exist. If they exist, proceed to the next step.

    ```
    sw-leaf-001# dir config
    ```

    Example output:

    ```
    Directory contents for folder: config
    Date (modified)        Size (bytes)  Name
    ---------------------  ------------  ------------------------------------------
    2022-02-08T16:31:42Z   112189        csm1.0.xml
    2022-02-08T16:28:31Z   112189        csm1.2.xml
    2022-02-08T16:30:23Z   112189        startup.xml
    ```

2. Copy the desired configuration to the startup configuration.

    ```
    sw-leaf-001# copy config://csm1.0.xml config://startup.xml
    ```

    `Copy completed` will be returned if successful.

3. Reboot the switch without saving configuration.
    
    ```
    sw-leaf-001# reload
    System configuration has been modified. Save? [yes/no]:no
    ```

### Mellanox

1. View the configuration files.
   
    Ensure that `csm1.0` and `csm1.2` exist. If they exist, proceed to the next step.

    ```
    sw-spine-001 [standalone: master] (config) # show configuration files
    ```

    Example output:

    ```
    csm1.0 (active)
    csm1.0.bak
    csm1.2
    csm1.2.bak
    initial
    initial.bak

    Active configuration: csm1.0
    Unsaved changes     : yes
    ```

2. Switch to desired configuration.

    ```
    sw-spine-001 [standalone: master] (config) # configuration switch-to csm1.0
    ```

    Example output:

    ```
    This requires a reboot.
    Type 'yes' to confirm: yes
    ```

The switch will then reboot to chosen configuration.
