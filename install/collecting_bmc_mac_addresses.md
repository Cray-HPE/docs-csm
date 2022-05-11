# Collecting the BMC MAC Addresses

This guide will detail how to collect BMC MAC addresses from an HPE Cray EX system with configured switches.
The BMC MAC address is the exclusive, dedicated LAN for the onboard BMC.

Results may vary if an unconfigured switch is being used.

## Prerequisites

* There is a configured switch with SSH access or unconfigured with COM access (serial-over-lan/DB-9).
* A file is available to record the collected BMC information.

## Procedure

1. Start a session on the leaf switch, either using SSH or a USB serial cable (see [Connect to Switch over USB-Serial Cable](connect_to_switch_over_usb_serial_cable.md) for details on how to do that).

    > **NOTE:** These IP addresses are examples; `10.X.0.4` may or may not match the setup.

    ```bash
    # SSH over METAL MANAGEMENT
    pit# ssh admin@10.1.0.4

    # SSH over NODE MANAGEMENT
    pit# ssh admin@10.252.0.4

    # SSH over HARDWARE MANAGEMENT
    pit# ssh admin@10.254.0.4

    # or.. serial (device name will vary).
    pit# minicom -b 115200 -D /dev/tty.USB1
    ```

1. Display the MAC addresses for the BMC ports (if known). If they exist on the same VLAN, dump the VLAN to get the MAC addresses.

    In order to find the ports of the BMCs, cross reference the HMN tab of the SHCD.

    > Please reference the CLI for more information (press `?` or `tab` to assist on-the-fly).

    Print using the VLAN ID:

    DellOS 10

    ```bash
    # DellOS 10
    sw-leaf-001# show mac address-table vlan 4
    VlanId  Mac Address  Type      Interface
    4 00:1e:67:98:fe:2c  dynamic   ethernet1/1/11
    4 a4:bf:01:38:f0:b1  dynamic   ethernet1/1/27
    4 a4:bf:01:38:f1:44  dynamic   ethernet1/1/25
    4 a4:bf:01:48:1e:ac  dynamic   ethernet1/1/28
    4 a4:bf:01:48:1f:70  dynamic   ethernet1/1/31
    4 a4:bf:01:48:1f:e0  dynamic   ethernet1/1/26
    4 a4:bf:01:48:20:03  dynamic   ethernet1/1/30
    4 a4:bf:01:48:20:57  dynamic   ethernet1/1/29
    4 a4:bf:01:4d:d9:9a  dynamic   ethernet1/1/32
    ```

    Aruba AOS-CX

    ```bash
    # Aruba AOS-CX
    sw-leaf-bmc-001# show mac-address-table vlan 4
    MAC age-time            : 300 seconds
    Number of MAC addresses : 21

    MAC Address          VLAN     Type                      Port
    --------------------------------------------------------------
    b4:2e:99:df:f3:61    4        dynamic                   1/1/36
    b4:2e:99:df:ec:f1    4        dynamic                   1/1/35
    b4:2e:99:df:ec:49    4        dynamic                   1/1/33
    94:40:c9:37:04:84    4        dynamic                   1/1/26
    94:40:c9:35:03:06    4        dynamic                   1/1/27
    94:40:c9:37:0a:2a    4        dynamic                   1/1/29
    94:40:c9:37:67:60    4        dynamic                   1/1/43
    94:40:c9:37:67:80    4        dynamic                   1/1/37
    94:40:c9:37:77:26    4        dynamic                   1/1/31
    94:40:c9:37:77:b8    4        dynamic                   1/1/28
    94:40:c9:37:87:5a    4        dynamic                   1/1/30
    94:40:c9:37:f9:b4    4        dynamic                   1/1/25
    b4:2e:99:df:eb:c1    4        dynamic                   1/1/34
    ```

    Print using the interface and trunk:

    DellOS 10

    ```bash
    # DellOS 10
    sw-leaf-001# show mac address-table interface ethernet 1/1/32
    VlanId Mac Address    Type      Interface
    4 a4:bf:01:4d:d9:9a   dynamic   ethernet1/1/32
    ```

    Aruba AOS-CX

    ```bash
    # Aruba AOS-CX
    sw-leaf-bmc-001# show mac-address-table port
      PORTS  List of Ports [e.g. 1/1/1 or 1/1/1-1/1/3 or lag1]
    sw-leaf-bmc-001# show mac-address-table port 1/1/36
    MAC age-time            : 300 seconds
    Number of MAC addresses : 1

    MAC Address          VLAN     Type                      Port
    --------------------------------------------------------------
    b4:2e:99:df:f3:61    4        dynamic                   1/1/36
    ```

    Print everything:

    DellOS 10

    ```bash
    # DellOS 10
    sw-leaf-001# show mac address-table
    VlanId  Mac Address  Type     Interface
    4 a4:bf:01:4d:d9:9a  dynamic  ethernet1/1/32
    ....
    # Onyx and Aruba
    sw-leaf-001# show mac-address-table
    ```

    Aruba AOS-CX

    ```bash
    # Aruba AOS-CX
    sw-leaf-bmc-001# show mac-address-table
    MAC age-time            : 300 seconds
    Number of MAC addresses : 52

    MAC Address          VLAN     Type                      Port
    --------------------------------------------------------------
    ec:eb:b8:3d:89:41    1        dynamic                   1/1/42
    ```

1. Ensure the management NCNs are present in the `ncn_metadata.csv` file.

   The output from the previous `show mac address-table` command will display information for all management NCNs that do not have an external connection for their BMC, such as `ncn-m001`.

   All of the management NCNs should be present in the `ncn_metadata.csv` file.

   Fill in the `Bootstrap MAC`, `Bond0 MAC0`, and `Bond0 MAC1` columns with a placeholder value, such as `de:ad:be:ef:00:00`,
   as a marker that the correct value is not in this file yet.

   **IMPORTANT:** Mind the index for each group of nodes (3, 2, 1.... ; not 1, 2, 3).
   If storage nodes are `ncn-s001 x3000c0s7b0n0`, `ncn-s002 x3000c0s8b0n0`, `ncn-s003 x3000c0s9b0n0`,
   then their portion of the file would be ordered `x3000c0s9b0n0`, `x3000c0s8b0n0`, `x3000c0s7b0n0`.

   ```text
   Xname,Role,Subrole,BMC MAC,Bootstrap MAC,Bond0 MAC0,Bond0 MAC1
   x3000c0s9b0n0,Management,Storage,a4:bf:01:38:f1:44,de:ad:be:ef:00:00,de:ad:be:ef:00:00,de:ad:be:ef:00:00
   x3000c0s8b0n0,Management,Storage,a4:bf:01:48:1f:e0,de:ad:be:ef:00:00,de:ad:be:ef:00:00,de:ad:be:ef:00:00
   x3000c0s7b0n0,Management,Storage,a4:bf:01:38:f0:b1,de:ad:be:ef:00:00,de:ad:be:ef:00:00,de:ad:be:ef:00:00
                                     ^^^^^^^^^^^^^^^^^
   ```

   The column heading must match that shown above for `csi` to parse it correctly.

1. Collect the BMC MAC address information for the PIT node.

   The PIT node BMC is not connected to the switch like the other management nodes.

   ```bash
   linux# export SYSTEM_NAME=eniac
   linux# export USERNAME=root
   linux# export IPMI_PASSWORD=changeme
   linux# ipmitool -I lanplus -U $USERNAME -E -H ${SYSTEM_NAME}-ncn-m001-mgmt lan print | grep "MAC Address"
   MAC Address             : a4:bf:01:37:87:32
   ```

   > **NOTE:** An Intel node needs to use `ipmitool -I lanplus -U $USERNAME -E -H ${SYSTEM_NAME}-ncn-m001-mgmt lan print` instead of the above command.

   Add this information for `ncn-m001` to the `ncn_metadata.csv` file. There should be `ncn-m003`, then `ncn-m002`, and this new entry for `ncn-m001` as the last line in the file.

   ```text
   x3000c0s1b0n0,Management,Master,a4:bf:01:37:87:32,de:ad:be:ef:00:00,de:ad:be:ef:00:00,de:ad:be:ef:00:00
   ```

1. Verify the `ncn_metadata.csv` file has a row for every management node in the SHCD.

   There may be placeholder entries for some MAC addresses.

   Sample file showing storage nodes 3, 2, and 1, then worker nodes 3, 2, and 1, and finally master nodes 3, 2, and 1 with valid `BMC MAC`
  addresses, but placeholder value `de:ad:be:ef:00:00` for the `Bootstrap MAC`, `Bond0 MAC0`, and `Bond0 MAC1`.

   ```text
   Xname,Role,Subrole,BMC MAC,Bootstrap MAC,Bond0 MAC0,Bond0 MAC1
   x3000c0s9b0n0,Management,Storage,a4:bf:01:38:f1:44,de:ad:be:ef:00:00,de:ad:be:ef:00:00,de:ad:be:ef:00:00
   x3000c0s8b0n0,Management,Storage,a4:bf:01:48:1f:e0,de:ad:be:ef:00:00,de:ad:be:ef:00:00,de:ad:be:ef:00:00
   x3000c0s7b0n0,Management,Storage,a4:bf:01:38:f0:b1,de:ad:be:ef:00:00,de:ad:be:ef:00:00,de:ad:be:ef:00:00
   x3000c0s6b0n0,Management,Worker,a4:bf:01:48:1e:ac,de:ad:be:ef:00:00,de:ad:be:ef:00:00,de:ad:be:ef:00:00
   x3000c0s5b0n0,Management,Worker,a4:bf:01:48:20:57,de:ad:be:ef:00:00,de:ad:be:ef:00:00,de:ad:be:ef:00:00
   x3000c0s4b0n0,Management,Worker,a4:bf:01:48:20:03,de:ad:be:ef:00:00,de:ad:be:ef:00:00,de:ad:be:ef:00:00
   x3000c0s3b0n0,Management,Master,a4:bf:01:48:1f:70,de:ad:be:ef:00:00,de:ad:be:ef:00:00,de:ad:be:ef:00:00
   x3000c0s2b0n0,Management,Master,a4:bf:01:4d:d9:9a,de:ad:be:ef:00:00,de:ad:be:ef:00:00,de:ad:be:ef:00:00
   x3000c0s1b0n0,Management,Master,a4:bf:01:37:87:32,de:ad:be:ef:00:00,de:ad:be:ef:00:00,de:ad:be:ef:00:00
   ```
