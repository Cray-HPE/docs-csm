# Save a Configuration

## Write Memory

To keep track of what configuration version is running on the switch, create a new configuration file using the `CSN version` and the `CANU version` from the MOTD banner from the running config.

### Mellanox

1. Get the CSM and CANU versions from the MOTD banner.

    ```
    sw-spine-001 [mlag-domain: master] (config) # show banner
    ```

    Example output:

    ```
    Banners:
      Message of the Day (MOTD):

        ###############################################################################
        # CSM version:  1.0
        # CANU version: 1.1.11
        ###############################################################################
    ```

1. Save a configuration file with the CSM and CANU versions.

    ```
    sw-spine-001 [mlag-domain: master] (config) # configuration write to csm1.0-canu1.1.11
    ```

### Dell

1. Get the CSM and CANU version from the MOTD banner.

    ```
    sw-leaf-bmc-001# show running-configuration | grep motd
    ```

    Example output:

    ```
    banner motd ^C
    ###############################################################################
    # CSM version:  1.0
    # CANU version: 1.1.11
    ###############################################################################
    ```

1. Create a configuration file with the CSM/CANU versions.

    ```
    sw-leaf-bmc-001(config)# copy config://startup.xml config://csm1.0-canu1.1.11
    ```

    `Copy completed` will be returned if successful.

### Aruba

1. Get the CSM and CANU versions from the EXEC banner.

    ```
    sw-leaf-bmc-001(config)# show banner exec

    ```

    Example output:

    ```
    ###############################################################################
    # CSM version:  1.2
    # CANU version: 1.1.11
    ###############################################################################
    ```

1. Create a checkpoint with the CSM/CANU versions.

    ```
    sw-leaf-bmc-001(config)# copy running-config checkpoint CSM1_2_CANU_1_1_11
    ```
