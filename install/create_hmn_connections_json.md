# Create HMN Connections JSON
### About this task

The following procedure shows the process for generating the `hmn_connections.json` from the system's SHCD Excel document. This process is typically needed when generating the `hmn_connections.json` file for a new system, or regenerating it when system's SHCD is changed (specifically the HMN tab). The hms-shcd-parser tool can be used to generate the `hmn_connections.json` file.

The [SHCD/HMN Connections Rules document](shcd_hmn_connections_rules.md) explains the expected naming conventions and rules for the HMN tab of the SHCD, and the `hmn_connections.json` file.

### Prerequisites
* SHCD Excel file for your system
* Podman or Docker running

> Note: Docker can be used instead of Podman if the system being used to prepare this file does not have Podman available. 
> Podman is available on the CSM LiveCD, and is installed onto a NCN when being used as an environment to create the CSM PIT in the [Bootstrap PIT Node from LiveCD USB](bootstrap_livecd_usb.md) procedure.

### Procedure
1. Inspect the HMN tab of the SHCD to verify that it does not have unexpected data in columns J through U in row 20 or below. If any unexpected data is present in this region of the HMN tab it will end up in the generated `hmn_connections.json`, and needs to be removed before generating the `hmn_connections.json` file. Unexpected data is anything other than HMN cabling information, such as another table placed below the HMN cabling information. Any data above row 20 will not interfere when generating `hmn_connections.json`.

    For example, below is an example a unexpected table present underneath HMN cabling information in rows 26 to 29. Note the HMN cabling information was truncated for brevity. 
    ![Screen Shot of unexpected data in the HMN tab of a SHCD](../img/install/shcd-hmn-tab-unexpected-data.png)

2. __If using Docker__: Make sure that the docker service is running:
    ```
    linux# systemctl status docker
    ● docker.service - Docker Application Container Engine
    Loaded: loaded (/usr/lib/systemd/system/docker.service; disabled; vendor preset: disabled)
    Active: inactive (dead)
        Docs: http://docs.docker.com
    ``` 

    If the service is not running start it:
    ```
    linux# systemctl start docker
    ```

3. Load the hms-shcd-parser container image from the CSM release distribution. Only required if the CSM release distribution includes container images, otherwise this step can be skipped.

    > Note: The load-container-image.sh script works with both Podman and Docker

    Load the hms-shcd-parser docker image. This script will load the image into either Podman or Docker.
    ```
    linux# ${CSM_RELEASE}/hack/load-container-image.sh dtr.dev.cray.com/cray/hms-shcd-parser:1.4.3
    ```
4. Set environment to point to the system's SHCD Excel file:
    > Note: Make sure to quote the SHCD file path if there are spaces in the document's filename.

    ```
    linux# export SHCD_FILE="/path/to/systems/SHCD.xlsx"
    ```

5. Generate the hmn_connections.json file from the SHCD. This will either create or overwrite the `hmn_connections.json` file in the current directory:

    __If using Podman__:
    ```
    linux# podman run --rm -it --name hms-shcd-parser -v "$(realpath "$SHCD_FILE")":/input/shcd_file.xlsx -v "$(pwd)":/output dtr.dev.cray.com/cray/hms-shcd-parser:1.4.3
    ```

    __If using Docker__:
    ```
    linux# docker run --rm -it --name hms-shcd-parser -v "$(realpath "$SHCD_FILE")":/input/shcd_file.xlsx -v "$(pwd)":/output dtr.dev.cray.com/cray/hms-shcd-parser:1.4.3
    ```
