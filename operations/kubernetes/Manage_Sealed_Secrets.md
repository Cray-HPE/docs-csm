

## Manage Sealed Secrets

Procedures for encrypting, decrypting, and modifying Kubernetes sealed secrets.


### Generate Sealed Secrets Post-Install

Sealed secrets are stored in customizations.yaml as `SealedSecret` resources 
(encrypted secrets), which are deployed by specific charts and decrypted by the
sealed secrets operator. First, those secrets must be seeded, generated, and
encrypted.

1. Prepare to customize the customizations.yaml file.

   If the customizations.yaml file is managed in an external Git repository (as recommended), then clone a local working tree. Replace the `<URL>` value in the following command before running it.

   ```bash
   ncn-m001# git clone <URL> /root/site-init
   ncn-m001# cd /root/site-init
   ```

   If there is not a backup of site-init, perform the following steps to create a new one using the values stored in the Kubernetes cluster.

   1. Create a new site-init directory using the CSM tarball.

      Determine the location of the initial unpacked install tarball and set ${CSM_DISTDIR} accordingly.

      > **NOTE:** If the unpacked set of CSM directories was copied, no untar action is required. If the tarball tgz file was copied, the command to unpack it is `tar -zxvf CSM_RELEASE.tar.gz`. Replace the *CSM_RELEASE* value before running the command to unpack the tarball.

      ```bash
      ncn-m001# cp -r ${CSM_DISTDIR}/shasta-cfg/* /root/site-init
      ncn-m001# cd /root/site-init
      ```
  
   1. Extract customizations.yaml from the site-init secret.

      ```bash
      ncn-m001# kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
      ```

   1. Extract the certificate and key used to create the sealed secrets.

      ```bash
      ncn-m001# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.crt}' | base64 -d - > certs/sealed_secrets.crt
      ncn-m001# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.key}' | base64 -d - > certs/sealed_secrets.key
      ```

1. (Optional) Prevent tracked sealed secrets from being regenerated.
    
    1. Remove the sealed secrets not being regenerated from the `spec.kubernetes.tracked_sealed_secrets` list in `/root/site-init/${CSM_DISTDIR}/shasta-cfg/customizations.yaml` prior to executing the remaining steps in this section.

    2. Retain the REDS/MEDS/RTS credentials.

       ```bash
       linux# yq delete -i ./${CSM_DISTDIR}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_reds_credentials
       linux# yq delete -i ./${CSM_DISTDIR}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_meds_credentials
       linux# yq delete -i ./${CSM_DISTDIR}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_hms_rts_credentials
       ```

2. Prepare to generate sealed secrets.
   
   ```bash
   ncn-m001# ./utils/secrets-reencrypt.sh customizations.yaml ./certs/sealed_secrets.key ./certs/sealed_secrets.crt
   ```
      
3. Encrypt the static values in the customizations.yaml file after making changes.

   The following command must be run within the site-init directory.

   ```bash
   ncn-m001# ./utils/secrets-seed-customizations.sh customizations.yaml
   ```

   Expected output looks similar to:

      ```bash
      Creating Sealed Secret keycloak-certs
      Generating type static_b64...
      Creating Sealed Secret keycloak-master-admin-auth
      Generating type static...
      Generating type static...
      Generating type randstr...
      Generating type static...
      Creating Sealed Secret cray_reds_credentials
      Generating type static...
      Generating type static...
      Creating Sealed Secret cray_meds_credentials
      Generating type static...
      Creating Sealed Secret cray_hms_rts_credentials
      Generating type static...
      Generating type static...
      Creating Sealed Secret vcs-user-credentials
      Generating type randstr...
      Generating type static...
      Creating Sealed Secret generated-platform-ca-1
      Generating type platform_ca...
      Creating Sealed Secret pals-config
      Generating type zmq_curve...
      Generating type zmq_curve...
      Creating Sealed Secret munge-secret
      Generating type randstr...
      Creating Sealed Secret slurmdb-secret
      Generating type static...
      Generating type static...
      Generating type randstr...
      Generating type randstr...
      Creating Sealed Secret keycloak-users-localize
      Generating type static...
      ```



### Prevent Regeneration of Tracked Sealed Secrets

In order to prevent tracked sealed secrets from being regenerated, they 
**MUST BE REMOVED** from the `spec.kubernetes.tracked_sealed_secrets` list in the `customizations.yaml` file prior to 
executing the "Generate Sealed Secrets" section of the [Prepare Site Init](../../install/prepare_site_init.md) procedure.

The `customizations.yaml` file will be located in one of the following locations depending
on the state of the system: 

* Fresh install location: `/mnt/pitdata/${CSM_DISTDIR}/shasta-cfg/customizations.yaml`
* Post-install location: `/root/site-init/${CSM_DISTDIR}/shasta-cfg/customizations.yaml`

To retain the REDS/MEDS/RTS credentials:

```bash
linux# yq delete -i /mnt/pitdata/${CSM_DISTDIR}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_reds_credentials
linux# yq delete -i /mnt/pitdata/${CSM_DISTDIR}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_meds_credentials
linux# yq delete -i /mnt/pitdata/${CSM_DISTDIR}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_hms_rts_credentials
```


### View Tracked Sealed Secrets

Tracked sealed secrets are regenerated every time secrets are seeded (see the
use of `utils/secrets-seed-customizations.sh` above).

To view currently tracked sealed secrets:

```bash
linux# yq read /mnt/pitdata/${CSM_RELEASE}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets
```

Expected output looks similar to the following:

```bash
- cray_reds_credentials
- cray_meds_credentials
- cray_hms_rts_credentials
```


### Decrypt Sealed Secrets for Review

Use the `secrets-decrypt.sh` utility in the SHASTA-CFG to decrypt and review previously encrypted
sealed secrets.

Syntax: `secret-decrypt.sh SEALED-SECRET-NAME SEALED-SECRET-PRIVATE-KEY CUSTOMIZATIONS-YAML`

For example:

```bash
linux:/mnt/pitdata/prep/site-init# ./utils/secrets-decrypt.sh cray_meds_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_redfish_defaults | sed -e 's/"//g' | base64 -d; echo
```

Expected output looks similar to the following:

```bash
{"Username": "root", "Password": "..."}
```

