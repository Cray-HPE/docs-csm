# Collect MAC Addresses for NCNs

## Topics

1. [Setup Networking](#1-set-up-networking)
2. [Collect MAC Addresses](#2-collect-mac-addresses)

## 1. Set up Networking

This assumes that the HMN is not setup on the PIT node, and these steps cater to bare-metal and configured switches.

1. (`pit#`) Change into the preparation directory.

   > **`NOTE`** If `PITDATA` is not defined, see [set reusable environment variables](./pre-installation.md#set-reusable-environment-variables).

   ```bash
   cd ${PITDATA}/prep
   ```

1. (`pit#`) Confirm that the `ncn_metadata.csv` file in this directory has the new information.

   > **`NOTE`** If the file is missing, please generate the file by following 
   > [Generate Topology Files](./pre-installation.md#generate-topology-files) after the 
   > other steps in [create system configuration](./pre-installation.md#3-create-system-configuration).

   ```bash
   cat ncn_metadata.csv
   ```

1. (`pit#`) Set up the management network if it does not already exist.

   > **`NOTE`** This network will be overwritten when `/root/bin/pit-init.sh` is invoked during [initialize the LiveCD](./pre-installation.md#initialize-the-livecd).

   - Set up the bond:

      ```bash
      # NOTE: REplace p801p1 and p802p2 with the interfaces from system_config.yaml#install-ncn-bond-members, e.g. the interfaces the PIT is using as the bond. 
      /root/bin/csi-setup-bond0.sh 10.1.1.1/16 p801p1 p801p2
      ```

   - Set up the MTL DHCP

      ```bash
      csi-pxe-bond0.sh 10.1.1.1 10.1.2.1 10.1.255.254 10m
      ```

   - **If** the switches are already configured with an HMN (e.g. this is not a bare-metal installation) then set the HMN up:

      ```bash
      vlanid=4
      /root/bin/csi-setup-hmn.sh 10.254.1.1/17 $vlanid
      /root/bin/csi-pxe-hmn.sh 10.254.1.1 10.254.2.1 10.254.127.254 10m
      ```

## 2. Collect MAC Addresses

1. See [collecting BMC MAC Addresses](./collecting_bmc_mac_addresses.md).

1. See [collecting NCN MAC Addresses](./collecting_ncn_mac_addresses.md).

1. Return to [generate topology files](./pre-installation.md#customize-system_configyaml).
