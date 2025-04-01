# Create System Configuration Using SHCD

This stage walks the user through creating the configuration payload for the system.

## Topics

1. [Validate SHCD](#1-validate-shcd)
1. [Generate topology files](#2-generate-topology-files)
1. [Next topic](#next-topic)

### 1. Validate SHCD

1. (`pit#`) Make the `prep` directory.

   ```bash
   mkdir -pv "${PITDATA}/prep"
   ```

1. (`pit#`) Change into the `prep` directory.

   ```bash
   cd "${PITDATA}/prep"
   ```

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

## Next topic

After completing this procedure, return to the pre-installation document to [generate system configuration](pre-installation.md#33-generate-system-configuration).
