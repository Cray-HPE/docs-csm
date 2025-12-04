# Configure FM (Fabric Manager) On Baremetal

This document describes the procedure for customizing and deploying the base FMN OS image along with provisioning storage LUNs, 
and configuring the necessary networking to support Fabric Manager on  baremetal following the CSM upgrade.
  
## Requirements

* Hardware requirements - 2 bare-metal nodes with dedicated boot and data disks
* Software requirements - OS (SLES SP7), CSM services like CANU, HSM, SLS, BSS, CSI, CFS, ansible playbooks for FMN

## Note:

* Fabric Manager Nodes (`FMNs`) can be added only after the CSM upgrade has been completed.
* By default, Fabric Manager on baremetal is disabled.
* Once enabled, Fabric Manager on baremetal cannot be disabled.
  
## Post upgrade of CSM from 1.7.0 to 1.7.1

Post CSM Upgrade from 1.7.0 to CSM 1.7.1, if an administrator wishes to enable Fabric Manager on baremetal, they must follow below procedure.

* Step 1: [FMN Prerequisites](#fmn-prerequisites)
* step 2: [FMN Pre Boot](#fmn-pre-boot)
    * [FMN Base Image Creation](#fmn-base-image-creation)
    * [Add FMN Nodes to CSM](#add-fmn-nodes-to-csm)
    * [Update Switch Configuration With CANU](#update-switch-configuration-with-canu)
* Step 3: [FMN Booting](#fmn-booting)
* Step 4: [FMN Post Boot](#fmn-post-boot)
    * [Validation](#validation)
    * [Install Fabric Manager on FM baremetal nodes](#install-fabric-manager-on-fm-baremetal-nodes)
* Step 5: [Uninstall FMN Helm Chart](#uninstall-fmn-helm-chart)

## FMN Prerequisites

### Update SHCD with FMN (Fabric Manager Node) Information

The administrator must update the SHCD to include the placement and cabling details of the new FMNs.

### Configure FMN BMC

Verify that the BMC of each FMN is configured with the correct root user credentials.

### Perform CANU validation

* Validate SHCD with respect to FMNs
* Map FMNs in the SHCD to the node type: `Management_FabricManager` when building the CCJ file
* Generate switch configuration for the node based on the new Role: `Management` , SubRole: `FabricManager` pairing

Validate the SHCD.

**For example:**

``` bash
canu validate shcd -a TDS --shcd "System5 Surtur Shasta River RevA27.xlsx" --tabs edge,25G_10G,NMN,HMN --corners J1,T3,I14,Q55,I16,S21,J20,U41 --edge Arista
```

If the output looks good (Warnings about the CAN switch and SITE connections can be discounted) then generate the CCJ file.

```bash
canu validate shcd -a TDS --shcd "System5 Surtur Shasta River RevA27.xlsx" --tabs edge,25G_10G,NMN,HMN --corners J1,T3,I14,Q55,I16,S21,J20,U41 --edge Arista --json --out surtur-ccj.json
```

Verify that the Fabric Manager nodes are present in the output CCJ file.

```bash
jq -c '.topology[] | select(.common_name|contains("fmn"))' surtur-ccj.json
```

## FMN Pre Boot

### FMN Base Image Creation

The FabricManager subrole has been introduced to facilitate FMN node discovery and configuration. Corresponding updates have been made to `ncn_nodes.yaml` and `ncn_initrd.yaml` to support customization of the FMN base image— a non-Kubernetes image containing only essential artifacts. This customization is performed using the `csm.fm.baremetal` Ansible role, executed under the `Management_FabricManager` host. The following steps detail the process for generating the FMN base image with the required components and deploying it to FMN nodes.

#### Create FMN base image (only base OS; no Fabric Manager)

Adapt and customize the current NCN Kubernetes image for compatibility with FMN node requirements. See (../../operations/configuration_management/Management_Node_Image_Customization.md)

##### FMN Boot Preparation

Create `sat bootprep` configuration file (`fmn_bootprep.yaml`) for FMN as below.

**Note:** Ensure that the `fmn_bootprep.yaml` configuration file is updated with the official released versions before proceeding.

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

##### New FMN base image creation and uploade to S3 

Execute the commands below on any master node to generate the new FMN image and upload it to the S3 storage.

First set `bootprep` file path:
 
```bash
# BOOTPREP_FILE_PATH=./fmn_bootpre.yaml
```

Now execute the `sat bootprep run` command below to generate the new base image and upload it to S3.

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

### Add FMN Nodes to CSM

After creating the FMN base image, add FMN nodes to CSM by following the [NCN add procedure](../../operations/node_management/Add_Remove_Replace_NCNs/Add_Remove_Replace_NCNs.md)

**Note:** 

* Below are the Interface level differences to be considered while following NCN add procedure for FMNs:
    * As part of the [NCNs add prerequisites](../../operations/node_management/Add_Remove_Replace_NCNs/Add_Remove_Replace_NCNs.md#prerequisites), there is a       new
      prompt added to confirm if the node getting added is an FMN or not.
    * As part of the [add NCN to BSS, HSM, and SLS step](../../operations/node_management/Add_Remove_Replace_NCNs/Add_NCN_Data.md#add-the-ncn-to-bss-hsm-and-sls), include
      the new parameter `--fmn-image-id` only for the FM node. The value for this parameter should be the image ID generated in the [FMN base image creation stage](https://github.com/Cray-HPE/docs-csm/blob/CASM-5740-fm-ha/operations/fm_on_baremetal/Configure_FM_On_Baremetal.md#fmn-base-image-creation).

After completion of the NCN add procedure, SLS, HSM, and BSS will contain the corresponding FMN data. 

The following checks can be used to verify that the updates have been correctly applied:

#### SLS hardware should list the new nodes

For Example:

```bash
cray sls hardware describe x3000c0s28b0n0
```

#### IPs should be allocated and made available for FMNs in all of SLS networks

**Note:** NMN and HMN should be having additional FMN VIPs also allocated.

For Example:

```bash
cray sls search networks list --name NMN --format json
```

#### HSM ethernet interfaces should be updated with the same allocated IPs

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

### Update Switch Configuration With CANU

**Note: ** This step cannot be performed until the Fabric Manager nodes have been added to SLS.

In order to generate new configuration the following is required:

* A CCJ file
* Any custom config file specific to the system
* A SLS file that contains the FMNs (`cray sls dumpstate list --format json` may be used to obtain this once SLS has been updated on the running system)
* Knowledge of whether the system has the NMN Isolation feature enabled or not

#### Generate the switch configuration

For Example: 

```bash
canu generate network config -a TDS --csm 1.7 --custom-config custom_switch_config.yaml --edge Arista --sls-file sls_input_file.json --ccj surtur-ccj.json --folder output (--enable-nmn-isolation --nmn-pvlan <pvid>)
```

#### Validate the generated switch configuration against the network switches

* TDS style systems have the management nodes plugged directly into the spine switches, most will only have a single leaf-bmc switch.
* Systems that use the "Full" architecture will have the management nodes plugged into the leaf switches.

The configuration generated here will contain updates for the leaf-bmc switch(es) for the Fabric Manager node BMCs and updates to either the spine switches or the leaf switches for the bonded connection.

For Example:

```bash
canu validate switch config --ip 10.254.0.4 --generated output/sw-leaf-bmc-001.cfg
```

**Note:** CANU will likely suggest the removal of the snmpv3 user, this is because the SNMP configuration is not held in the `custom_config.yaml` file because it's not permitted to store secrets in GitHub. Do NOT remove this configuration from the switch.

Take extreme care when manipulating ACLs, if CANU suggests moving a "permit any ..." rule be sure to create the new rule before removing the old one. It is possible to lose access to the switch if the ACLs are not applied in the correct order.


## FMN Booting

Once the FMNs have been added to the CSM, proceed to boot the FMN nodes (using iPXE boot commands) with the FMN bare-metal base image.

### Set BMC with node name

```bash
BMC="${NODE}-mgmt"; echo $BMC
```

**Note: ** Here the NODE can be `fmn001` (or) `fmn002`. For example, consider `fmn001` with xname `x3000c0s28b0n0` and `fmn002`  with xname `x3000c0s29b0n0`.

### Get and export IPMI credentials

```bash
read -r -s -p "${BMC} root password: " IPMI_PASSWORD
export IPMI_PASSWORD
```

### Open console to check the progress of the upcoming boot 

Run below command in a different terminal to check the progress of the boot which we are going to initiate in the next step.

**Note: ** Here `xname` can be `fmn001 or `fmn002` based on which FMN is getting booted with.

```bash
cray console interact <xname> 
echo ${BMC}
```

### Check the current chassis power status 

```bash
ipmitool -I lanplus -U root -E -H "${BMC}" chassis power status
```
### Set the boot option 

```bash
ipmitool -I lanplus -U root -E -H "${BMC}" chassis bootdev pxe options=efiboot
```

### Power off the chassis 

Power off the chassis:

```bash
ipmitool -I lanplus -U root -E -H "${BMC}" chassis power off
```
Check the chassis power status:

```bash
ipmitool -I lanplus -U root -E -H "${BMC}" chassis power status
```
### Power on the chassis 

Power on the chassis:

```bash
ipmitool -I lanplus -U root -E -H "${BMC}" chassis power on
```

Check the chassis power status:

```bash
ipmitool -I lanplus -U root -E -H "${BMC}" chassis power status
```
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

2. Check if both FMN nodes are shown under `sat status`:

```bash
ncn-m001:~ # sat status | grep fmn
```

```text
INFO: All values for 'Most Recent Session Template' are 'MISSING', omitting key.
| x3000c0s28b0n0 | fmn001    | Node | 100011   | On        | OK   | True    | X86  | River | Management  | FabricManager | Sling    | True    | fmn-bm-default-configuration | configured           | 0           | stable      | MISSING                              | MISSING                              |
| x3000c0s29b0n0 | fmn002    | Node | 100012   | On        | OK   | True    | X86  | River | Management  | FabricManager | Sling    | True    | fmn-bm-default-configuration | configured           | 0           | stable      | MISSING                              | MISSING                              |
```

3. Optionally check more details on the FMN nodes

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

```bash
ncn-m001:~ # XNAME=x3000c0s29b0n0
```

```bash
ncn-m001:~ # cray hsm state components describe "${XNAME}" --format toml
```

```text
ID = "x3000c0s29b0n0"
Type = "Node"
State = "On"
Flag = "OK"
Enabled = true
Role = "Management"
SubRole = "FabricManager"
NID = 100012
NetType = "Sling"
Arch = "X86"
Class = "River"
```

#### Validate FMN required networking configuration

```bash
ncn-m001:~/sav/csm-config # cray sls networks list
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
Aliases = [ "fmn-vip.local",]
Comment = "fmn-virtual-ip"
IPAddress = "10.252.1.13"
Name = "fmn-vip"

[[results.ExtraProperties.Subnets.IPReservations]]
Aliases = [ "fmn001-nmn", "time-nmn", "time-nmn.local", "x3000c0s28b0n0", "fmn001.local",]
Comment = "x3000c0s28b0n0"
IPAddress = "10.252.1.12"
Name = "fmn001"

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

#### Validate FMN required storage configuration (LVM partitions)

#### Validate addition of FM required repositories

### Install Fabric Manager on FM baremetal nodes

For install/ upgrade Fabric Manager on the FMNs please refer [FabricManager Install/ Upgrade](...)

## Uninstall FMN Helm Chart

After FMNs have comeup healthy and Running,  uninstall existing FM helm chart (FM K8s pod) `slingshot-fabric-manager`.
