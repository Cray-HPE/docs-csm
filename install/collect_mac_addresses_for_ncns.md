# Collect MAC Addresses for NCNs  

Now that the PIT node has been booted with the LiveCD and the management network switches have been configured,
the actual MAC address for the management nodes can be collected. This process will include repetition of some 
of the steps done up to this point because `csi config init` will need to be run with the proper
MAC addresses and some services will need to be restarted.

**Note**: If a reinstall of this software release is being done on this system and the `ncn_metadata.csv` 
file already had valid MAC addresses for both BMC and node interfaces before `csi config init` was run, then
this topic could be skipped and instead move to [Deploy Management Nodes](index.md#deploy_management_nodes).

**Note**: If a first time install of this software release is being done on this system and the `ncn_metadata.csv` 
file already had valid MAC addresses for both BMC and node interfaces before `csi config init` was run, then this
topic could be skipped and instead move to [Deploy Management Nodes](index.md#deploy_management_nodes).

### Topics

   1. [Collect the BMC MAC addresses](#collect_the_bmc_mac_addresses)
   1. [Restart Services after BMC MAC Addresses Collected](#restart_services_after_bmc_mac_addresses_collected)
   1. [Collect the NCN MAC addresses](#collect_the_ncn_mac_addresses)
   1. [Restart Services after NCN MAC Addresses Collected](#restart_services_after_ncn_mac_addresses_collected)
   1. [Next Topic](#next-topic)

## Details

<a name="collect_the_bmc_mac_addresses"></a>
### 1. Collect the BMC MAC addresses

The BMC MAC address can be collected from the switches using knowledge about the cabling of the NMN from the SHCD. 

See [Collecting BMC MAC Addresses](collecting_bmc_mac_addresses.md).

<a name="restart_services_after_bmc_mac_addresses_collected"></a>
### 2. Restart Services after BMC MAC Addresses Collected

The previous step updated `ncn_metadata.csv` with the BMC MAC Addresses so several earlier steps need to be repeated.

1. Change into the preparation directory.

   ```bash
   pit# cd /var/www/ephemeral/prep
   ```

1. Confirm that the `ncn_metadata.csv` file in this directory has the new information.
   There should be no remaining dummy data (de:ad:be:ef:00:00) for the BMC MAC column in the file, but that string may
   be present for the Bootstrap MAC, Bond0 MAC0, and Bond0 MAC1 columns.

   ```bash
   pit# cat ncn_metadata.csv
   ```

1. Remove the incorrectly-generated configs. Before deleting the incorrectly-generated configs consider
making a backup of them, in case they need to be examined at a later time.

   > **`WARNING`** Ensure that the `SYSTEM_NAME` environment variable is correctly set.

   ```bash
   pit# export SYSTEM_NAME=eniac
   pit# echo $SYSTEM_NAME
   ```

   Rename the old directory. 

   ```bash
   pit# mv /var/www/ephemeral/prep/${SYSTEM_NAME} /var/www/ephemeral/prep/${SYSTEM_NAME}.oldBMC
   ```

1. Generate system configuration again.

   The needed files should be in the current directory.
  
   ```bash
   pit# ls -1
   ```
  
   Expected output looks similar to the following:
  
   ```
   application_node_config.yaml
   cabinets.yaml
   hmn_connections.json
   ncn_metadata.csv
   switch_metadata.csv
   system_config.yaml
   ```

   The `system_config.yaml` file will make it easier to run the next command because it has the saved information
   from the command line arguments which were used initially for this command.

   ```bash
   pit# csi config init
   ```

   A new directory matching your `--system-name` argument will now exist in your working directory.

1. Check for workarounds in the `/opt/cray/csm/workarounds/csi-config` directory. If there are any workarounds in that directory, run those now. Each has its own instructions in their respective `README.md` files.

   ```bash
   pit# ls /opt/cray/csm/workarounds/csi-config
   ```

   If there is a workaround here, the output looks similar to the following:

   ```
   CASMINST-999
   ```

1. Copy the interface config files generated earlier by `csi config init` into `/etc/sysconfig/network/`.

   ```bash
   pit# cp -pv /var/www/ephemeral/prep/${SYSTEM_NAME}/pit-files/* /etc/sysconfig/network/
   pit# wicked ifreload all
   pit# systemctl restart wickedd-nanny && sleep 5
   ```

1. Check that IPs are set for each interface and investigate any failures.

    1. Check IPs, do not run tests if these are missing and instead start triage.

       ```bash
       pit# wicked show bond0 vlan002 vlan004 vlan007
       bond0           up
       link:     #7, state up, mtu 1500
       type:     bond, mode ieee802-3ad, hwaddr b8:59:9f:fe:49:d4
       config:   compat:suse:/etc/sysconfig/network/ifcfg-bond0
       leases:   ipv4 static granted
       addr:     ipv4 10.1.1.2/16 [static]

       vlan002         up
       link:     #8, state up, mtu 1500
       type:     vlan bond0[2], hwaddr b8:59:9f:fe:49:d4
       config:   compat:suse:/etc/sysconfig/network/ifcfg-vlan002
       leases:   ipv4 static granted
       addr:     ipv4 10.252.1.4/17 [static]
       route:    ipv4 10.92.100.0/24 via 10.252.0.1 proto boot

       vlan007         up
       link:     #9, state up, mtu 1500
       type:     vlan bond0[7], hwaddr b8:59:9f:fe:49:d4
       config:   compat:suse:/etc/sysconfig/network/ifcfg-vlan007
       leases:   ipv4 static granted
       addr:     ipv4 10.102.9.5/24 [static]

       vlan004         up
       link:     #10, state up, mtu 1500
       type:     vlan bond0[4], hwaddr b8:59:9f:fe:49:d4
       config:   compat:suse:/etc/sysconfig/network/ifcfg-vlan004
       leases:   ipv4 static granted
       addr:     ipv4 10.254.1.4/17 [static]
       ```

    1. Run tests, inspect failures.

       ```bash
       pit# csi pit validate --network
       ```
1. Copy the service config files generated earlier by `csi config init` for DNSMasq, Metal
   Basecamp (cloud-init), and Conman.

    1. Copy files (files only, `-r` is expressly not used).

        ```bash
        pit# cp -pv /var/www/ephemeral/prep/${SYSTEM_NAME}/dnsmasq.d/* /etc/dnsmasq.d/
        pit# cp -pv /var/www/ephemeral/prep/${SYSTEM_NAME}/conman.conf /etc/conman.conf
        pit# cp -pv /var/www/ephemeral/prep/${SYSTEM_NAME}/basecamp/* /var/www/ephemeral/configs/
        ```

    1. Restart all PIT services.

        ```bash
        pit# systemctl restart basecamp nexus dnsmasq conman
        ```

1. Apply any NCN pre-boot workarounds. Check for workarounds in the `/opt/cray/csm/workarounds/before-ncn-boot` directory. If there are any workarounds in that directory, run those now. Each has its own instructions in their respective README.md files.

   ```bash
   pit# ls /opt/cray/csm/workarounds/before-ncn-boot
   ```

   If there is a workaround here, the output looks similar to the following:
   ```
   CASMINST-980
   ```

1. Verify that all BMCs can be pinged.

   **Note:** It may take about 10 minutes from when dnsmasq is restarted to when the BMCs pick up new DHCP leases.

   This step will check all management nodes except ncn-m001-mgmt since that has an external connection and could
   not be booted by itself as the PIT node. 

   ```bash
   pit# export mtoken='ncn-m(?!001)\w+-mgmt'
   pit# export stoken='ncn-s\w+-mgmt'
   pit# export wtoken='ncn-w\w+-mgmt'
   pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ping -c3 {}
   ```

<a name="collect_the_ncn_mac_addresses"></a>
### 3. Collect the NCN MAC addresses

Now that the BMC MAC addresses are correct in `ncn_metadata.csv` and the PIT node services have been restarted,
a partial boot of the management nodes can be done to collect the remaining information from the conman console
logs on the PIT node using the [Procedure: iPXE Consoles](collecting_ncn_mac_addresses.md#procedure-ipxe-consoles)

See [Procedure: iPXE Consoles](collecting_ncn_mac_addresses.md#procedure-ipxe-consoles).

<a name="restart_services_after_ncn_mac_addresses_collected"></a>
### 4. Restart Services after NCN MAC Addresses Collected

The previous step updated `ncn_metadata.csv` with the NCN MAC Addresses for Bootstrap MAC, Bond0 MAC0, and Bond0 MAC1
so several earlier steps need to be repeated.

1. Change into the preparation directory.

   ```bash
   pit# cd /var/www/ephemeral/prep
   ```

1. Confirm that the `ncn_metadata.csv` file in this directory has the new information.
   There should be no remaining dummy data (de:ad:be:ef:00:00) for columns or rows in the file.
   Every row should have uniquely different MAC addresses from the other rows.

   ```bash
   pit# grep -v "de:ad:be:ef:00:00" ncn_metadata.csv
   pit# cat ncn_metadata.csv
   ```

1. Remove the incorrectly-generated configs. Before deleting the incorrectly-generated configs consider
making a backup of them, in case they need to be examined at a later time.

   > **`WARNING`** Ensure that the `SYSTEM_NAME` environment variable is correctly set.

   ```bash
   pit# export SYSTEM_NAME=eniac
   pit# echo $SYSTEM_NAME
   ```

   Rename the old directory. 

   ```bash
   pit# mv /var/www/ephemeral/prep/${SYSTEM_NAME} /var/www/ephemeral/prep/${SYSTEM_NAME}.oldNCN
   ```

1. Generate system configuration again.

   The needed files should be in the current directory.
  
   ```bash
   pit# ls -1
   ```
  
   Expected output looks similar to the following:
  
   ```
   application_node_config.yaml
   cabinets.yaml
   hmn_connections.json
   ncn_metadata.csv
   switch_metadata.csv
   system_config.yaml
   ```

   The `system_config.yaml` file will make it easier to run the next command because it has the saved information
   from the command line arguments which were used initially for this command.

   ```bash
   pit# csi config init
   ```

   A new directory matching your `--system-name` argument will now exist in your working directory.

1. Check for workarounds in the `/opt/cray/csm/workarounds/csi-config` directory. If there are any workarounds in that directory, run those now. Each has its own instructions in their respective `README.md` files.

   ```bash
   pit# ls /opt/cray/csm/workarounds/csi-config
   ```

   If there is a workaround here, the output looks similar to the following:

   ```
   CASMINST-999
   ```

1. Copy the interface config files generated earlier by `csi config init` into `/etc/sysconfig/network/`.

   ```bash
   pit# cp -pv /var/www/ephemeral/prep/${SYSTEM_NAME}/pit-files/* /etc/sysconfig/network/
   pit# wicked ifreload all
   pit# systemctl restart wickedd-nanny && sleep 5
   ```

1. Check that IPs are set for each interface and investigate any failures.

    1. Check IPs, do not run tests if these are missing and instead start triage.

       ```bash
       pit# wicked show bond0 vlan002 vlan004 vlan007
       bond0           up
       link:     #7, state up, mtu 1500
       type:     bond, mode ieee802-3ad, hwaddr b8:59:9f:fe:49:d4
       config:   compat:suse:/etc/sysconfig/network/ifcfg-bond0
       leases:   ipv4 static granted
       addr:     ipv4 10.1.1.2/16 [static]

       vlan002         up
       link:     #8, state up, mtu 1500
       type:     vlan bond0[2], hwaddr b8:59:9f:fe:49:d4
       config:   compat:suse:/etc/sysconfig/network/ifcfg-vlan002
       leases:   ipv4 static granted
       addr:     ipv4 10.252.1.4/17 [static]
       route:    ipv4 10.92.100.0/24 via 10.252.0.1 proto boot

       vlan007         up
       link:     #9, state up, mtu 1500
       type:     vlan bond0[7], hwaddr b8:59:9f:fe:49:d4
       config:   compat:suse:/etc/sysconfig/network/ifcfg-vlan007
       leases:   ipv4 static granted
       addr:     ipv4 10.102.9.5/24 [static]

       vlan004         up
       link:     #10, state up, mtu 1500
       type:     vlan bond0[4], hwaddr b8:59:9f:fe:49:d4
       config:   compat:suse:/etc/sysconfig/network/ifcfg-vlan004
       leases:   ipv4 static granted
       addr:     ipv4 10.254.1.4/17 [static]
       ```

    1. Run tests, inspect failures.

       ```bash
       pit# csi pit validate --network
       ```
1. Copy the service config files generated earlier by `csi config init` for DNSMasq, Metal
   Basecamp (cloud-init), and Conman.

    1. Copy files (files only, `-r` is expressly not used).

        ```bash
        pit# cp -pv /var/www/ephemeral/prep/${SYSTEM_NAME}/dnsmasq.d/* /etc/dnsmasq.d/
        pit# cp -pv /var/www/ephemeral/prep/${SYSTEM_NAME}/conman.conf /etc/conman.conf
        pit# cp -pv /var/www/ephemeral/prep/${SYSTEM_NAME}/basecamp/* /var/www/ephemeral/configs/
        ```

    1. Restart all PIT services.

        ```bash
        pit# systemctl restart basecamp nexus dnsmasq conman
        ```

1. Apply any NCN pre-boot workarounds. Check for workarounds in the `/opt/cray/csm/workarounds/before-ncn-boot` directory. If there are any workarounds in that directory, run those now. Each has its own instructions in their respective README.md files.

   ```bash
   pit# ls /opt/cray/csm/workarounds/before-ncn-boot
   ```

   If there is a workaround here, the output looks similar to the following:
   ```
   CASMINST-980
   ```

<a name="next-topic"></a>
# Next Topic

   After completing the collection of BMC MAC addresses and NCN MAC address to update `ncn_metadata.csv` and restarting
   the services dependent on correct data in `ncn_metadata.csv`, the next step is deployment of the management nodes.

   See [Deploy Management Nodes](index.md#deploy_management_nodes)

