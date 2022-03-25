# Switch PXE Boot from Onboard NIC to PCIe

This section details how to migrate NCNs from using their onboard NICs for PXE booting to booting
over the PCIe cards.

- [Switch PXE Boot from Onboard NIC to PCIe](#switch-pxe-boot-from-onboard-nic-to-pcie)
  - [Enabling UEFI PXE Mode](#enabling-uefi-pxe-mode)
    - [Mellanox](#mellanox)
      - [Print Current UEFI and SR-IOV State](#print-current-uefi-and-sr-iov-state)
      - [Setting Expected Values](#setting-expected-values)
      - [High-Speed Network](#high-speed-network)
          - [Obtaining Mellanox Tools](#obtaining-mellanox-tools)
    - [QLogic FastLinq](#qlogic-fastlinq)
      - [Kernel Modules](#kernel-modules)
  - [Disabling or Removing On-Board Connections](#disabling-or-removing-on-board-connections)


**This applies to Newer systems (Spring 2020 or newer)** where onboard NICs are still used.

This presents a need for migration for systems still using the legacy, preview topology. Specifically,
systems with onboard connections to their leaf-bmc switches and NCNs need to disable/remove that connection.

This onboard NCN port came from before spine-switches were added to the shasta-network topology. The onboard connection
was responsible for every network (MTL/NMN/HMN/CAN) and was the sole driver of PXE booting for. Now, NCNs use bond interfaces and spine switches for those networks;
however, some older systems still have this legacy connection to their leaf-bmc switches and solely use it for PXE booting. 
This NIC is not used during runtime, and NCNs in this state should enable PXE within their PCIe devices' OpROMs and disable/remove this onboard connection.

<a name="enabling-uefi-pxe-mode"></a>
## Enabling UEFI PXE Mode

<a name="mellanox"></a>
### Mellanox

The [Mellanox CLI Tools][1] are required to configure UEFI PXE from the Linux command line.

On any NCN (using 0.0.10 k8s, or 0.0.8 Ceph; anything built on ncn-0.0.21 or higher), run the following command to begin interacting with Mellanox cards:

> **NOTE:** If recovering NCNs with an earlier image without the Mellanox tools, refer to the [Obtaining Mellanox Tools](#obtaining-mellanox-tools) section.

```bash
ncn# mst start
```

Now `mst status` and other commands like `mlxfwmanager` or `mlxconfig` will work, and devices required for these commands will be created in `/dev/mst`.

<a name="print-current-uefi-and-sr-iov-state"></a>
#### Print Current UEFI and SR-IOV State

> **UEFI:** All boots are UEFI; this needs to be enabled for access to the UEFI OpROM for configuration and for usage of UEFI firmwares.
> **SR_IOV:** This is currently DISABLED because it can attribute to longer POSTs on HPE blades (Gen10+, i.e. DL325 or DL385) with Mellanox ConnectX-5 PCIe cards. The technology is not yet enabled for virtualization usage, but may be in the future.

Use the following snippet to display device name and current UEFI PXE state.

```bash
ncn# mst status
for MST in $(ls /dev/mst/*); do
    mlxconfig -d ${MST} q | egrep "(Device|EXP_ROM|SRIOV_EN)"
done
```

<a name="setting-expected-values"></a>
#### Setting Expected Values

Use the following snippet to enable and dump UEFI PXE state.

```bash
for MST in $(ls /dev/mst/*); do
    echo ${MST}
    mlxconfig -d ${MST} -y set EXP_ROM_UEFI_x86_ENABLE=1
    mlxconfig -d ${MST} -y set EXP_ROM_PXE_ENABLE=1
    mlxconfig -d ${MST} -y set SRIOV_EN=0
    mlxconfig -d ${MST} q | egrep "EXP_ROM"
done
```

<a name="high-speed-network"></a>
#### High-Speed Network

For worker nodes with High-Speed network attachments, the PXE and SR-IOV features should be
disabled.

1. Run `mlxfwmanager` to probe and dump the Mellanox PCIe cards.
    
    ```bash
    ncn# mlxfwmanager
    ```

2. Find the device path for the HSN card, assuming it is a ConnectX-5 or other 100GB card, this should be easy to pick out.

3. Run the following commands, swapping the `MST` variable for the actual card path.
    
    ```bash
    # Set UEFI to YES

    ncn# MST=/dev/mst/mt4119_pciconf1
    ncn# mlxconfig -d ${MST} -y set EXP_ROM_UEFI_ARM_ENABLE=0
    ncn# mlxconfig -d ${MST} -y set EXP_ROM_UEFI_x86_ENABLE=0
    ncn# mlxconfig -d ${MST} -y set EXP_ROM_PXE_ENABLE=0
    ncn# mlxconfig -d ${MST} -y set SRIOV_EN=0
    ncn# mlxconfig -d ${MST} q | egrep "EXP_ROM"
    ```

The Mellanox HSN card is now neutralized, and will only be usable in a booted system.

<a name="obtaining-mellanox-tools"></a>
###### Obtaining Mellanox Tools

For 1.4 or later systems, `mft` is installed in NCN images by default.

For 1.3 systems, obtain the Mellanox tools with the following commands:

```bash
linux# wget https://www.mellanox.com/downloads/MFT/mft-4.15.1-9-x86_64-rpm.tgz
linux# tar -xzvf mft-4.15.1-9-x86_64-rpm.tgz
linux# cd mft-4.15.1-9-x86_64-rpm/RPMS
linux# rpm -ivh ./mft-4.15.1-9.x86_64.rpm
linux# cd
linux# mst start
```

<a name="qlogic-fastlinq"></a>
### QLogic FastLinq

These should already be configured for PXE booting.

<a name="kernel-modules"></a>
#### Kernel Modules

KMP modules for Qlogic are installed:

- qlgc-fastlinq-kmp-default
- qlgc-qla2xxx-kmp-default


<a name="disabling-or-removing-on-board-connections"></a>
## Disabling or Removing On-Board Connections

The onboard connection can be disabled in a few ways; short of removing the physical connection, one
may shutdown the switchport as well.

If the physical connection can be removed, this is preferred and can be done so after enabling PXE on
the PCIe cards.

If the connection must be disabled, log in to the respective leaf-bmc switch.

1. Connect to the leaf-bmc switch using serial or SSH connections.

   Select one of the connection options below. The IP addresses and device names may vary in the commands below.
    
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

2. Enter configuration mode.
    
   ```sh
   sw-leaf-bmc-001> configure terminal
   sw-leaf-bmc-001(config)#>
   ```

3. Disable the NCN interfaces.
   
   Check the SHCD for reference before continuing so that the interfaces connected to management NCNs are being changed. Ports 2 to 10 are commonly the master, worker, and storage nodes when there are 3 of each. Some systems may have more worker nodes or utility storage nodes, or may be racked and cabled differently.
   
   ```bash
   sw-leaf-bmc-001(config)#> interface range 1/1/2-1/1/10
   sw-leaf-bmc-001(config)#> shutdown
   sw-leaf-bmc-001(config)#> write memory
   ```
   
   Enable the interfaces again at anytime by switching the `shutdown` command out for `no shutdown`.


[1]: http://www.mellanox.com/page/management_tools

