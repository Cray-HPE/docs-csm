# Redeploy Fabric Manager Nodes

> **OPTIONAL:** This procedure is only applicable if Fabric Manager nodes were deployed during the CSM installation.

Although Fabric Manager Nodes (FMNs) were deployed during the CSM installation, the initial deployment would not include the final image
with all necessary components. Once the other HPE Cray EX software products have been installed via the Install and Upgrade Framework (IUF),
the FMNs need to be redeployed with the new customized image.

## Prerequisites

- CSM installation has been completed
- Additional HPE Cray EX software products have been installed via IUF
- The Cray CLI is configured and authenticated
- SAT is configured and authenticated

## Procedure

### 1. Build the FMN image

Follow the procedure in the **FMN Base Image Creation** section of [Configure FM (Fabric Manager) On Baremetal](Configure_FM_On_Baremetal.md#fmn-base-image-creation) to build the new FMN base image.

This procedure will:

- Create a `sat bootprep` configuration file for FMN
- Execute `sat bootprep run` to generate the new FMN image and upload it to S3
- Produce a new IMS image ID for the customized FMN image

### 2. Update BSS with the new FMN image

Once the new FMN image has been built and uploaded to S3, update the boot parameters in the Boot Script Service (BSS) to point the FMNs to the new image.

1. (`ncn-mw#`) Set an environment variable for the new IMS image ID.

    After running `sat bootprep run`, obtain the IMS resultant image ID from the output or from the CFS session:

    ```bash
    NEW_IMS_IMAGE_ID="<IMS_IMAGE_ID_FROM_BOOTPREP>"
    ```

1. (`ncn-mw#`) Determine the component names (xnames) of the FMNs.

    ```bash
    cray hsm state components list --role Management --subrole FabricManager --format json | jq -r '.Components[].ID'
    ```

    Example output:

    ```text
    x3000c0s28b0n0
    x3000c0s29b0n0
    ```

1. (`ncn-mw#`) Update the boot parameters for the FMNs.

    Replace the `<xname>` placeholders with the actual xnames of the FMNs.

    ```bash
    /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh \
       -p "${NEW_IMS_IMAGE_ID}" <xname1> <xname2>
    ```

    For example:

    ```bash
    /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh \
       -p "${NEW_IMS_IMAGE_ID}" x3000c0s28b0n0 x3000c0s29b0n0
    ```

1. (`ncn-mw#`) Verify the boot parameters have been updated.

    ```bash
    cray bss bootparameters list --name <xname> --format json | jq -r '.[0].params' | grep metal.server
    ```

    The output should show the new IMS image ID in the `metal.server` parameter.

1. (`ncn-mw#`) Set `metal.no-wipe=0` to allow the disk to be wiped during redeployment.

    For each FMN, set `metal.no-wipe=0`:

    ```bash
    TARGET_XNAME=<fmn-xname>
    csi handoff bss-update-param --set metal.no-wipe=0 --limit ${TARGET_XNAME}
    ```

    For example:

    ```bash
    TARGET_XNAME=x3000c0s28b0n0
    csi handoff bss-update-param --set metal.no-wipe=0 --limit ${TARGET_XNAME}
    ```

    Repeat for each FMN.

1. (`ncn-mw#`) Verify the change:

    ```bash
    cray bss bootparameters list --name ${TARGET_XNAME} --format=json | jq -r '.[0].params' | grep metal.no-wipe
    ```

    The output should show `metal.no-wipe=0`.

### 3. Redeploy the FMNs

After updating BSS with the new image and setting `metal.no-wipe=0`, redeploy the FMNs to apply the new image.

Follow the [Boot NCN](../node_management/Add_Remove_Replace_NCNs/Boot_NCN.md) procedure for each Fabric Manager node. This procedure will:

- Set the PXE boot option and power on the node
- Monitor the boot process
- Set `metal.no-wipe=1` after successful boot to preserve data on future reboots

**Note:** Skip the sections in Boot NCN that are specific to master, worker, or storage nodes (such as verifying cluster membership or Ceph operations).

### 4. Join Fabric Manager nodes to Spire

After the Fabric Manager nodes have been redeployed and are running with the new image, join them to Spire to avoid issues with Spire tokens.

1. (`ncn-mw#`) Join Spire on the Fabric Manager nodes.

    ```bash
    /opt/cray/platform-utils/spire/fix-spire-on-fmn.sh
    ```
