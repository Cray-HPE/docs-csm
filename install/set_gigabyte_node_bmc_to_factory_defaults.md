# Set Gigabyte Node BMC to Factory Defaults

## Prerequisites

**Note**: This section refers to scripts that exist only in the PIT environment. If necessary, copy the LiveCD data from a different machine to get these scripts.

Use the management scripts and text files to reset Gigabyte BMC to factory default settings. Set the BMC to the factory default settings in the following cases:

- There are problems using the `ipmitool` command and Redfish does not respond
- There are problems using the `ipmitool` command and Redfish is running
- When BIOS or BMC flash procedures fail using Redfish
  - Run the `do_bmc_factory_default.sh` script
  - Run `ipmitool -I lanplus -U admin -P password -H BMC_or_CMC_IP mc reset cold` and flash it again after 5 minutes seconds
- If booted from the PIT node:
  - the firmware packages are located in the HFP package provided with the Shasta release
  - the required scripts are located in `/var/www/fw/river/sh-svr-scripts`

## Procedure

### Apply the BMC Factory Command

1. Create a `node.txt` file and add the target node information as shown:

    Example `node.txt` file with two nodes:

    ```screen
    10.254.1.11 x3000c0s9b0 ncn-w002
    10.254.1.21 x3000c0s27b0 uan01
    ```

    Example `node.txt` file with one node:

    ```screen
    10.254.1.11 x3000c0s9b0 ncn-w002
    ```

2. Use Redfish to reset the BMC to factory default, the BMC is running 12.84.01 or later version, run:

      ```bash
      ncn-w001# sh do_Redfish_BMC_Factory.sh
      ```

   - Alternatively, use `ipmitool` to reset the BMC to factory defaults:

      ```bash
      ncn-w001# sh do_bmc_factory_default.sh
      ```

   - Alternatively, use the power control script:

      ```bash
      ncn-w001# sh do_bmc_power_control.sh raw 0x32 0x66
      ```

3. After the BMC has been reset to factory defaults, wait five minutes for BMC and Redfish initialization.

   ```bash
   ncn-w001# sleep 300
   ```

4. Add the default login/password to the BMC.

   ```bash
   ncn-w001# ncn-w001# sh do_bmc_root_account.sh
   ```

5. If BMC is version 12.84.01 or later, skip this step. Otherwise, add the default login/password to Redfish.

   ```bash
   ncn-w001# sh do_Redfish_credentials.sh
   ```

6. Make sure the BMC is not in failover mode. Run the script with the `read` option to check the BMC status:

   ```bash
   ncn-w001# sh do_bmc_change_mode_to_manual.sh read
   ---------------------------------------------------
   [ BMC: 172.30.48.33 ]
   => Manual mode (O)
   ```

   If the BMC displays `Failover mode`:

   ```bash
   [ BMC: 172.30.48.33 ]
   ==> Failover mode (X) <==
   ```

   Change the BMC back to manual mode.

   ```bash
   ncn-w001# sh do_bmc_change_mode_to_manual.sh change
   ```

7. If the BMC is in a booted management NCN running v1.4+ or v1.3, reapply the static IP address and clear the DHCP address from HSM/KEA.

   Determine the MAC address in HSM for the DHCP address for the BMC, then delete it from HSM and restart KEA.

8. Reboot or power cycle the target nodes.

9. After the CMC is reset to factory defaults, wait 300 seconds for CMC and Redfish initialization, then add the default login/password to the CMC.

   ```bash
   ncn-w001# sleep 300
   ncn-w001# sh do_bmc_root_account.sh
   ```
