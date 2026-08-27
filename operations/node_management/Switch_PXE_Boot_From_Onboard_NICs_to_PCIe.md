# Switch PXE Boot from Onboard NIC to PCIe

This section details how to migrate NCNs from using their onboard NICs for PXE booting to booting
over the PCIe cards.

- [Enabling UEFI PXE mode](#enabling-uefi-pxe-mode)
    - [Mellanox](#mellanox)
        - [Print current UEFI and SR-IOV state](#print-current-uefi-and-sr-iov-state)
        - [Setting expected values](#setting-expected-values)
        - [High-Speed Network](#high-speed-network)
    - [QLogic `FastLinq`](#qlogic-fastlinq)
        - [Kernel modules](#kernel-modules)
- [Disabling or removing on-board connections](#disabling-or-removing-on-board-connections)

**This applies to newer systems (Spring 2020 or newer)** where onboard NICs are still used.

This presents a need for migration for systems still using the legacy, preview topology. Specifically,
systems with onboard connections to their leaf-bmc switches and NCNs need to disable/remove that connection.

This onboard NCN port came from before spine-switches were added to the shasta-network topology. The onboard connection
was responsible for every network (MTL/NMN/HMN/CAN) and was the sole driver of PXE booting for.
NCNs now use bond interfaces and spine switches for those networks;
however, some older systems still have this legacy connection to their leaf-bmc switches and solely use it for PXE booting.
This NIC is not used during runtime, and NCNs in this state should enable PXE within their PCIe devices' OpROMs and disable/remove this onboard connection.

## Enabling UEFI PXE mode

### Mellanox

The [Mellanox CLI Tools][1] are required to configure UEFI PXE from the Linux command line.

For CSM 1.4 or later systems, `mft` is installed in NCN images by default.

(`ncn#`) Run the following command to begin interacting with Mellanox cards:

```bash
mst start
```

Now `mst status` and other commands like `mlxfwmanager` or `mlxconfig` will work, and devices required for these commands will be created in `/dev/mst`.

#### Print current UEFI and SR-IOV state

> **UEFI:** All boots are UEFI; this needs to be enabled for access to the UEFI OpROM for configuration and for usage of UEFI firmwares.
> **SR-IOV:** This is currently DISABLED because it can attribute to longer POSTs on HPE blades (Gen10+, i.e. DL325 or DL385) with Mellanox ConnectX-5 PCIe cards. The technology is not yet enabled for virtualization usage, but may be in the future.

Use the following snippet to display device name and current UEFI PXE state.

```bash
mst status
for MST in $(ls /dev/mst/*); do
    mlxconfig -d ${MST} q | egrep "(Device|EXP_ROM|SRIOV_EN)"
done
```

#### Setting expected values

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

#### High-Speed Network

For worker nodes with High-Speed Network attachments, the PXE and SR-IOV features should be
disabled.

1. Run `mlxfwmanager` to probe and dump the Mellanox PCIe cards.

    ```bash
    mlxfwmanager
    ```

1. Find the device path for the HSN card, assuming it is a ConnectX-5 or other 100GB card, this should be easy to pick out.

1. Run the following commands, swapping the `MST` variable for the actual card path.

    ```bash
    # Set UEFI to YES

    MST=/dev/mst/mt4119_pciconf1
    mlxconfig -d ${MST} -y set EXP_ROM_UEFI_ARM_ENABLE=0
    mlxconfig -d ${MST} -y set EXP_ROM_UEFI_x86_ENABLE=0
    mlxconfig -d ${MST} -y set EXP_ROM_PXE_ENABLE=0
    mlxconfig -d ${MST} -y set SRIOV_EN=0
    mlxconfig -d ${MST} q | egrep "EXP_ROM"
    ```

The Mellanox HSN card is now neutralized, and will only be usable in a booted system.

### QLogic `FastLinq`

These should already be configured for PXE booting.

#### Kernel modules

KMP modules for QLogic are installed:

- `qlgc-fastlinq-kmp-default`
- `qlgc-qla2xxx-kmp-default`

## Disabling or removing on-board connections

The onboard connection can be disabled in a few ways; short of removing the physical connection, one
may shutdown the switch port as well.

If the physical connection can be removed, this is preferred and can be done after enabling PXE on
the PCIe cards.

If the connection must be disabled, log in to the respective leaf-bmc switch.

1. Connect to the leaf-bmc switch using serial or SSH connections.

   Select one of the connection options below. The IP addresses and device names may vary in the commands below.

   ```bash
   # SSH over METAL MANAGEMENT
   ssh admin@10.1.0.4
   # SSH over NODE MANAGEMENT
   ssh admin@10.252.0.4
   # SSH over HARDWARE MANAGEMENT
   ssh admin@10.254.0.4

   # or.. serial (device name will vary).
   minicom -b 115200 -D /dev/tty.USB1
   ```

1. Enter configuration mode.

   ```console
   sw-leaf-bmc-001> configure terminal
   sw-leaf-bmc-001(config)#>
   ```

1. Disable the NCN interfaces.

   Check the SHCD for reference before continuing so that the interfaces connected to management NCNs are being changed.
   Ports 2 to 10 are commonly the master, worker, and storage nodes when there are 3 of each. Some systems may have more
   worker nodes or utility storage nodes, or may be racked and cabled differently.

   ```console
   sw-leaf-bmc-001(config)#> interface range 1/1/2-1/1/10
   sw-leaf-bmc-001(config)#> shutdown
   sw-leaf-bmc-001(config)#> write memory
   ```

Enable the interfaces again at any time by switching the `shutdown` command out for `no shutdown`.

[1]: http://www.mellanox.com/page/management_tools
