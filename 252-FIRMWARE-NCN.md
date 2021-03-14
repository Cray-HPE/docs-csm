<a name="node-firmware"></a>
# Node Firmware

This page will walk an administrator through NCN BIOS and firmware checkout.

To complete firmware checkout, proceed through the below sections:
1. [Confirm BIOS and Firmware Inventory](252-FIRMWARE-NCN.md#confirm-bios-and-firmware-inventory)
2. [Identifying BIOS and Hardware](252-FIRMWARE-NCN.md#identifying-bios-and-hardware)
   * [Gigabyte Upgrades](252-FIRMWARE-NCN.md#gigabyte-upgrades)
   * [HPE (iLO) Upgrades](252-FIRMWARE-NCN.md#hpe-ilo-upgrades)
      * [Pre-Reqs](252-FIRMWARE-NCN.md#pre-reqs)
      * [GUI](252-FIRMWARE-NCN.md#gui)
      * [Redfish](252-FIRMWARE-NCN.md#redfish)
3. [Component Firmware Checkout](252-FIRMWARE-NCN.md#component-firmware-checkout)
   * [Marvell Upgrades](252-FIRMWARE-NCN.md#marvell-upgrades)
   * [Mellanox Upgrades](252-FIRMWARE-NCN.md#mellanox-upgrades)
      * [Enable Tools](252-FIRMWARE-NCN.md#enable-tools)
      * [Check Current Firmware](252-FIRMWARE-NCN.md#check-current-firmware)
      * [Optional Online Update](252-FIRMWARE-NCN.md#optional-online-update)
<a name="confirm-bios-and-firmware-inventory"></a>

## Confirm BIOS and Firmware Inventory

> **`CUSTOMER NOTE`** If there's doubt that the tar contains latest, the customer should check [CrayPort][10] for newer firmware.

1. Prepare the inventory; the RPMs providing firmware need to be installed:

    ```bash
    pit# export CSM_RELEASE=<insert the name of the CSM release folder>
    pit# find /var/www/ephemeral/${CSM_RELEASE}/firmware -name *.rpm -exec zypper -n in --auto-agree-with-licenses --allow-unsigned-rpm {} \+
    ```

2. Hide the old firmware; cleanup the directory
     > **`NOTE`** This step will be removed in later versions of Shasta; this is correcting the layout of the directory.
    ```bash
    pit# mv /var/www/fw/river /var/www/fw/.river-old
    ```

3. Set web-links for the new firmware:
    ```bash
    pit# \
    mkdir -pv /var/www/fw/river/hpe
    find /opt/cray/fw -name *.flash -exec ln -snf {} /var/www/fw/river/hpe/ \;
    find /opt/cray/fw -name *.bin -exec ln -snf {} /var/www/fw/river/hpe/ \;
    mkdir -pv /var/www/fw/river/gb
    find /opt/cray/FW/bios -name sh-svr* -exec ln -snf {} /var/www/fw/river/gb/ \;
    mkdir -pv /var/www/fw/mountain/cray
    find /opt/cray/FW/bios -mindepth 0 -maxdepth 1 -type f -exec ln -snf {} /var/www/fw/mountain/cray/ \;
4. Make a tftp symlink for Gigabyte nodes:
    ```bash
    pit #ln -snf ../fw /var/www/boot/fw
    ```

<a name="identifying-bios-and-hardware"></a>
## Identifying BIOS and Hardware

1. Checkout BIOS and BMC firmware with `ipmitool`:
   - From the NCN:
      ```bash
      ncn-m002# pdsh -b -w $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u |  tr -t '\n' ',') '
      ipmitool fru | grep -i "board product" && \
      ipmitool mc info | grep -i "firmware revision" && \
      ipmitool fru | grep -i "product version"
      ' | sort -u
      ```
   - From the LiveCD
     ```bash
     pit# \
     export mtoken='ncn-m(?!001)\w+-mgmt'
     export stoken='ncn-s\w+-mgmt'
     export wtoken='ncn-w\w+-mgmt'
     export username=root
     export IPMI_PASSWORD=changeme
     grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | xargs -t -i ipmitool -I lanplus -U $username -E -H {} fru | grep -i 'board product'
     grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | xargs -t -i ipmitool -I lanplus -U $username -E -H {} mc info | grep -i 'firmware revision'
     ```
   > #### Manufacturer Examples
   > - Gigabyte:
   >      > **NOTE** On Gigabyte, the Product Version can be disregarded. It may become valuable at a later date.
   >      ```bash
   >      ncn-m001:  Board Product         : MZ32-AR0-00
   >      ncn-m001: Firmware Revision         : 12.84
   >      ncn-m001:  Product Version       : 0100
   >      ncn-m002:  Board Product         : MZ32-AR0-00
   >      ncn-m002: Firmware Revision         : 12.84
   >      ncn-m002:  Product Version       : 0100
   >      ncn-m003:  Board Product         : MZ32-AR0-00
   >      ncn-m003: Firmware Revision         : 12.84
   >      ncn-m003:  Product Version       : 0100
   >      ncn-s001:  Board Product         : MZ32-AR0-00
   >      ncn-s001: Firmware Revision         : 12.84
   >      ncn-s001:  Product Version       : 0100
   >      ncn-s002:  Board Product         : MZ32-AR0-00
   >      ncn-s002: Firmware Revision         : 12.84
   >      ncn-s002:  Product Version       : 0100
   >      ncn-s003:  Board Product         : MZ32-AR0-00
   >      ncn-s003: Firmware Revision         : 12.84
   >      ncn-s003:  Product Version       : 0100
   >      ncn-w001:  Board Product         : MZ32-AR0-00
   >      ncn-w001: Firmware Revision         : 12.84
   >      ncn-w001:  Product Version       : 0100
   >      ncn-w002:  Board Product         : MZ32-AR0-00
   >      ncn-w002: Firmware Revision         : 12.84
   >      ncn-w002:  Product Version       : 0100
   >      ncn-w003:  Board Product         : MZ32-AR0-00
   >      ncn-w003: Firmware Revision         : 12.84
   >      ncn-w003:  Product Version       : 0100
   >      ```
   >
   > - HPE:
   >      ```bash
   >      ncn-m001:  Board Product         : Marvell 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter
   >      ncn-m001:  Board Product         : ProLiant DL325 Gen10 Plus
   >      ncn-m001: Firmware Revision         : 2.33
   >      ncn-m001:  Product Version       :
   >      ncn-m001:  Product Version       : 10/30/2020
   >      ncn-m002:  Board Product         : Marvell 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter
   >      ncn-m002:  Board Product         : ProLiant DL325 Gen10 Plus
   >      ncn-m002: Firmware Revision         : 2.33
   >      ncn-m002:  Product Version       :
   >      ncn-m002:  Product Version       : 10/30/2020
   >      ncn-m003:  Board Product         : Marvell 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter
   >      ncn-m003:  Board Product         : ProLiant DL325 Gen10 Plus
   >      ncn-m003: Firmware Revision         : 2.33
   >      ncn-m003:  Product Version       :
   >      ncn-m003:  Product Version       : 10/30/2020
   >      ncn-s001:  Board Product         : Marvell 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter
   >      ncn-s001:  Board Product         : ProLiant DL325 Gen10 Plus
   >      ncn-s001: Firmware Revision         : 2.33
   >      ncn-s001:  Product Version       :
   >      ncn-s001:  Product Version       : 10/30/2020
   >      ncn-s002:  Board Product         : Marvell 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter
   >      ncn-s002:  Board Product         : ProLiant DL325 Gen10 Plus
   >      ncn-s002: Firmware Revision         : 2.33
   >      ncn-s002:  Product Version       :
   >      ncn-s002:  Product Version       : 10/30/2020
   >      ncn-s003:  Board Product         : Marvell 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter
   >      ncn-s003:  Board Product         : ProLiant DL325 Gen10 Plus
   >      ncn-s003: Firmware Revision         : 2.33
   >      ncn-s003:  Product Version       :
   >      ncn-s003:  Product Version       : 10/30/2020
   >      ncn-w001:  Board Product         : Marvell 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter
   >      ncn-w001:  Board Product         : ProLiant DL325 Gen10 Plus
   >      ncn-w001: Firmware Revision         : 2.33
   >      ncn-w001:  Product Version       :
   >      ncn-w001:  Product Version       : 10/30/2020
   >      ncn-w002:  Board Product         : Marvell 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter
   >      ncn-w002:  Board Product         : ProLiant DL325 Gen10 Plus
   >      ncn-w002: Firmware Revision         : 2.33
   >      ncn-w002:  Product Version       :
   >      ncn-w002:  Product Version       : 10/30/2020
   >      ncn-w003:  Board Product         : Marvell 2P 25GbE SFP28 QL41232HQCU-HC OCP3 Adapter
   >      ncn-w003:  Board Product         : ProLiant DL325 Gen10 Plus
   >      ncn-w003: Firmware Revision         : 2.33
   >      ncn-w003:  Product Version       :
   >      ncn-w003:  Product Version       : 10/30/2020
   >      ```

2. Refer to the table below, and use the output from the previous step to map the following information:
   - NCN Type: `Board Product` maps to the "Board Product" column
   - NCN BIOS:`Product Version : 10/30/2020` maps to the "Version" column (note: ignore this field for Gigabyte)
   - NCN BMC Firmware: `Firmeware Revision` maps to the rows for the BMC

   > **`IMPORTANT NOTE`** **Do not downgrade firmware** unless directed to by the table(s) below. In the event that newer firmware is found, the administrator should return to their Shasta installation and consider this step completed. Only on rare circumstance will certain downgrades be required.

   | Manufacturer | Board Product | Device Type | Version | Downgrade (Y/n)? | LiveCD Location |
   | :---: | :--- | :---: | ---: | :---: | :--- | 
   | Gigabyte | MZ32-AR0 | BIOS | `C17` (12.84.09 a.k.a. 21.00.00) | `YES` |`http://pit/fw/river/gb/sh-svr-1264up-bios/bios/SPI_UPD/image.bin`
   | Gigabyte | MZ32-AR0 | BMC | 12.84.09 | `YES` |`http://pit/fw/river/gb/sh-svr-1264up-bios/bmc/fw/128409.bin`
   | | | | | |
   | Gigabyte | MZ62-HD0 | BIOS | `C20` 20.03.00 | `NO` |`http://pit/fw/river/gb/sh-svr-3264-bios/bios/SPI_UPD/image.bin`
   | Gigabyte | MZ62-HD0 | BMC | 12.84.09 | `NO` |`http://pit/fw/river/gb/sh-svr-3264-bios/bmc/fw/128409.bin`
   | Gigabyte | MZ62-HD0 | CMC | 62.84.02 | `NO` |`http://pit/fw/river/gb/sh-svr-3264-bios/bmc/fw/628402.bin`
   | | | | | |
   | Gigabyte | MZ92-FS0 | BIOS | `C20` 20.03.00 | `NO` |`http://pit/fw/river/gb/sh-svr-5264-gpu-bios/bios/SPI_UPD/image.bin`
   | Gigabyte | MZ92-FS0 | BMC | 12.84.09 | `NO` |`http://pit/fw/river/gb/sh-svr-5264-gpu-bios/bmc/fw/128409.bin`
   | | | | | |
   | HPE | `A42` ProLiant DL385 Gen10 Plus | BIOS | 10/30/2020 1.38 | `NO` | `http://pit/fw/river/hpe/A42_1.38_10_30_2020.signed.flash` | 
   | HPE | `A43` ProLiant DL325 Gen10 Plus | BIOS | 10/30/2020 1.38 | `NO` | `http://pit/fw/river/hpe/A43_1.38_10_30_2020.signed.flash` | 
   | HPE | iLO5 | BMC | 2.33 | `NO` |`http://pit/fw/river/hpe/ilo5_233.bin` |
   | | | | | |
   | CRAY | EX235n | BIOS | ex235n.bios-1.0.3 | `NO` | `http://pit/fw/mountain/cray/ex235n.bios-1.0.3.tar.gz` | 
   | CRAY | EX425 | BIOS | ex425.bios-1.4.3 | `NO` | `http://pit/fw/mountain/cray/ex425.bios-1.4.3.tar.gz` |

3. For each server that is **lower** than the items above (except for any downgrade exceptions), run through
these guides to update them:
   - [Gigabyte Upgrades](#gigabyte-upgrades)
   - [HPE (iLO) Upgrades](#hpe-ilo-upgrades)

<a name="gigabytes-upgrades"></a>
<a name="gigabyte-upgrades"></a>
### Gigabyte Upgrades

> TODO: Get directions.

<a name="hpe-ilo-upgrades"></a>
### HPE (iLO) Upgrades

Firmware is located on the LiveCD (versions 1.4.6 or higher).

<a name="pre-reqs"></a>
#### Pre-Reqs

- BMCs are reachable; dnsmasq is setup and BMCs show in `/var/lib/misc/dnsmasq.leases`
- Servers can be `off`
- Static entries in dnsmasq are a bonus; helpful but unnecessary.

<a name="gui"></a>
#### GUI

1. From the administrators own machine, SSH tunnel (`-L` creates the tunnel, and `-N` prevents a shell and stubs the connection). One at a time, or all together.
    ```bash
    ssh -L 6443:ncn-m002-mgmt:443 -N $system_name-ncn-m001
    ssh -L 7443:ncn-m003-mgmt:443 -N $system_name-ncn-m001
    ssh -L 8443:ncn-w001-mgmt:443 -N $system_name-ncn-m001
    ssh -L 9443:ncn-w002-mgmt:443 -N $system_name-ncn-m001
    ssh -L 10443:ncn-w003-mgmt:443 -N $system_name-ncn-m001
    ssh -L 11443:ncn-s001-mgmt:443 -N $system_name-ncn-m001
    ssh -L 12443:ncn-s002-mgmt:443 -N $system_name-ncn-m001
    ssh -L 13443:ncn-s003-mgmt:443 -N $system_name-ncn-m001
    ```
2. One at a time in (to prevent log-outs from duplicate SSL/CA) open each and run through the nested steps:

         https://127.0.0.1:6443
         https://127.0.0.1:7443
         https://127.0.0.1:8443
         https://127.0.0.1:9443
         https://127.0.0.1:10443
         https://127.0.0.1:11443
         https://127.0.0.1:12443
         https://127.0.0.1:13443

      1. Login with the default credentials.
      2. On the _Left_, select "Firmware & OS Software"
      3. On the _Right_, select "Upload Firmware"
      4. Select "Remote File" and "Confirm TPM override", and then choose your firmware file:
         ![fw-ilo-4](img/fw-ilo-4.png)
      5. Press **`Flash`** and wait for the upload and flash to complete. iLO may reboot after flash.
      6. Now grab the iLO5 Firmware the same way:
         1. On the _Right_, select "Upload Firmware"
         2. Select "Remote File" and "Confirm TPM override", and then choose your firmware file:
            ![fw-ilo-5](img/fw-ilo-5.png)
         3. Press **`Flash`** and wait for the upload and flash to complete. iLO may reboot after flash.
      7. Cold boot the node, or momentarily press the button (GUI button) to power it on.

3. After Flashing the node, the SSH tunnel may be severed.

<a name="redfish"></a>
#### Redfish

![redfish.png](img/3rd/redfish.png)

> **Not Ready** This LiveCD bash script is broken, and will be fixed. It will allow remote BIOS and firmware updates and checkout from the pit node.

1. Set login vars for redfish™
    ```bash
   export username=root
   export password=changeme
   ```
2. Invoke `mfw` with the matching firmware (check `ls 1 /var/www/fw/river/hpe` for a list)
    ```bash
    pit# /root/bin/mfw A43_1.30_07_18_2020.signed.flash
    ```

3. Watch status:
    ```bash
    pit# curl -sk -u $username:$password https://$1/redfish/v1/UpdateService | jq |grep -E 'State|Progress|Status'"
    ```

<a name="component-firmware-checkout"></a>
## Component Firmware Checkout

This covers PCIe devices.

> Note: The Mellanox firmware can be updated to minimum spec. using `mlxfwmanager`. The `mlxfwmanager` will fetch updates from online, or it can use a local file (or local web server such as http://pit/).

Find more information for each vendor below:

- [Marvell Upgrades](#marvell-upgrades)
- [Mellanox Upgrades](#mellanox-upgrades)

| Vendor | Model | PSID | Version | Downgrade (Y/n)? | LiveCD Location |
   | :--- | :--- | --- | ---: | :---: | :--- | 
| Marvell | QL41232HQCU-HC |   | 08.50.78 | `NO` | `unavailable`
| Mellanox | MCX416A-BCA* | `CRAY000000001` | 12.28.2006 | `NO` | `http://pit/fw/pcie/images/CRAY000000001.bin`
| Mellanox | MCX515A-CCA* | `MT_0000000011` and `MT_0000000591` | 16.28.2006 | `NO` | `http://pit/fw/pcie/images/MT_0000000011.bin`


<a name="marvell-upgrades"></a>
### Marvell Upgrades

> There are no upgrades at this time for Marvell.

<a name="mellanox-upgrades"></a>
### Mellanox Upgrades

Shasta 1.4 NCNs are # Print name and current state; on an NCN or on the liveCD.

<a name="enable-tools"></a>
#### Enable Tools

MST needs to be started for the tools to work.

```bash
linux# mst status
Starting MST (Mellanox Software Tools) driver set
Loading MST PCI module - Success
Loading MST PCI configuration module - Success
Create devices
Unloading MST PCI module (unused) - Success
```

<a name="check-current-firmware"></a>
#### Check Current Firmware

**Some nodes will not have any Mellanox cards.** If `mlxfwmanager` returns with no devices found after `mst start` was run then this
section should be skipped for that NCN.

1. Start and Run Mellanox Firmware services to check for firmware revision:
   ```bash
   linux# mlxfwmanager
   Querying Mellanox devices firmware ...

   Device #1:
   ----------

     Device Type:      ConnectX5
     Part Number:      MCX515A-CCA_Ax_Bx
     Description:      ConnectX-5 EN network interface card; 100GbE single-port QSFP28; PCIe3.0 x16; tall bracket; ROHS R6
     PSID:             MT_0000000011
     PCI Device Name:  /dev/mst/mt4119_pciconf1
     Base GUID:        506b4b030028505c
     Base MAC:         506b4b28505c
     Versions:         Current        Available
        FW             16.28.4000     N/A
        PXE            3.6.0103       N/A
        UEFI           14.21.0021     N/A

     Status:           No matching image found

   Device #2:
   ----------

     Device Type:      ConnectX5
     Part Number:      MCX515A-CCA_Ax_Bx
     Description:      ConnectX-5 EN network interface card; 100GbE single-port QSFP28; PCIe3.0 x16; tall bracket; ROHS R6
     PSID:             MT_0000000011
     PCI Device Name:  /dev/mst/mt4119_pciconf0
     Base GUID:        98039b03001eda3c
     Base MAC:         98039b1eda3c
     Versions:         Current        Available
        FW             16.28.4000     N/A
        PXE            3.6.0103       N/A
        UEFI           14.21.0021     N/A

     Status:           No matching image found
   ```

2. Download and run the update on the NCN
   ```bash
   ncn# curl -O http://pit/fw/pcie/images/MT_0000000011.bin
   ncn# curl -O http://pit/fw/pcie/images/CRAY000000001.bin
   ncn# mlxfwmanager -u -i ./MT_0000000011.bin -y
   ncn# mlxfwmanager -u -i ./CRAY000000001.bin -y
   ```
4. Update the PIT node:
   ```bash
   ncn# mlxfwmanager -u -i /var/www/fw/pcie/images/MT_0000000011.bin -y
   ncn# mlxfwmanager -u -i /var/www/fw/pcie/images/CRAY000000001.bin -y
   ```

<a name="optional-online-update"></a>
#### Optional Online Update

The non-HSN PCIe cards, like the NCN's management PCIe cards, can obtain updates from the Internet:
- When firmware is not available on the LiveCD _and_
- Internet access is available to the NCN

Simply run this to update the card, after finding the PCI Device Name in the `mlxfwmanager` output:

```bash
ncn# mlxfwmanager -u --online -d /dev/mst/<mst_device_id>
```

[5]: https://www.marvell.com/products/hpe/hpe-industry-standard-adapters.html
[6]: http://15.213.147.156/HPC_Fabric/Mellanox/Mellanox%20HDR/ConnectX-6%20EN%20network%20interface%20card%20100GbE%20single-port%20QSFP28%20MCX515A-CCAT%20(Cray%20E1000)/
[7]: http://15.213.147.156/HPC_Fabric/Mellanox/Mellanox%20EDR/HPE%20Ethernet%20100Gb%201-port%20QSFP28%20MCX515A-CCAT%20PCIe3%20x16%20Adapter%20P313246-H21%20(Oku)/16.28.4000%20GA/
[8]: https://www.mellanox.com/support/firmware/connectx4en
[10]: https://cray.my.salesforce.com/apex/Home