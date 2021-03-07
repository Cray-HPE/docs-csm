# Guide : Netboot an NCN from a Spine

This page details how to migrate NCNs from depending on their onboard NICs for PXE booting, and booting
over the spine switches.

* [Enabling UEFI PXE Mode](#enabling-uefi-pxe-mode) 
    * [Mellanox](#mellanox) 
        * [Print current UEFI and SR-IOV State](#print-current-uefi-and-sr-iov-state) 
        * [Setting Expected Values](#setting-expected-values) 
        * [High-Speed Network](#high-speed-network) 
        * [Obtaining Mellanox Tools](#obtaining-mellanox-tools) 
    * [QLogic FastLinq](#qlogic-fastlinq) 
        * [Kernel Modules](#kernel-modules) 
* [Disabling/Removing On-Board Connections](#disabling-or-removing-on-board-connections) 


**This applies to Newer systems (Spring 2020 or newer)** where onboard NICs are still used.

This presents a need for migration for systems still using the legacy, preview topology. Specifically,
systems with onboard connections to their leaf switches and NCNs need to disable/remove that connection.

This onboard NCN port came from before spine-switches were added to the shasta-network topology. The onboard connection
  was responsible for every network (MTL/NMN/HMN/CAN) and was the sole driver of PXE booting for. Now, NCNs use bond interfaces and spine switches for those networks,
   however some older systems still have this legacy connection to their leaf switches and solely use it for PXE booting. This NIC is not used during runtime, and NCNs in this state should enable PXE within their PCIe devices' OpROMs and disable/remove this onboard connection.

<a name="enabling-uefi-pxe-mode"></a>
## Enabling UEFI PXE Mode

<a name="mellanox"></a>
### Mellanox

This uses the [Mellanox CLI Tools][1] for configuring UEFI PXE from the Linux command line.

On any NCN (using 0.0.10 k8s, or 0.0.8 ceph; anything built on ncn-0.0.21 or higher) can run this to begin interacting with Mellanox cards:
If you are recovering NCNs with an earlier image without the mellanox tools, please refer to the section on the bottom of the Mellanox this segment.

```bash
ncn# mst start
```

Now `mst status` and other commands like `mlxfwmanager` or `mlxconfig` will work, and devices required for these commands will be created in `/dev/mst`.

<a name="print-current-uefi-and-sr-iov-state"></a>
#### Print current UEFI and SR-IOV State

> UEFI: all boots are UEFI, this needs to be enabled for access to the UEFI OpROM for configuration and for usage of UEFI firmwares.
> SR_IOV: This is currently DISABLED because it can attribute to longer POSTs on HPE blades (Gen10+, i.e. DL325 or DL385) with Mellanox ConnectX-5 PCIe cards. The technology is not yet enabled for virtualization usage, but may be in the future.

Use this snippet to print out device name and current UEFI PXE state.
```bash
ncn# mst status
for MST in $(ls /dev/mst/*); do
    mlxconfig -d ${MST} q | egrep "(Device|EXP_ROM|SRIOV_EN)"
done
```

<a name="setting-expected-values"></a>
#### Setting Expected Values

Use this snippet to enable and dump UEFI PXE state.
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

1. Run `mlxfwmanager` to probe and dump your Mellanox PCIe cards
    ```bash
    ncn# mlxfwmanager
    ```

2. Find the device path for the HSN card, assuming it is a ConnectX-5 or other 100GB card this should be easy to pick out.

3. Run this, swapping the `MST` variable for your actual card path
    ```bash
    # Set UEFI to YES
    
    ncn# MST=/dev/mst/mt4119_pciconf1
    ncn# mlxconfig -d ${MST} -y set EXP_ROM_UEFI_ARM_ENABLE=0
    ncn# mlxconfig -d ${MST} -y set EXP_ROM_UEFI_x86_ENABLE=0
    ncn# mlxconfig -d ${MST} -y set EXP_ROM_PXE_ENABLE=0
    ncn# mlxconfig -d ${MST} -y set SRIOV_EN=0
    ncn# mlxconfig -d ${MST} q | egrep "EXP_ROM"
    ```

Your Mellanox HSN card is now neutralized, and will only be usable in a booted system.

<a name="obtaining-mellanox-tools"></a>
###### Obtaining Mellanox Tools

`mft` is installed in 1.4 NCN images, for 1.3 systems they will need to obtain the tools by hand:

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

See [#casm-triage][2] if this is not the case.

<a name="disabling-or-removing-on-board-connections"></a>
## Disabling or Removing On-Board Connections

The onboard connection can be disabled a few ways, short of removing the physical connection one
may shutdown the switchport as well.

If you can remove the physical connection, this is preferred and can be done so after enabling PXE on
the PCIe cards.

If you want to disable the connection, you will need to login to your respective leaf switch.
1. Connect over your medium of choice:
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
2. Enter configuration mode
    ```sh
    sw-leaf-001> configure terminal
    sw-leaf-001(config)#>  
    ```
3. Disable the NCN interfaces - check your SHCD for reference before continuing.
    ```
    sw-leaf-001(config)#> interface range 1/1/2-1/1/10  
    sw-leaf-001(config)#> shutdown  
    sw-leaf-001(config)#> write memory  
    ```

You're done.

You can enable them again at anytime by switching the `shutdown` command out for `no shutdown`.


[1]: http://www.mellanox.com/page/management_tools
