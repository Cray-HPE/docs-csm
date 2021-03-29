# HMN Connections File
### About this task
This guide shows the process for generating the `hmn_connections.json` from the system's SHCD Excel document. This process is typically needed when generating the `hmn_connections.json` file for a new system, or regenerating it when system's SHCD is changed (specifically the HMN tab). The hms-shcd-parser tool can be used to generate the `hmn_connections.json` file.

> **`INTERNAL USE`** This file should come from the [shasta_system_configs](https://stash.us.cray.com/projects/DST/repos/shasta_system_configs/browse) repository.
> Each system has its own directory in the repository. If this is a new system that doesn't yet have the `hmn_connections.json` file (or needs to be regenerated), then one will need to be generated from the SHCD (Cabling Diagram) for the system. 
>
> If you need to fetch the system's SHCD, you can use your HPE login to fetch it from [SharePoint](https://hpe.sharepoint.com/sites/HPC-AI-Install/CID/Install%20Documents/Forms/AllItems.aspx?FolderCTID=0x0120009859972694683B4C93C09EA98DDBB640&viewid=d6b54e31%2D74ce%2D44a9%2D924a%2Df5c0627cd172&id=%2Fsites%2FHPC%2DAI%2DInstall%2FCID%2FInstall%20Documents%2FCray%2FShasta%20River). May need to request permission to access this SharePoint folder.

### Prerequisites
* SHCD Excel file for your system
* Podman or Docker running

> Note: Docker can be used instead of Podman if the system being used to prepare this file does not have Podman available. 
> Podman is available on the CSM LiveCD, and is installed onto a NCN running Shasta v1.3 during the procedure to create the [CSM USB LiveCD](003-CSM-USB-LIVECD.md).

### Procedure
1. __If using Docker__: Make sure that the docker service is running:
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

2. Load the hms-shcd-parser docker image from the CSM release distribution. Only required if the CSM release distribution includes container images, otherwise this step can be skipped.
    > **`INTERNAL USE`** When the version of the hms-shcd-parser image changes in the CSM release distribution the following section will need to be updated with the corrected tag

    > Note: The load-container-image.sh script works with both Podman and Docker

    Load the hms-shcd-parser docker image. This script will load the image into either Podman or Docker.
    ```
    linux# ${CSM_RELEASE}/hack/load-container-image.sh dtr.dev.cray.com/cray/hms-shcd-parser:1.1.1
    ```
3. Set environment to point to the system's SHCD Excel file:
    > Note: Make sure to quote the SHCD file path if there are spaces in the document's filename.

    ```
    linux# export SHCD_FILE="/path/to/systems/SHCD.xsls"
    ```

4. Generate the hmn_connections.json file from the SHCD. This will either create or overwrite the `hmn_connections.json` file in the current directory:
    > **`INTERNAL USE`** When the version of the hms-shcd-parser image changes in the CSM release distribution the following section will need to be updated with the corrected tag

    __If using Podman__:
    ```
    linux# podman run --rm -it --name hms-shcd-parser -v "$(realpath "$SHCD_FILE")":/input/shcd_file.xlsx -v "$(pwd)":/output dtr.dev.cray.com/cray/hms-shcd-parser:1.1.1
    ```

    __If using Docker__:
    ```
    linux# docker run --rm -it --name hms-shcd-parser -v "$(realpath "$SHCD_FILE")":/input/shcd_file.xlsx -v "$(pwd)":/output dtr.dev.cray.com/cray/hms-shcd-parser:1.1.1
    ```
