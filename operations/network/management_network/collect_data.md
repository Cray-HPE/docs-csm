# Collect Data 

Collect the input data needed to generate switch configs.

## Prerequisites 

- SSH access to the switches
- System Layout Service (SLS) API access

## Procedure

1. Retrieve the most up-to-date SHCD spreadsheet. Accuracy in this spreadsheet is critical.

    For example:
    - Internal repository
    - Customer repository

1. Get an SLS file from a Shasta system.

    Log into any NCN where the Cray CLI is configured. Then run this command to create an SLS file named `sls_file.json` in the current directory.

    **IMPORTANT:** If this is an upgrade SLS needs to be updated to the correct CSM version first.

    ```bash
    ncn# cray sls dumpstate list  --format json >> sls_file.json   
    ```

1. Retrieve switch running configurations.

    CANU can backup all the management network switches using either the SLS input file or the SLS API.
    This can also be done from outside the cluster using the CMN switch IP addresses.

    ```bash
    ncn# canu backup network --folder switch_backups/ --sls-file ./sls_input_file_1_2.json
    ```

    Example output:

    ```
    Enter the switch password:
    -
    Running Configs Saved
    ---------------------
    sw-spine-001.cfg
    sw-spine-002.cfg
    sw-leaf-001.cfg
    sw-leaf-002.cfg
    sw-leaf-003.cfg
    sw-leaf-004.cfg
    sw-leaf-bmc-001.cfg
    sw-leaf-bmc-002.cfg
    sw-cdu-001.cfg
    sw-cdu-002.cfg
    ```

    If the SLS API is up, an SLS file does not need to be provided.

3. Retrieve the customizations file.

    Log in from `ncn-m001` and run the following command:  

    ```bash
    ncn# kubectl -n loftsman get secret site-init -o json | jq -r '.data."customizations.yaml"' | base64 -d > customizations.yaml 
    ```

    This will output the customizations file to a file called `customizations.yaml` in the current working directory.
