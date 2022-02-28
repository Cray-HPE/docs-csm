# Stage 0 - Prerequisites and Preflight Checks

> **NOTE:** CSM-0.9.4 or later CSM 0.9.x is required in order to upgrade to CSM-1.0.1 (available with Shasta v1.5).
>
> **NOTE:** Installed CSM versions may be listed from the product catalog using the following command. This will sort a semantic version without a hyphenated suffix after the same semantic version with a hyphenated suffix, e.g. `1.0.0` > `1.0.0-beta.19`.
>

Use the following command can be used to check the CSM version on the system:

```bash
ncn# kubectl get cm -n services cray-product-catalog -o json | jq -r '.data.csm' | tee csm-version.txt
```

This check will also be conducted in the `prerequisites.sh` script listed below and will fail if the system is not running CSM-0.9.4, CSM-0.9.5, or CSM-1.0.0.

>**`IMPORTANT:`**
> 
> Before running any upgrade scripts, be sure the Cray CLI output format is reset to default by running the following command:
>
>```bash
> ncn# unset CRAY_FORMAT
>```

## Stage 0.1 - Install latest docs RPM

1. Copy the latest document RPM package to `/root` and install it.

    The install scripts will look for this RPM in `/root`, so it is important that you copy it there.

    * Internet Connected

        ```bash
        ncn-m001# wget https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm/docs-csm-latest.noarch.rpm -P /root
        ncn-m001# rpm -Uvh --force /root/docs-csm-latest.noarch.rpm
        ```

    * Air Gapped (replace the PATH_TO below with the location of the rpm)

        ```bash
        ncn-m001# cp [PATH_TO_docs-csm-*.noarch.rpm] /root
        ncn-m001# rpm -Uvh --force /root/docs-csm-*.noarch.rpm
        ```

## Stage 0.2 - Update `customizations.yaml`

Perform these steps to update `customizations.yaml`:

1. Extract `customizations.yaml` from the `site-init` secret:

    ```bash
    ncn-m001# cd /tmp
    ncn-m001# kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
    ```

1. Update `customizations.yaml`:

    ```bash
    ncn-m001# /usr/share/doc/csm/upgrade/1.0.1/scripts/upgrade/update-customizations.sh -i customizations.yaml
    ```

1. Update the `site-init` secret:

    ```bash
    ncn-m001# kubectl delete secret -n loftsman site-init
    ncn-m001# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
    ```

1. If [using an external Git repository for managing customizations](../../install/prepare_site_init.md#version-control-site-init-files) as recommended,
   clone a local working tree and commit appropriate changes to `customizations.yaml`.
   
    For example:

    ```bash
    ncn-m001# git clone <URL> site-init
    ncn-m001# cp /tmp/customizations.yaml site-init
    ncn-m001# cd site-init
    ncn-m001# git add customizations.yaml
    ncn-m001# git commit -m 'Remove Gitea PVC configuration from customizations.yaml'
    ncn-m001# git push
    ```

5. Return to original working directory:

    ```bash
    ncn-m001# cd -
    ```

## Stage 0.3 - Execute Prerequisites Check

>**`IMPORTANT:`**
> 
> Reminder: Before running any upgrade scripts, be sure the Cray CLI output format is reset to default by running the following command:
>
>```bash
> ncn# unset CRAY_FORMAT
>```

1. Authenticate with the Cray CLI on `ncn-m001`.

    See [Configure the Cray Command Line Interface](../../operations/configure_cray_cli.md) for details on how to do this.

1. Set the `CSM_RELEASE` variable to the correct value for the CSM release upgrade being applied.

    ```bash
    ncn-m001# CSM_RELEASE=csm-1.0.1
    ```

1. Run check script:

    **NOTE** The `prerequisites.sh` script will warn that it will unmount `/mnt/pitdata`, but this is not accurate. The script will only unmount it if the script itself mounts it. That is, if it is mounted when the script begins, the script will not unmount it.

    * Option 1 - Internet Connected Environment

        1. Set the `ENDPOINT` variable to the URL of the directory containing the CSM release tarball.
        
            In other words, the full URL to the CSM release tarball will be `${ENDPOINT}${CSM_RELEASE}.tar.gz`
        
            **NOTE** This step is optional for Cray/HPE internal installs.
        
            ```bash
            ncn-m001# ENDPOINT=https://put.the/url/here/
            ```

        1. Run the script
        
            **NOTE** The `--endpoint` argument is optional for Cray/HPE internal use.

            ```bash
            ncn-m001# /usr/share/doc/csm/upgrade/1.0.1/scripts/upgrade/prerequisites.sh --csm-version $CSM_RELEASE --endpoint $ENDPOINT
            ```

    * Option 2 - Air Gapped Environment

        1. Set the `TAR_DIR` variable to the directory on `ncn-m001` containing the CSM release tarball.
        
            In other words, the full path to the CSM release tarball will be `${TAR_DIR}/${CSM_RELEASE}.tar.gz`

            ```bash
            ncn-m001# TAR_DIR=/path/to/tarball/dir
            ```

        1. Run the script

            ```bash
            ncn-m001# /usr/share/doc/csm/upgrade/1.0.1/scripts/upgrade/prerequisites.sh --csm-version $CSM_RELEASE --tarball-file ${TAR_DIR}/${CSM_RELEASE}.tar.gz
            ```

**`IMPORTANT:`** If any errors are encountered, then potential fixes should be displayed where the error occurred. 

**IF** the `prerequisites.sh` script fails and does not provide guidance, then try rerunning it. If the failure persists, then open a support ticket for guidance before proceeding.

## Stage 0.4 - Backup VCS Data

To prevent any possibility of losing configuration data, backup the VCS data and store it in a safe location. See [Version_Control_Service_VCS.md](../../operations/configuration_management/Version_Control_Service_VCS.md#backup-and-restore-data) for these procedures.

**`IMPORTANT:`** As part of this stage, **only perform the backup, not the restore**. The backup procedure is being done here as a precautionary step.

## Stage 0.5 - Backup Workload Manager Data

To prevent any possibility of losing Workload Manager configuration data or files, a back-up is required. Please execute all Backup procedures (for the Workload Manager in use) located in the `Troubleshooting and Administrative Tasks` sub-section of the `Install a Workload Manager` section of the `HPE Cray Programming Environment Installation Guide: CSM on HPE Cray EX`. The resulting back-up data should be stored in a safe location off of the system.

## Stage 0.6 - Update the Storage Node runcmds for reboots

To prevent accidental storage cloud-init runs and also to ensure the Ceph services are set to auto-start on boot, please run the below script on `ncn-m001`:

```bash
ncn-m001# python3 /usr/share/doc/csm/scripts/patch-ceph-runcmd.py
```

## Stage 0.6 - Backup BSS Data

In the event of a problem during the upgrade which may cause the loss of BSS data, perform the following to preserve this data.

   ```bash
   ncn-m001# cray bss bootparameters list --format=json >bss-backup-$(date +%Y-%m-%d).json
   ```

The resulting file needs to be saved in the event that BSS data needs to be restored in the future.

Once the above steps have been completed, proceed to [Stage 1](Stage_1.md).
