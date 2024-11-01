# SAT and IUF

The Install and Upgrade Framework (IUF) provides commands which install, upgrade, and deploy
products on systems managed by CSM with the help of `sat bootprep`. Outside of IUF, it is uncommon
to use `sat bootprep`.

For more information on IUF, see [Install and Upgrade Framework](../../iuf/IUF.md). For more
information on `sat bootprep`, see [SAT Bootprep](SAT_Bootprep.md).

## IUF variable substitutions

As described in [Variable substitutions](SAT_Bootprep.md#variable-substitutions),
the `sat bootprep` command supports variable substitutions in the `bootprep`
input files. IUF merges variables from multiple sources and then passes the
resulting merged variables to `sat bootprep` using the `--vars-file` option. The
sources used by IUF, in order of highest to lowest precedence are as follows:

1. The versions of products found in the media directory for the IUF activity.
1. The site variables (`site_vars.yaml`) passed to IUF with the `--site-vars`
   option.
1. The variables in the HPC CSM Software Recipe `product_vars.yaml` file passed
   to IUF.
1. The most recent versions of products from the product catalog.

See [Customer branch name](../../iuf/stages/update_vcs_config.md#customer-branch-name)
in the IUF documentation for further details on how these variables are
constructed.

When IUF merges these variable sources, it performs an additional rendering pass
that allows the expansion of variables in other variables defined in the
`product_vars.yaml` file. For example, the `product_vars.yaml` may contain the
following:

```yaml
default:
  working_branch: "integration-{{version_x_y_z}}"

uss:
  version: 1.2.0-95-csm
  working_branch: "{{working_branch}}"
```

IUF first determines the appropriate value of `uss.version` using the previously
described precedence rules. Then it substitutes `{{working_branch}}` in the
value of `uss.working_branch` with the value `"integration-{{version_x_y_z}}"`.
Finally, it renders this string and replaces `{{version_x_y_z}}` using the value
of `uss.version`. Assuming IUF determines the value of `uss.version` to be
`1.2.0-95-csm`, the rendered variables for `uss` are as follows:

```yaml
uss:
  version: 1.2.0-95-csm
  working_branch: "integration-1.2.0"
```

Since this variable substitution requires multiple passes of rendering and
knowledge of the versions of products being installed by IUF, this rendering
cannot be performed by `sat bootprep` alone. If the `product_vars.yaml` file
shown above is passed to `sat bootprep` directly without being rendered by the
IUF, it will not use the intended value for `uss.working_branch`.

In order to use a `sat bootprep` file that depends on a complex variable as
described above, the merged and rendered `session_vars.yaml` file can be
obtained from an IUF activity, and that file can be provided to `sat bootprep`
with the `--vars-file` option.

### Obtaining IUF session variables and bootprep files

When IUF constructs the variables as described in [IUF Variable
Substitutions](#iuf-variable-substitutions), it saves these variables to a file
named `session_vars.yaml` in the directory for the IUF activity. The following
procedure describes how to obtain a copy of the `session_vars.yaml` and `sat
bootprep` input files used in an IUF activity. These files can then be used
directly with `sat bootprep` if desired. This can be useful for debugging
purposes.

In order to follow this procedure, you will need to know the name of the IUF
activity used to perform the initial installation of the HPE Cray EX software
products. See the [Activities](../../iuf/IUF.md#activities) section of the IUF
documentation for more information on IUF activities. See
[`list-activities`](../../iuf/IUF.md#list-activities) for information about
listing the IUF activities on the system. The first step provides an example
showing how to find the IUF activity.

1. (`ncn-m001#`) Find the IUF activity used for the most recent install of the system.

   ```bash
   iuf list-activities
   ```

   This will output a list of IUF activity names. For example, if only a single install has been
   performed on this system of the 24.01 recipe, the output may show a single line like this:

   ```text
   24.01-recipe-install
   ```

1. (`ncn-m001#`) Record the most recent IUF activity name and directory in environment variables.

   ```bash
   export ACTIVITY_NAME=
   ```

   ```bash
   export ACTIVITY_DIR="/etc/cray/upgrade/csm/iuf/${ACTIVITY_NAME}"
   ```

1. (`ncn-m001#`) Record the media directory used for this activity in an environment variable.

   ```bash
   export MEDIA_DIR="$(yq r "${ACTIVITY_DIR}/state/stage_hist.yaml" 'summary.media_dir')"
   echo "${MEDIA_DIR}"
   ```

   This should display a path to a media directory. For example:

   ```text
   /etc/cray/upgrade/csm/media/24.01-recipe-install
   ```

1. (`ncn-m001#`) Create a directory for the `sat bootprep` input files and the `session_vars.yaml`
   file.

   This example uses a directory under the RBD mount used by IUF:

   ```bash
   export BOOTPREP_DIR="/etc/cray/upgrade/csm/admin/bootprep-csm-${CSM_RELEASE}"
   mkdir -pv "${BOOTPREP_DIR}"
   ```

1. (`ncn-m001#`) Copy the desired `sat bootprep` input file(s) into the directory.

   The example below shows copying the two default bootprep files
   `management-bootprep.yaml` and `compute-and-uan-bootprep.yaml`.

   ```bash
   cp -pv "${MEDIA_DIR}/.bootprep-${ACTIVITY_NAME}/management-bootprep.yaml" "${BOOTPREP_DIR}"
   cp -pv "${MEDIA_DIR}/.bootprep-${ACTIVITY_NAME}/compute-and-uan-bootprep.yaml" "${BOOTPREP_DIR}"
   ```

1. (`ncn-m001#`) Copy the `session_vars.yaml` file into the directory.

   ```bash
   cp -pv "${ACTIVITY_DIR}/state/session_vars.yaml" "${BOOTPREP_DIR}"
   ```

1. (`ncn-m001#`) It is recommended to modify the `default.suffix` value in the
   copied `session_vars.yaml`.

   As long as the `sat bootprep` input file uses `{{default.suffix}}` in the
   names of the CFS configurations, IMS images, and BOS session templates, this
   will ensure new CFS configurations and IMS images are created with different
   names from the ones created in the IUF activity.

   The example below sets the suffix to "-debug":

   ```bash
   yq w -i -- "${BOOTPREP_DIR}/session_vars.yaml" 'default.suffix' "-debug"
   ```

In order use `sat bootprep` with the variables defined in this
`session_vars.yaml` file, pass `--vars-file session_vars.yaml` to `sat bootprep
run`.

## Manually building and applying management node images and configurations

**This section is purely for workaround purposes.**

This section is not expected to be used in a normal upgrade or install process.
These steps are automatically done through IUF. This section is here in case
`sat bootprep` needs to be run manually or in case CSM NCN images need to be
built manually. These steps are not needed during a normal upgrade or install.

The procedure below describes how to create CFS configurations and IMS images
for management nodes and assign them to the management nodes.

1. Follow the procedure in [Obtaining IUF session variables and bootprep files](#obtaining-iuf-session-variables-and-bootprep-files)
   to obtain the appropriate `session_vars.yaml` and `management-bootprep.yaml`
   files.

1. (`ncn-m001#`) Change directory to the `BOOTPREP_DIR` and run `sat bootprep`,
   passing the `session_vars.yaml` file as the value of the `--vars-file`
   option:

   ```bash
   cd "${BOOTPREP_DIR}"
   sat bootprep run --vars-file session_vars.yaml management-bootprep.yaml
   ```

1. (`ncn-m001#`) Gather the CFS configuration name, and the IMS image names from
   the output of `sat bootprep`.

   `sat bootprep` will print a report summarizing the CFS configuration and IMS
   images it created. For example:

   ```text
   ################################################################################
   CFS configurations
   ################################################################################
   +-----------------------------+
   | name                        |
   +-----------------------------+
   | management-22.4.0-csm-x.y.z |
   +-----------------------------+
   ################################################################################
   IMS images
   ################################################################################
   +-----------------------------+--------------------------------------+--------------------------------------+-----------------------------+----------------------------+
   | name                        | preconfigured_image_id               | final_image_id                       | configuration               | configuration_group_names  |
   +-----------------------------+--------------------------------------+--------------------------------------+-----------------------------+----------------------------+
   | master-secure-kubernetes    | c1bcaf00-109d-470f-b665-e7b37dedb62f | a22fb912-22be-449b-a51b-081af2d7aff6 | management-22.4.0-csm-x.y.z | Management_Master          |
   | worker-secure-kubernetes    | 8b1343c4-1c39-4389-96cb-ccb2b7fb4305 | 241822c3-c7dd-44f8-98ca-0e7c7c6426d5 | management-22.4.0-csm-x.y.z | Management_Worker          |
   | storage-secure-storage-ceph | f3dd7492-c4e5-4bb2-9f6f-8cfc9f60526c | 79ab3d85-274d-4d01-9e2b-7c25f7e108ca | storage-22.4.0-csm-x.y.z    | Management_Storage         |
   +-----------------------------+--------------------------------------+--------------------------------------+-----------------------------+----------------------------+
   ```

   1. Save the names of the CFS configurations from the `configuration` column:

      > Note that the storage node configuration might be titled `minimal-management-` or `storage-` depending on the value
      > set in the sat `bootprep` file.
      >
      > The following uses the values from the example output above. Be sure to modify them
      > to match the actual values.

      ```bash
      export KUBERNETES_CFS_CONFIG_NAME="management-22.4.0-csm-x.y.z"
      export STORAGE_CFS_CONFIG_NAME="storage-22.4.0-csm-x.y.z"
      ```

   1. Save the name of the IMS images from the `final_image_id` column:

      > The following uses the values from the example output above. Be sure to modify them
      > to match the actual values.

      ```bash
      export MASTER_IMAGE_ID="a22fb912-22be-449b-a51b-081af2d7aff6"
      export WORKER_IMAGE_ID="241822c3-c7dd-44f8-98ca-0e7c7c6426d5"
      export STORAGE_IMAGE_ID="79ab3d85-274d-4d01-9e2b-7c25f7e108ca"
      ```

1. (`ncn-m001#`) Assign the images to the management nodes in BSS.

   - Master management nodes:

      ```bash
      /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh -m -p "$MASTER_IMAGE_ID"
      ```

   - Storage management nodes:

      ```bash
      /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh -s -p "$STORAGE_IMAGE_ID"
      ```

   - Worker management nodes:

      ```bash
      /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh -w -p "$WORKER_IMAGE_ID"
      ```

1. (`ncn-m001#`) Assign the CFS configuration to the management nodes.

   This deliberately only sets the desired configuration of the components in
   CFS. It disables the components and does not clear their configuration states
   or error counts. When the nodes are rebooted to their new images, they will
   automatically be enabled in CFS, and node personalization will occur.
  
   1. Get the xnames of the master and worker management nodes.

      ```bash
      WORKER_XNAMES=$(cray hsm state components list --role Management --subrole Worker --type Node --format json |
          jq -r '.Components | map(.ID) | join(",")')
      MASTER_XNAMES=$(cray hsm state components list --role Management --subrole Master --type Node --format json |
          jq -r '.Components | map(.ID) | join(",")')
      echo "${MASTER_XNAMES},${WORKER_XNAMES}"
      ```

   1. Apply the CFS configuration to master nodes and worker nodes using the
      xnames and CFS configuration name found in the previous steps.

      ```bash
      /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
          --no-config-change --config-name "${KUBERNETES_CFS_CONFIG_NAME}" --no-enable --no-clear-err \
          --xnames ${MASTER_XNAMES},${WORKER_XNAMES}
      ```

      Successful output will end with the following:

      ```text
      All components updated successfully.
      ```

   1. Get the xnames of the storage management nodes.

      ```bash
      STORAGE_XNAMES=$(cray hsm state components list --role Management --subrole Storage --type Node --format json |
          jq -r '.Components | map(.ID) | join(",")')
      echo $STORAGE_XNAMES
      ```

   1. Apply the CFS configuration to storage nodes using the xnames and CFS
      configuration name found in the previous steps.

      ```bash
      /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
          --no-config-change --config-name "${STORAGE_CFS_CONFIG_NAME}" --no-enable --no-clear-err \
          --xnames ${STORAGE_XNAMES}
      ```

      Successful output will end with the following:

      ```text
      All components updated successfully.
      ```
