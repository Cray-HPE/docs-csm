# Stage 0 - Prerequisites and Preflight Checks

> **NOTE:** CSM-0.9.4 or later CSM 0.9.x is required in order to upgrade to CSM-1.0.0 (available with Shasta v1.5).
>
> **NOTE:** Installed CSM versions may be listed from the product catalog using the following command. This will sort a semantic version without a hyphenated suffix after the same semantic version with a hyphenated suffix, e.g. 1.0.0 > 1.0.0-beta.19.
>

Use the following command can be used to check the CSM version on the system:

```bash
ncn# kubectl get cm -n services cray-product-catalog -o json | jq -r '.data.csm'
```

This check will also be conducted in the 'prerequisites.sh' script listed below and will fail if the system is not running CSM-0.9.4 or CSM-0.9.5.

## Stage 0.1 - Install latest docs RPM

1. Install latest document RPM package:

    * Internet Connected

        ```bash
        ncn-m001# cd /root/
        ncn-m001# wget https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm/docs-csm-latest.noarch.rpm
        ncn-m001# rpm -Uvh docs-csm-latest.noarch.rpm
        ```

    * Air Gapped

        ```bash
        ncn-m001# cd /root/
        ncn-m001# rpm -Uvh [PATH_TO_docs-csm-*.noarch.rpm]
        ```

## Stage 0.2 - Update `customizations.yaml`

Perform these steps to update `customizations.yaml`:

1. Extract `customizations.yaml` from the `site-init` secret:

   ```bash
   ncn-m001# cd /tmp
   ncn-m001# kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
   ```

2. Update `customizations.yaml`:

   ```bash
   ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/update-customizations.sh -i customizations.yaml
   ```

3. Update the `site-init` secret:

   ```bash
   ncn-m001# kubectl delete secret -n loftsman site-init
   ncn-m001# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

4. If using an external Git repository for managing customizations ([as recommended](../../install/prepare_site_init.md#version-control-site-init-files)),
   clone a local working tree and commit appropriate changes to `customizations.yaml`.
   
   For Example:

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
> Run below command to make sure cray cli output format is reset to default
> 
>```
> ncn-m# unset CRAY_FORMAT
>```

Run check script:

* Internet Connected

    ```bash
    ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --endpoint [ENDPOINT]
    ```

    **NOTE** ENDPOINT is optional for internal use. It is pointing to internal arti by default.

* Air Gapped

    ```bash
    ncn-m001# /usr/share/doc/csm/upgrade/1.0/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --tarball-file [PATH_TO_CSM_TARBALL_FILE]
    ```

**`IMPORTANT:`** If any errors are encountered, then potential fixes should be displayed where the error occurred. **IF** the upgrade `prerequisites.sh` script fails and does not provide guidance, then try rerunning it. If the failure persists, then open a support ticket for guidance before proceeding.

## Stage 0.4 - Backup VCS Data

To prevent any possibility of losing configuration data, backup the VCS data and store it in a safe location. See [Version_Control_Service_VCS.md](../../operations/configuration_management/Version_Control_Service_VCS.md#backup-and-restore-data) for these procedures.

**`IMPORTANT:`** As part of this stage, **only perform the backup, not the restore**. The backup procedure is being done here as a precautionary step.

## Stage 0.5 - Backup Workload Manager Data

To prevent any possibility of losing Workload Manager configuration data or files, a back-up is required. Please execute all Backup procedures (for the Workload Manager in use) located in the `Troubleshooting and Administrative Tasks` sub-section of the `Install a Workload Manager` section of the `HPE Cray Programming Environment Installation Guide: CSM on HPE Cray EX`.  The resulting back-up data should be stored in a safe location off of the system.

Once the above steps have been completed, proceed to [Stage 1](Stage_1.md).
