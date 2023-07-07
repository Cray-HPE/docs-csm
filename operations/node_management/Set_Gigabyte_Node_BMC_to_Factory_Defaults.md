# Set Gigabyte Node BMC to Factory Defaults

There are cases when a Gigabyte node BMC must be reset to its factory default settings. This page describes when this reset is appropriate, and
how to use management scripts and text files to do the reset.

Set the BMC to the factory default settings in the following cases:

- There are problems using the `ipmitool` command and Redfish does not respond.
- There are problems using the `ipmitool` command and Redfish is running.
- When BIOS or BMC flash procedures fail using Redfish.

## Procedure

**This section refers to scripts that exist only in the PIT environment.** If necessary, copy the LiveCD data from a different machine to get these scripts.

**Note**: When BIOS or BMC flash procedures fail using Redfish:

- Run the `do_bmc_factory_default.sh` script
- Run `ipmitool -I lanplus -U admin -P password -H BMC_or_CMC_IP mc reset cold` and flash it again after five minutes.

If booted from the PIT node:

- The firmware packages are located in the HPE Cray EX HPC Firmware Pack (HFP) provided with the Shasta release.
- The required scripts are located in `/var/www/fw/river/sh-svr-scripts`

1. Create a `node.txt` file and add the target node information as shown:

    Example `node.txt` file with two nodes:

    ```text
    10.254.1.11 x3000c0s9b0 ncn-w002
    10.254.1.21 x3000c0s27b0 uan01
    ```

   Example `node.txt` file with one node:

    ```text
    10.254.1.11 x3000c0s9b0 ncn-w002
    ```

1. (`ncn#`) Use Redfish to reset the BMC to factory default.

    - **Option 1:** If the BMC is running version `12.84.01` or later, then run:

        ```bash
        sh do_Redfish_BMC_Factory.sh
        ```

    - **Option 2:** Use `ipmitool` to reset the BMC to factory defaults:

        ```bash
        sh do_bmc_factory_default.sh
        ```

    - **Option 3:** Use the power control script:

        ```bash
        sh do_bmc_power_control.sh raw 0x32 0x66
        ```

        (`raw 0x32 0x66` are Gigabyte/AMI vendor-specific IPMI commands to reset to factory defaults.)

1. (`ncn#`) Wait five minutes (300 seconds) for the BMC and Redfish to initialize.

    ```bash
    sleep 300
    ```

1. (`ncn#`) Add the default login and password to the BMC.

    ```bash
    sh do_bmc_root_account.sh
    ```

1. (`ncn#`) Add the default login and password to Redfish.

    **IMPORTANT:** If the BMC is version `12.84.01` or later, then **skip this step**.

    ```bash
    sh do_Redfish_credentials.sh
    ```

1. (`ncn#`) Make sure the BMC is not in failover mode.

    Run the script with the `read` option to check the BMC status:

    ```bash
    sh do_bmc_change_mode_to_manual.sh read
    ```

    Example output:

    ```text
    ---------------------------------------------------
    [ BMC: 172.30.48.33 ]
    => Manual mode (O)
    ```

    The BMC is in failover mode if the previous command includes output similar to the following:

    ```text
    [ BMC: 172.30.48.33 ]
    ==> Failover mode (X) <==
    ```

    If the BMC is in failover mode, then change the BMC back to manual mode:

    ```bash
    sh do_bmc_change_mode_to_manual.sh change
    ```

1. If the BMC is in a booted management NCN running Shasta v1.3 or later, then reapply the static IP address and clear the DHCP address from HSM/KEA.

    Determine the MAC address in HSM for the DHCP address for the BMC, delete it from HSM, and restart KEA.

1. Reboot or power cycle the target nodes.

1. (`ncn#`) After the BMC is reset to factory defaults, wait 300 seconds for BMC and Redfish initialization.

    ```bash
    sleep 300
    ```

1. (`ncn#`) Add the default login and password to the BMC.

    ```bash
    sh do_bmc_root_account.sh
    ```
