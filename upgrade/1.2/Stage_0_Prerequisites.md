# Stage 0 - Prerequisites and Preflight Checks

> **NOTE:** CSM-1.0.1 is required in order to upgrade to CSM-1.2.0


## Stage 0.1 - Install latest docs RPM

1. Install latest document RPM package:

    * Internet Connected

        ```bash
        ncn-m001# cd /root/
        ncn-m001# wget https://storage.googleapis.com/csm-release-public/csm-1.2/docs-csm/docs-csm-latest.noarch.rpm
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

1. Update `customizations.yaml`:

    > **`IMPORTANT:`** If the password for the local Nexus `admin` account has
    > been changed from the default `admin123` (not typical), then set the
    > `NEXUS_PASSWORD` environment variable to the correct `admin` password
    > before running update-customizations.sh! For example:
    >
    > ```bash
    > ncn-m001# export NEXUS_PASSWORD=cu$t0m@DM1Np4s5w0rd
    > ```
    >
    > Otherwise, a random 32-character base64-encoded string will be generated
    > and updated as the default `admin` password when Nexus is upgraded.

    ```bash
    ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/update-customizations.sh -i customizations.yaml
    ```

    > **`IMPORTANT:`** If the `NEXUS_PASSWORD` environment variable was set as
    > previously mentioned, then remove it before continuing:
    >
    > ```bash
    > ncn-m001# export -n NEXUS_PASSWORD
    > ncn-m001# unset NEXUS_PASSWORD
    > ```

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

Run check script:

* Internet Connected

    ```bash
    ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --endpoint [ENDPOINT]
    ```

    **NOTE** ENDPOINT is optional for internal use. It is pointing to internal arti by default.

* Air Gapped

    ```bash
    ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --tarball-file [PATH_TO_CSM_TARBALL_FILE]
    ```

**`IMPORTANT:`** If any errors are encountered, then potential fixes should be displayed where the error occurred. **IF** the upgrade `prerequisites.sh` script fails and does not provide guidance, then try rerunning it. If the failure persists, then open a support ticket for guidance before proceeding.

## Stage 0.4 - Backup VCS Data

To prevent any possibility of losing configuration data, backup the VCS data and store it in a safe location. See [Version_Control_Service_VCS.md](../../operations/configuration_management/Version_Control_Service_VCS.md#backup-and-restore-data) for these procedures.

**`IMPORTANT:`** As part of this stage, **only perform the backup, not the restore**. The backup procedure is being done here as a precautionary step.

Once the above steps have been completed, proceed to [Stage 1](Stage_1.md).
