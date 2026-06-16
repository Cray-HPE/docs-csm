# Configure FM (Fabric Manager) On `Baremetal`

This document describes the procedure for customizing and deploying the base FMN OS image along with provisioning storage `LUNs`,
and configuring the necessary networking to support Fabric Manager on `baremetal` following the CSM upgrade.

## Requirements

* Hardware requirements - 2 bare-metal nodes with dedicated boot and data disks
* Software requirements - OS (SLES SP7), CSM services like CANU, HSM, SLS, BSS, CSI, CFS, Ansible playbooks for FMN

## Notes

* Fabric Manager Nodes (`FMNs`) can be added only after the CSM upgrade has been completed.
* By default, Fabric Manager would be running on Kubernetes as a Kubernetes pod
* After Fabric Manager is migrated from a Kubernetes pod to bare-metal infrastructure, it cannot be reverted.

## Post upgrade of CSM to 1.7.1

Post CSM Upgrade from 1.7.0 to CSM 1.7.1, if an administrator wishes to enable Fabric Manager on baremetal, they must follow below procedure.

* Step 1: [FMN Prerequisites](#fmn-prerequisites)
* step 2: [FMN Pre Boot](#fmn-pre-boot)
    * [FMN Base Image Creation](#fmn-base-image-creation)
    * [Add NCN Procedure](#add-ncn-procedure)
* Step 3: [FMN Booting](#fmn-booting)
* Step 4: [FMN Post Boot](#fmn-post-boot)
    * [Validation](#validation)
    * [Install Fabric Manager on FM baremetal nodes](#install-fabric-manager-on-fm-baremetal-nodes)

## FMN Prerequisites

### Update SHCD with FMN (Fabric Manager Node) Information

The administrator must update the SHCD to include the placement and cabling details of the new FMNs.

### Configure FMN BMC

Verify that the BMC of each FMN is configured with the correct root user credentials.

## FMN Pre Boot

### FMN Base Image Creation

The FMN base image creation process supports node discovery, configuration, and base image customization. The base image contains only the essential artifacts required for deployment.

The following steps details the process for generating the FMN image.

#### Create FMN base image (only base OS; no Fabric Manager)

Adapt and customize the current NCN Kubernetes image for compatibility with FMN node requirements.

##### FMN Boot Preparation

Create `sat bootprep` configuration file (`fmn_bootprep.yaml`) for FMN as below.

**Note:** Ensure that the `fmn_bootprep.yaml` configuration file is updated with the official CSM released versions and the appropriate commits on playbooks before proceeding.

For Example:

```bash
ncn-m001:~ # cat fmn_bootprep.yaml
```

```yaml
schema_version: 1.0.2
configurations:
- name: fmn-bm-default-configuration
  layers:
  - name: fmn-nodes-bm
    playbook: ncn_nodes.yml
    git:
     commit: 64c8753fbc3143ec8b889a755a445b5bbc8007fd
     url: https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git
  - name: fmn-initrd-bm
    playbook: ncn-initrd.yml
    git:
     commit: 64c8753fbc3143ec8b889a755a445b5bbc8007fd
     url: https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git
images:
- name: fabricmanager-bm-node-image-1.0.0
  base:
    product:
      name: csm
      version: 1.7.1-beta.10
      type: image
      filter:
        prefix: secure-kubernetes
  configuration: fmn-bm-default-configuration
  configuration_group_names:
  - Management_Fabric
```

##### New FMN base image creation and upload to S3

Execute the commands below on any master node to generate the new FMN image and upload it to the S3 storage.

(ncn-m#) First set `bootprep` file path:

```bash
# BOOTPREP_FILE_PATH=./fmn_bootprep.yaml
```

(ncn-m#) Now execute the `sat bootprep run` command below to generate the new base image and upload it to S3.

```bash
sat bootprep run \
      --limit images --limit configurations \
      --overwrite-images --overwrite-configs \
      --format json \
      --cfs-version v3
      --bos-version v2 \
      $BOOTPREP_FILE_PATH
```

**Note:** Using the `--overwrite-images` option in the command above will overwrite any previously uploaded images in S3.

**Note:** After creating the FMN base image above, follow below steps to add FMN nodes to CSM:

### Add NCN procedure

#### Allocate NCN IP Addresses

Follow [`Step-1`](https://github.com/Cray-HPE/docs-csm/blob/CASM-5740-fm-ha/operations/node_management/Add_Remove_Replace_NCNs/Add_Remove_Replace_NCNs.md#add-ncn-procedure)

#### Add NCN data

Follow [`Step-3`](https://github.com/Cray-HPE/docs-csm/blob/CASM-5740-fm-ha/operations/node_management/Add_Remove_Replace_NCNs/Add_Remove_Replace_NCNs.md#add-ncn-procedure)

#### Generate Switch Configuration With CANU

For Example:

```bash
canu generate network config -a TDS --csm 1.7 --custom-config custom_switch_config.yaml --edge Arista --sls-file sls_input_file.json --ccj surtur-ccj.json --folder output (--enable-nmn-isolation --nmn-pvlan <pvid>)
```

#### Validate the generated switch configuration against the network switches

* TDS style systems have the management nodes plugged directly into the spine switches, most will only have a single leaf-bmc switch.
* Systems that use the "Full" architecture will have the management nodes plugged into the leaf switches.

The configuration generated here will contain updates for the leaf-bmc switch(`es`) for the Fabric Manager node BMCs and updates to either the spine switches or the leaf switches for the bonded connection.

For Example:

```bash
canu validate switch config --ip 10.254.0.4 --generated output/sw-leaf-bmc-001.cfg
```

**Note:** CANU will likely suggest the removal of the `snmpv3` user, this is because the SNMP configuration is not held in the `custom_config.yaml` file because it's not permitted to store secrets in GitHub. Do NOT remove this configuration from the switch.

Take extreme care when manipulating ACLs, if CANU suggests moving a "permit any ..." rule be sure to create the new rule before removing the old one. It is possible to lose access to the switch if the ACLs are not applied in the correct order.

## FMN Booting

Upon completion of the FMNs add procedure, the corresponding FMN entries will be populated in SLS, HSM, and BSS. The required network, storage and other cloud-init configurations are added to BSS and would be applied when the FMN node boots.

Proceed to boot the FMN nodes (using iPXE boot commands) with the FMN bare-metal base image [Boot NCN](../node_management/Add_Remove_Replace_NCNs/Boot_NCN.md#boot-ncn).

## FMN Post Boot

### Validation

#### Validate base FMN nodes bring up successful completion

1. Check if we are able to access both FMN nodes (`fmn001` and `fmn002`):

```bash
ncn-m001:~ # ssh fmn001
Last login: Thu Dec  4 11:25:30 2025 from 10.252.1.10
...
```

```bash
ncn-m001:~ # ssh fmn002
Last login: Thu Dec  4 05:03:46 2025 from 10.252.1.10
...
```

1. Check if both FMN nodes are shown under `sat status`:

```bash
ncn-m001:~ # sat status | grep fmn
```

```text
INFO: All values for 'Most Recent Session Template' are 'MISSING', omitting key.
| x3000c0s28b0n0 | fmn001    | Node | 100011   | On        | OK   | True    | X86  | River | Management  | FabricManager | Sling    | True    | fmn-bm-default-configuration | configured           | 0           | stable      | MISSING                              | MISSING                              |
| x3000c0s29b0n0 | fmn002    | Node | 100012   | On        | OK   | True    | X86  | River | Management  | FabricManager | Sling    | True    | fmn-bm-default-configuration | configured           | 0           | stable      | MISSING                              | MISSING                              |
```

1. Optionally check more details on the FMN nodes

For Example:

```bash
ncn-m001:~ # XNAME=x3000c0s28b0n0
```

```bash
ncn-m001:~ # cray hsm state components describe "${XNAME}" --format toml
```

```text
ID = "x3000c0s28b0n0"
Type = "Node"
State = "On"
Flag = "OK"
Enabled = true
Role = "Management"
SubRole = "FabricManager"
NID = 100011
NetType = "Sling"
Arch = "X86"
Class = "River"
```

#### Validate FMN required networking configuration

Check NMN, CMN, HMN, CHN, metal and virtual IP configuration for both FMN nodes (`fmn001` and `fmn002`).

```bash
ncn-m001:~ # cray sls networks list
```

```text
...
[[results.ExtraProperties.Subnets.IPReservations]]
Aliases = [ "fmn001-cmn", "time-cmn", "time-cmn.local",]
Comment = "x3000c0s28b0n0"
IPAddress = "10.102.193.42"
Name = "fmn001"

...
[[results.ExtraProperties.Subnets.IPReservations]]
Aliases = [ "fmn001-mtl", "time-mtl", "time-mtl.local",]
Comment = "x3000c0s28b0n0"
IPAddress = "10.1.1.10"
Name = "fmn001"
...

[[results.ExtraProperties.Subnets.IPReservations]]
Aliases = [ "fmn001-nmn", "time-nmn", "time-nmn.local", "x3000c0s28b0n0", "fmn001.local",]
Comment = "x3000c0s28b0n0"
IPAddress = "10.252.1.12"
Name = "fmn001"

[[results.ExtraProperties.Subnets.IPReservations]]
Aliases = [ "fmn-vip.local",]
Comment = "fmn-virtual-ip"
IPAddress = "10.252.1.13"
Name = "fmn-vip"

[[results.ExtraProperties.Subnets.IPReservations]]
Aliases = [ "fmn001-mgmt",]
Comment = "x3000c0s28b0"
IPAddress = "10.254.1.21"
Name = "x3000c0s28b0"

[[results.ExtraProperties.Subnets.IPReservations]]
Aliases = [ "fmn001-hmn", "time-hmn", "time-hmn.local",]
Comment = "x3000c0s28b0n0"
IPAddress = "10.254.1.21"
Name = "fmn001"
...

[[results.ExtraProperties.Subnets.IPReservations]]
Aliases = [ "fmn001-chn", "time-chn", "time-chn.local",]
Comment = "x3000c0s28b0n0"
IPAddress = "10.102.193.206"
Name = "fmn001"
```

#### SLS hardware should list the new nodes

For Example:

```bash
cray sls hardware describe x3000c0s28b0n0
```

**Note:** NMN and HMN should be having additional FMN VIPs also allocated.

For Example:

```bash
cray sls search networks list --name NMN --format json
```

#### HSM `ethernetInterfaces` should be updated with the same allocated IPs

For Example:

```bash
cray hsm inventory ethernetInterfaces list --component-id x3000c0s28b0n0 --format json
```

#### BSS should be updated with new hosts entries for FMN with proper configurations

**Note:** BSS global parameters also needs to be updated with FMN IPs(VIP not included).

For Example:

```bash
cray bss bootparameters list --format json --name x3000c0s28b0n0
```

```bash
cray bss bootparameters list --hosts Global --format json
```

#### Join Fabric Manager nodes to Spire

After the Fabric Manager nodes have been deployed and are running, join them to Spire to avoid issues with Spire tokens.

```bash
ncn-m001:~ # /opt/cray/platform-utils/spire/fix-spire-on-fmn.sh
```

#### Validate FMN required storage configuration (LVM partitions)

Check if both LVM partitions `/dev/mapper/metalvg0-SCFIRMWARE` and `/dev/mapper/metalvg0-SLINGSHOT` created and mounted under `/opt/cray/FW/sc-firmware` and `/opt/slingshot` respectively on both FMN nodes (`fmn001` and `fmn002`).

```bash
fmn001:~ # lsblk
```

```text
NAME                      MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
loop0                       7:0    0   2.2G  1 loop  /run/rootfsbase
sda                         8:0    0   3.5T  0 disk
├─sda1                      8:1    0   476M  0 part
│ └─md127                   9:127  0 475.9M  0 raid1 /metal/recovery
├─sda2                      8:2    0  22.8G  0 part
│ └─md125                   9:125  0  22.8G  0 raid1 /run/initramfs/live
├─sda3                      8:3    0 139.7G  0 part
│ └─md124                   9:124  0 139.6G  0 raid1 /run/initramfs/overlayfs
└─sda4                      8:4    0 139.7G  0 part
  └─md126                   9:126  0 279.1G  0 raid0
    ├─metalvg0-SCFIRMWARE 254:0    0    80G  0 lvm   /opt/cray/FW/sc-firmware
    └─metalvg0-SLINGSHOT  254:1    0   120G  0 lvm   /opt/slingshot
sdb                         8:16   0   3.5T  0 disk
├─sdb1                      8:17   0   476M  0 part
│ └─md127                   9:127  0 475.9M  0 raid1 /metal/recovery
├─sdb2                      8:18   0  22.8G  0 part
│ └─md125                   9:125  0  22.8G  0 raid1 /run/initramfs/live
├─sdb3                      8:19   0 139.7G  0 part
│ └─md124                   9:124  0 139.6G  0 raid1 /run/initramfs/overlayfs
└─sdb4                      8:20   0 139.7G  0 part
  └─md126                   9:126  0 279.1G  0 raid0
    ├─metalvg0-SCFIRMWARE 254:0    0    80G  0 lvm   /opt/cray/FW/sc-firmware
    └─metalvg0-SLINGSHOT  254:1    0   120G  0 lvm   /opt/slingshot
sdc                         8:32   0   3.5T  0 disk
sdd                         8:48   0   3.5T  0 disk
```

```bash
fmn001:~ # mount | grep /opt/cray/FW/sc-firmware
/dev/mapper/metalvg0-SCFIRMWARE on /opt/cray/FW/sc-firmware type ext4 (rw,relatime,stripe=256)
```

```bash
fmn001:~ # mount | grep /opt/slingshot
/dev/mapper/metalvg0-SLINGSHOT on /opt/slingshot type ext4 (rw,relatime,stripe=256)
```

#### Validate addition of FM required repositories

Check if all the required repos are added on both FMN nodes (`fmn001` and `fmn002`) in order to install prerequisite OS RPMs required during Slingshot Software installation.

For Example:

```bash
fmn001:~ # zypper lr
```

```text
Repository priorities are without effect. All enabled repositories share the same priority.

#  | Alias                                                                 | Name                                             | Enabled | GPG Check | Refresh
---+-----------------------------------------------------------------------+--------------------------------------------------+---------+-----------+--------
 1 | SUSE-25.7.250709-SLE-Module-Development-Tools-15-SP6-x86_64-Pool      | SUSE-25.7.250709-SLE-Module-Development-Tools--> | Yes     | (  ) No   | Yes
 2 | SUSE-25.7.250709-SLE-Module-Legacy-15-SP7-x86_64-Updates              | SUSE-25.7.250709-SLE-Module-Legacy-15-SP7-x86_-> | Yes     | (  ) No   | Yes
 3 | SUSE-25.7.250709-SLE-Module-Server-Applications-15-SP7-x86_64-Pool    | SUSE-25.7.250709-SLE-Module-Server-Application-> | Yes     | (  ) No   | Yes
 4 | SUSE-SLE-Module-Basesystem-15-SP6-x86_64-Pool                         | SUSE-SLE-Module-Basesystem-15-SP6-x86_64-Pool    | Yes     | (  ) No   | Yes
 5 | SUSE-SLE-Module-Containers-15-SP7-x86_64-Updates                      | SUSE-SLE-Module-Containers-15-SP7-x86_64-Updates | Yes     | (  ) No   | Yes
 6 | csm-embedded                                                          | csm-embedded                                     | Yes     | (  ) No   | Yes
 ...
```

### Install Fabric Manager on FM baremetal nodes

For install/ upgrade Fabric Manager on the FMNs please refer section "3 Install HPE Slingshot Fabric Manager software on bare metal servers" in _HPE Slingshot Installation Guide for CSM_ PDF.
