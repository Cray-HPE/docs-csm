# Create System Configuration Using SHCD

This stage walks the user through creating the configuration payload for the system.

Run the following steps before starting any of the system configuration procedures.

1. (`pit#`) Make the `prep` directory.

   ```bash
   mkdir -pv "${PITDATA}/prep"
   ```

1. (`pit#`) Change into the `prep` directory.

   ```bash
   cd "${PITDATA}/prep"
   ```

## Topics

1. [Validate SHCD](#1-validate-shcd)
1. [Generate topology files](#2-generate-topology-files)
1. [Customize `system_config.yaml`](#3-customize-system_configyaml)
1. [Run CSI](#4-run-csi)
1. [Prepare Site Init](#5-prepare-site-init)
1. [Initialize the LiveCD](#6-initialize-the-livecd)
1. [Next topic](#next-topic)

### 1. Validate SHCD

1. (`pit#`) Download the SHCD to the `prep` directory.

    The SHCD is contained in the administrator's Cray deliverable.

1. Validate the SHCD.

    See [Validate SHCD](../operations/network/management_network/validate_shcd.md) and then return to this page.

### 2. Generate topology files

The following steps use the new, automated method for generating files. The previous step for
[validate SHCD](#1-validate-shcd) generated "paddle" files; these are necessary for generating
the rest of the seed files.

> **NOTE**: The paddle files are temporarily not used due to bugs in the seed file generation software.
> Until these bugs are resolved, the seed files must be manually generated.

If seed files from a prior installation of the same major-minor version of CSM exist, then these can be used and
this step may be skipped.

1. (`pit#`) Create each seed file, unless they already exist from a previous installation.

   - For new installations of CSM that have no prior seed files, each one must be created:

      - [Create `application_node_config.yaml`](create_application_node_config_yaml.md)
      - [Create `cabinets.yaml`](create_cabinets_yaml.md)
      - [Create `hmn_connections.json`](create_hmn_connections_json.md)
      - [Create `ncn_metadata.csv`](create_ncn_metadata_csv.md)
      - [Create `switch_metadata.csv`](create_switch_metadata_csv.md)

   - For re-installations of CSM 1.3, the previous seed files may be used and this step can be skipped.
   - For new installations of CSM 1.3 that have prior seed files from CSM 1.2 or older, the previous seed files
     may be used **except that the following files must be recreated** because of content or formatting changes:

      - [Create `cabinets.yaml`](create_cabinets_yaml.md)
      - [Create `hmn_connections.json`](create_hmn_connections_json.md)

1. (`pit#`) Confirm that the topology files exist.

   ```bash
   ls -l "${PITDATA}"/prep/{application_node_config.yaml,cabinets.yaml,hmn_connections.json,ncn_metadata.csv,switch_metadata.csv}
   ```

   Expected output may look like:

   ```text
   -rw-r--r-- 1 root root  146 Jun  6 00:12 /var/www/ephemeral/prep/application_node_config.yaml
   -rw-r--r-- 1 root root  392 Jun  6 00:12 /var/www/ephemeral/prep/cabinets.yaml
   -rwxr-xr-x 1 root root 3768 Jun  6 00:12 /var/www/ephemeral/prep/hmn_connections.json
   -rw-r--r-- 1 root root 1216 Jun  6 00:12 /var/www/ephemeral/prep/ncn_metadata.csv
   -rw-r--r-- 1 root root  150 Jun  6 00:12 /var/www/ephemeral/prep/switch_metadata.csv
   ```

### 3. Customize `system_config.yaml`

1. (`pit#`) Create or copy `system_config.yaml`.

   - If one does not exist from a prior installation, then create an empty one:

      ```bash
      csi config init empty
      ```

   - Otherwise, copy the existing `system_config.yaml` file into the working directory and proceed to the [Run CSI](#4-run-csi) step.

1. (`pit#`) Edit the `system_config.yaml` file with the appropriate values.

   > ***NOTES***
   >
   > - For a short description of each key in the file, run `csi config init --help`.
   >   ***IMPORTANT*** `install-ncn-bond-members` have many possibilities, but are typically:
   >      - `p1p1,p10p1` for HPE nodes
   >      - `p1p1,p1p2` for Gigabyte nodes
   >      - `p801p1,p801p2` for Intel nodes
   > - For more description of these settings and the default values, see
   >   [Default IP Address Ranges](../introduction/csm_overview.md#2-default-ip-address-ranges) and the other topics in
   >   [CSM Overview](../introduction/csm_overview.md).
   > - To enable or disable audit logging, refer to [Audit Logs](../operations/security_and_authentication/Audit_Logs.md)
   >   for more information.
   > - If the system is using a `cabinets.yaml` file, be sure to update the `cabinets-yaml` field with `'cabinets.yaml'` as its value.

   ```bash
   vim system_config.yaml
   ```

### 4. Run CSI

(`pit#`) Generate the initial configuration for CSI.

This will validate whether the inputs for CSI are correct.

```bash
csi config init
```

### 5. Prepare Site Init

Follow the [Prepare Site Init](prepare_site_init.md) procedure.

### 6. Initialize the LiveCD

> **NOTE:** If starting an installation at this point, then be sure to copy the previous `prep` directory back onto the system.

1. (`pit#`) Initialize the PIT.

   The `pit-init.sh` script will prepare the PIT server for deploying NCNs.

   ```bash
   /root/bin/pit-init.sh
   ```

1. (`pit#`) Set the `IPMI_PASSWORD` variable.

   ```bash
   read -r -s -p "NCN BMC root password: " IPMI_PASSWORD
   ```

1. (`pit#`) Export the `IPMI_PASSWORD` variable.

   ```bash
   export IPMI_PASSWORD
   ```

1. (`pit#`) Setup links to the boot artifacts extracted from the CSM tarball.

   > **NOTE**
   >
   > - This will also set all the BMCs to DHCP.
   > - Changing into the `$HOME` directory ensures the proper operation of the script.

   ```bash
   cd $HOME && /root/bin/set-sqfs-links.sh
   ```

## Next topic

After completing this procedure, proceed to import the CSM tarball.

See [Import the CSM Tarball](pre-installation.md#4-import-the-csm-tarball).
