# Enabling Fabric Manager (FM) On baremetal post CSM Upgrade

## Overview

* Fabric Manager Nodes (FMNs) can be added only after the CSM upgrade has been completed.
* By default, Fabric Manager on baremetal is disabled.
* This document describes the procedures for providing the base OS image, provisioning storage LUNs, and configuring the necessary networking to support
  Fabric Manager on  baremetal following the CSM upgrade.
* Once enabled, Fabric Manager on baremetal cannot be disabled.
  
## Post upgrade of CSM from 1.7.0 to 1.7.1

Post CSM Upgrade from 1.7.0 to CSM 1.7.1, if an administrator wishes to enable Fabric Manager on baremetal, they must follow below procedure.

## Prerequisites

### Update SHCD with FMN (Fabric Manager Node) Information

The administrator must update the SHCD to include the placement and cabling details of the new FMNs.

### Configure FMN BMC

Verify that the BMC of each FMN is configured with the correct root user credentials.

### Perform CANU validation

* Validate SHCD with respect to FMNs
* Map FMNs in the SHCD to the node type:Management_FabricManager when building the CCJ file
* Generate switch configuration for the node based on the new Role: Management , SubRole: FabricManager pairing

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

## FMN Node Image Customization and Deployment Procedure

The FabricManager subrole has been introduced to facilitate FMN node discovery and configuration. Corresponding updates have been made to `ncn_nodes.yaml` and `ncn_initrd.yaml` to support customization of the FMN base image— a non-Kubernetes image containing only essential artifacts. This customization is performed using the `csm.fm.baremetal` Ansible role, executed under the `Management_FabricManager` host. The following steps detail the process for generating the FMN base image with the required components and deploying it to FMN nodes.

### Create the base image (only base OS; no Fabric Manager) for FMN

Adapt and customize the current NCN Kubernetes image for compatibility with FMN node requirements [../../operations/configuration_management/Management_Node_Image_Customization.md]

#### Fabric Manager Boot Preparation

Create `sat bootprep` configuration file (`fmn_bootprep.yaml`) for FMN as below.

**Note:** Ensure that the `fmn_bootprep.yaml` configuration file is updated with the official released versions before proceeding.

For Example:

```yaml
schema_version: 1.0.2
configurations:
- name: fmn-bm-default-configuration
  layers:
  - name: fmn-nodes-bm
    playbook: ncn_nodes.yml
    git:
     commit: <commit-id-from-csm-config>
     url: https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git
  - name: fmn-initrd-bm
    playbook: ncn-initrd.yml
    git:
     commit: <commit-id-from-csm-config>
     url: https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git
images:
- name: fabricmanager-bm-node-image-1.0.0
  base:
    product:
      name: csm
      version: 1.7.1
      type: image
      filter:
        prefix: secure-kubernetes
  configuration: fmn-bm-default-configuration
  configuration_group_names:
  - Management_Fabric
```

#### New FMN image creation and uploade to S3 

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

## FMN add procedure

Follow NCN add procedure to add FMN nodes to CSM:

https://github.com/Cray-HPE/docs-csm/blob/release/1.7/operations/node_management/Add_Remove_Replace_NCNs/Add_Remove_Replace_NCNs.md
Scripts source (HSM/ SLS/ BSS): Cray-HPE/docs-csm at CASM-5647-5739
Note: Interface level differences to be considered while following NCN add procedure for FMNs

https://github.com/Cray-HPE/docs-csm/blob/release/1.7/operations/node_management/Add_Remove_Replace_NCNs/Add_Remove_Replace_NCNs.md#prerequisites
As part of the above prerequisites, there is a new prompt added to confirm if the node getting added is an FMN or not.

https://github.com/Cray-HPE/docs-csm/blob/release/1.7/operations/node_management/Add_Remove_Replace_NCNs/Add_NCN_Data.md#add-the-ncn-to-bss-hsm-and-sls
 As part of the above step, include the new parameter --fmn-image-id only for the FM node. The value for this parameter should be the image ID generated in Step 6.4. 

By the end of this procedure, SLS, HSM, BSS would be FMN data. Following validations could be performed if needed for confirmations -

SLS hardware should list the new nodes
Eg - cray sls hardware describe x3000c0s28b0n0 

IPs should be allocated and made available for FMNs in all of SLS networks
Note - NMN and HMN should be having additional FMN VIPs also allocated

Eg - cray sls search networks list --name NMN --format json 

HSM ethernet interfaces should be updated with the same allocated IPs.
Eg - cray hsm inventory ethernetInterfaces list --component-id x3000c0s28b0n0 --format json 

BSS should be updated with new hosts entries for FMN with proper configurations
Note - BSS global parameters also needs to be updated with FMN IPs(VIP not included)

Eg - cray bss bootparameters list --format json --name x3000c0s28b0n0 

Eg - cray bss bootparameters list --hosts Global --format json 


## Boot FMN Nodes with iPXE

Example:

iPXE boot commands
NODE=fmn001 (or) fmn002
 
fmn001 - x3000c0s28b0n0
 
fmn002 - x3000c0s29b0n0
 
 BMC="${NODE}-mgmt"; echo $BMC
read -r -s -p "${BMC} root password: " IPMI_PASSWORD
export IPMI_PASSWORD
cray console interact <xname>       (In a different screen to check the progress of the boot)
echo ${BMC}

```bash
ipmitool -I lanplus -U root -E -H "${BMC}" chassis power status
ipmitool -I lanplus -U root -E -H "${BMC}" chassis bootdev pxe options=efiboot
ipmitool -I lanplus -U root -E -H "${BMC}" chassis power off
ipmitool -I lanplus -U root -E -H "${BMC}" chassis power status
ipmitool -I lanplus -U root -E -H "${BMC}" chassis power on
ipmitool -I lanplus -U root -E -H "${BMC}" chassis power status
```
