# Collect MAC Addresses for NCNs

## Topics

1. [Set up networking](#1-set-up-networking)
2. [Collect MAC addresses](#2-collect-mac-addresses)

## 1. Set up networking

This assumes that the HMN is not setup on the PIT node; these steps cater to bare-metal and configured switches.

1. (`pit#`) Change into the preparation directory.

   > **`NOTE`** If `PITDATA` is not defined, then see [Set reusable environment variables](pre-installation.md#15-set-reusable-environment-variables).

   ```bash
   cd ${PITDATA}/prep
   ```

1. (`pit#`) Confirm that the `ncn_metadata.csv` file in this directory has the new information.

   > **NOTE** If the file is missing, then generate the file by following
   > [Generate topology files](pre-installation.md#32-generate-topology-files) after the
   > other steps in [Create system configuration](pre-installation.md#3-create-system-configuration).

   ```bash
   cat ncn_metadata.csv
   ```

1. (`pit#`) Set up the management network if it does not already exist.

   > **NOTE** This network will be overwritten when `/root/bin/pit-init.sh` is invoked during [Initialize the LiveCD](pre-installation.md#36-initialize-the-livecd).

   - Set up the `bond`:

      ```bash
      # NOTE: REplace p801p1 and p802p2 with the interfaces from system_config.yaml#install-ncn-bond-members, e.g. the interfaces the PIT is using as the bond. 
      /root/bin/csi-setup-bond0.sh 10.1.1.1/16 p801p1 p801p2
      ```

   - Set up the MTL DHCP

      ```bash
      csi-pxe-bond0.sh 10.1.1.1 10.1.2.1 10.1.255.254 10m
      ```

   - **If** the switches are already configured with an HMN (i.e. this is not a bare-metal installation), then set the HMN up:

      ```bash
      vlanid=4
      /root/bin/csi-setup-hmn.sh 10.254.1.1/17 $vlanid
      /root/bin/csi-pxe-hmn.sh 10.254.1.1 10.254.2.1 10.254.127.254 10m
      ```

## 2. Collect MAC addresses

1. See [Collecting NCN MAC Addresses](collecting_ncn_mac_addresses.md).

1. Return to [Generate topology files](pre-installation.md#33-customize-system_configyaml).
