# Save A Configuration

To keep track of what configuration version is running on the switch, create a new configuration file using the
CSM version and the CANU version from the MOTD banner from the running configuration.

## Mellanox

1. (`switch#`) Get the CSM and CANU versions from the MOTD banner.

    ```console
    show banner
    ```

    Example output:

    ```text
    Banners:
      Message of the Day (MOTD):

        ###############################################################################
        # CSM version:  1.0
        # CANU version: 1.1.11
        ###############################################################################
    ```

1. (`switch#`) Save a configuration file with the CSM and CANU versions.

    ```console
    configuration write to csm1.0-canu1.1.11
    ```

## Dell

1. (`switch#`) Get the CSM and CANU version from the MOTD banner.

    ```console
    show running-configuration | grep motd
    ```

    Example output:

    ```text
    banner motd ^C
    ###############################################################################
    # CSM version:  1.0
    # CANU version: 1.1.11
    ###############################################################################
    ```

1. (`switch#`) Create a configuration file with the CSM and CANU versions.

    ```console
    copy config://startup.xml config://csm1.0-canu1.1.11
    ```

    `Copy completed` will be returned if successful.

## Aruba

1. (`switch#`) Get the CSM and CANU versions from the `exec` banner.

    ```console
    show banner exec
    ```

    Example output:

    ```text
    ###############################################################################
    # CSM version:  1.2
    # CANU version: 1.1.11
    ###############################################################################
    ```

1. (`switch#`) Create a checkpoint with the CSM and CANU versions.

    ```console
    copy running-config checkpoint CSM1_2_CANU_1_1_11
    ```
