# Create HMN Connections JSON File

Use this procedure to generate the `hmn_connections.json` from the system's SHCD Excel document.
This process is typically needed when generating the `hmn_connections.json` file for a new system,
or regenerating it when a system's SHCD file is changed (specifically the `HMN` tab).
The `hms-shcd-parser` tool can be used to generate the `hmn_connections.json` file.

The [SHCD/HMN Connections Rules](shcd_hmn_connections_rules.md) document explains the expected
naming conventions and rules for the `HMN` tab of the SHCD file, and for
the `hmn_connections.json` file.

## Prerequisites

- SHCD Excel file for the system
- Podman is available

> **`NOTE`** Podman is available on the CSM LiveCD and NCN images.

## Procedure

> **`NOTE`** Ensure that the environment variables have been properly set by following
> [Set reusable environment variables](pre-installation.md#15-set-reusable-environment-variables) and then coming back
> to this page.

1. Inspect the `HMN` tab of the SHCD file.

    Verify that it does not have unexpected data in columns `J` through `U` in rows 20 or below. If any unexpected data is present in this region of the `HMN` tab, then it will end up in the generated `hmn_connections.json`. Therefore, it must be
    removed before generating the `hmn_connections.json` file. Unexpected data is anything other than HMN cabling information, such as another table placed below the HMN cabling information. Any data above row 20 will not interfere when generating `hmn_connections.json`.

    For example, the following image shows an unexpected table present underneath HMN cabling information in rows 26 to 29. The HMN cabling information in this example is truncated for brevity.

    ![Screen Shot of unexpected data in the `HMN` tab of an SHCD file](../img/install/shcd-hmn-tab-unexpected-data.png)

1. (`pit#`) Load the `hms-shcd-parser` container image from the CSM release distribution into Podman.

    - Determine the version of the `hms-shcd-parser` container image:

        ```bash
        SHCD_PARSER_VERSION=$(realpath ${CSM_PATH}/docker/artifactory.algol60.net/csm-docker/stable/hms-shcd-parser* | egrep  -o '[0-9]+\.[0-9]+\.[0-9]+$')
        echo $SHCD_PARSER_VERSION
        ```

    - Load the `hms-shcd-parser` container image into Podman:

        ```bash
        ${CSM_PATH}/hack/load-container-image.sh artifactory.algol60.net/csm-docker/stable/hms-shcd-parser:$SHCD_PARSER_VERSION
        ```

1. (`pit#`) Copy the system's SHCD file to the machine being used to prepare the `hmn_connections.json` file.

1. (`pit#`) Set a variable to point to the system's SHCD Excel file.

    > **`NOTE`** Make sure to quote the SHCD file path if there is whitespace in the document's path or filename.

    ```bash
    SHCD_FILE="/path/to/systems/SHCD.xlsx"
    ```

1. (`pit#`) Generate the `hmn_connections.json` file from the SHCD file.

    > This will create the `hmn_connections.json` file in the current directory. If it already exists, it will be overwritten.

    ```bash
    podman run --rm -it --name hms-shcd-parser -v "$(realpath "$SHCD_FILE")":/input/shcd_file.xlsx -v "$(pwd)":/output artifactory.algol60.net/csm-docker/stable/hms-shcd-parser:$SHCD_PARSER_VERSION
    ```
