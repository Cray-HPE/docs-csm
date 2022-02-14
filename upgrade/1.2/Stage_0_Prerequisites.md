# Stage 0 - Prerequisites and Preflight Checks

> **NOTE:** CSM-1.1.0 is required in order to upgrade to CSM-1.2.0
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

    * Air Gapped (replace the PATH_TO below with the location of the rpm)

        ```bash
        ncn-m001# cp [PATH_TO_docs-csm-*.noarch.rpm] /root
        ncn-m001# rpm -Uvh [PATH_TO_docs-csm-*.noarch.rpm]
        ```

## Stage 0.2 - Update `customizations.yaml`

Perform these steps to update `customizations.yaml`:

 1. Prepare work area

     If you manage customizations.yaml in an external Git repository (as recommended), then clone a local working tree.

    ```
    ncn-m001# git clone <URL> /root/site-init
    ncn-m001# cd /root/site-init
    ```

    If you do not have a backup of site-init then perform the following steps to create a new one using the values stored in the Kubernetes cluster.

    * Create a new site-init directory using from the CSM tarball

      ```
      ncn-m001# cp -r ${CSM_DISTDIR}/shasta-cfg /root/site-init
      ncn-m001# cd /root/site-init
      ```

    * Extract customizations.yaml from the site-init secret

      ```
      ncn-m001# kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
      ```

    * Extract the certificate and key used to create the sealed secrets

      ```
      ncn-m001# mkdir certs
      ncn-m001# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.crt}' | base64 -d - > certs/sealed_secrets.crt
      ncn-m001# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.key}' | base64 -d - > certs/sealed_secrets.key
      ```

  > **Note**: All subsequent steps of this procedure should be performed within the `/root/site-init` directory created in this step.

1. Update customizations.yaml

   Apply new values required for PowerDNS

   ```
   ncn-m001# ${CSM_SCRIPTDIR}/upgrade/update-customizations.sh -i customizations.yaml
   ```

1. Configure DNS zone transfer and DNSSEC (optional)

   If the DNS zone transfer and DNSSEC features are required please review the [PowerDNS configuration guide](../../operations/network/dns/PowerDNS_Configuration.md) and update `customizations.yaml` with the appropriate values.

1. Generate the new PowerDNS API key secret

   > **Note**: This step will also generate the SealedSecrets for the DNSSEC keys if configured in the previous step.  

   ```
   ncn-m001# ./utils/secrets-seed-customizations.sh customizations.yaml
   ```

1. Update the `site-init` secret

   ```
   ncn-m001# kubectl delete secret -n loftsman site-init
   ncn-m001# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
   ```

1. Commit changes to customizations.yaml if using an external Git repository.

   ```
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m 'Add required PowerDNS configuration'
   ncn-m001# git push
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

## Stage 0.5 - Update the Storage Node runcmds for reboots

To prevent accidental storage cloud-init runs and also to ensure the Ceph services are set to auto-start on boot, please run the below script.

On ncn-m001:

```bash
python3 /usr/share/doc/csm/scripts/patch-ceph-runcmd.py
```

## Stage 0.6 - Backup BSS Data

In the event of a problem during the upgrade which may cause the loss of BSS data, perform the following to preserve this data, and back it up to the config-data bucket in your Ceph cluster.

   ```bash
   ncn-m001# cray bss bootparameters list --format=json > bss-backup-$(date +%Y-%m-%d).json
   ncn-m001# cray artifacts create config-data bss-backup-$(date +%Y-%m-%d).json bss-backup-$(date +%Y-%m-%d).json
   ```

The resulting file needs to be saved in the event that BSS data needs to be restored in the future.

Once the above steps have been completed, proceed to [Stage 1](Stage_1.md).
