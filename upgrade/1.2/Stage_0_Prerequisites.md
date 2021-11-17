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

Once the above steps have been completed, proceed to [Stage 1](Stage_1.md).
