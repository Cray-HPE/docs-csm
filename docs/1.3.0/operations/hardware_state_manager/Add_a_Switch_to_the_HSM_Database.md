# Add a Switch to the HSM Database

Manually add a switch to the Hardware State Manager \(HSM\) database. Switches need to be in the HSM database in order to update their firmware with the Firmware Action Service \(FAS\).

## Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray CLI](../configure_cray_cli.md).
- The component name (xname), IP address, user name, and password are known for the switch being added.

## Procedure

1. (`ncn-mw#`) Add the switch to the HSM database.

    The `--rediscover-on-update true` flag forces HSM to discover the switch.

    ```bash
    cray hsm inventory redfishEndpoints create --id XNAME --fqdn IP_ADDRESS --user USERNAME \
        --password PASSWORD --rediscover-on-update true --format toml
    ```

    Example output:

    ```toml
    [[results]]
    URI = "/hsm/v2/Inventory/RedfishEndpoints/x3000c0r41b0"
    ```

1. (`ncn-mw#`) Verify that HSM successfully discovered the switch.

    ```bash
    cray hsm inventory redfishEndpoints list --id XNAME --format toml
    ```

    Example output:

    ```toml
    [[RedfishEndpoints]]
    Domain = ""
    RediscoverOnUpdate = true
    Hostname = "10.254.2.17"
    Enabled = true
    FQDN = "10.254.2.17"
    User = "root"
    Password = ""
    Type = "RouterBMC"
    ID = "x3000c0r41b0"

    [RedfishEndpoints.DiscoveryInfo]
    LastDiscoveryAttempt = "2020-02-05T18:41:08.823059Z"
    RedfishVersion = "1.2.0"
    LastDiscoveryStatus = "DiscoverOK"
    ```

The switch is now discovered by the HSM.
