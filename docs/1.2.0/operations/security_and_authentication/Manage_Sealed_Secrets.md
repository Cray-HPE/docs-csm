# Manage Sealed Secrets

Sealed secrets are essential for managing sensitive information on the system. The following procedures for
managing sealed secrets are included in this section:

* [Generate Sealed Secrets Post-Install](#generate-sealed-secrets-post-install)
* [Prevent Regeneration of Tracked Sealed Secrets](#prevent-regeneration-of-tracked-sealed-secrets)
* [View Tracked Sealed Secrets](#view-tracked-sealed-secrets)
* [Decrypt Sealed Secrets for Review](#decrypt-sealed-secrets-for-review)
* [Fix an Incorrect Value in a Sealed Secret](#fix-an-incorrect-value-in-a-sealed-secret)

In the following sections, the term "tracked sealed secrets" is used to describe
any existing secrets stored in `spec.kubernetes.tracked_sealed_secrets` that are available to be regenerated.

Many of the examples in this section assume that the system was installed using a USB PIT
node, and that the USB stick used to install the system is still available. If `site-init`
is no longer available on the USB stick and a backup has not been made, a new `site-init`
will need to be created following step 1 in the
[Generate Sealed Secrets Post-Install](#generate-sealed-secrets-post-install) section.

The `customizations.yaml` file used in this procedure will be in one of the following
locations depending on the state of the system:

* Fresh install location: `/mnt/pitdata/${CSM_DISTDIR}/shasta-cfg/customizations.yaml`
* Post-install location: `/root/site-init/${CSM_DISTDIR}/shasta-cfg/customizations.yaml`

## Generate Sealed Secrets Post-Install

Sealed secrets are stored in `customizations.yaml` as `SealedSecret` resources
(encrypted secrets), which are deployed by specific charts and decrypted by the
sealed secrets operator. First, those secrets must be seeded, generated, and
encrypted.

The steps in this section assume that the system was not installed using a USB PIT node,
or that the USB stick is no longer available.

If LDAP user federation is required, then refer to
[Add LDAP User Federation](../security_and_authentication/Add_LDAP_User_Federation.md).

1. Prepare to customize the `customizations.yaml` file.

   If the `customizations.yaml` file is managed in an external Git repository (as recommended), then
   clone a local working tree. Replace the `<URL>` value in the following command before running it.

   ```bash
   ncn# git clone <URL> /root/site-init
   ncn# cd /root/site-init
   ```

   If there is not a backup of `site-init`, perform the following steps to create a new one using the
   values stored in the Kubernetes cluster.

   1. Create a new `site-init` directory using the CSM tarball.

      Determine the location of the initial unpacked install tarball and set `${CSM_DISTDIR}` accordingly.

      > **NOTE:** If the unpacked set of CSM directories was copied, no action is required to expand the tarball.
      If the tarball tgz file was copied, the command to unpack it is `tar -zxvf CSM_RELEASE.tar.gz`.
      Replace the `CSM_RELEASE` value before running the command to unpack the tarball.

      ```bash
      ncn# cp -r ${CSM_DISTDIR}/shasta-cfg/* /root/site-init
      ncn# cd /root/site-init
      ```

   1. Extract `customizations.yaml` from the `site-init` secret.

      ```bash
      ncn# kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
      ```

   1. Extract the certificate and key used to create the sealed secrets.

      ```bash
      ncn# mkdir -p certs
      ncn# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.crt}' | base64 -d - > certs/sealed_secrets.crt
      ncn# kubectl -n kube-system get secret sealed-secrets-key -o jsonpath='{.data.tls\.key}' | base64 -d - > certs/sealed_secrets.key
      ```

1. (Optional) Prevent tracked sealed secrets from being regenerated.

   Remove the sealed secrets not being regenerated from the `spec.kubernetes.tracked_sealed_secrets` list in
   `/root/site-init/${CSM_DISTDIR}/shasta-cfg/customizations.yaml` prior to executing the remaining steps in this section.

   Retain the REDS/MEDS/RTS credentials.

   ```bash
   ncn# yq delete -i customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_reds_credentials
   ncn# yq delete -i customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_meds_credentials
   ncn# yq delete -i customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_hms_rts_credentials
   ```

1. Prepare to generate sealed secrets.

   ```bash
   ncn# ./utils/secrets-reencrypt.sh customizations.yaml ./certs/sealed_secrets.key ./certs/sealed_secrets.crt
   ```

1. Encrypt the static values in the `customizations.yaml` file after making changes.

   The following command must be run within the `site-init` directory.

   ```bash
   ncn# ./utils/secrets-seed-customizations.sh customizations.yaml
   ```

   Expected output looks similar to:

   ```text
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

## Prevent Regeneration of Tracked Sealed Secrets

Before performing the task to generate or regenerate sealed secrets,
administrators are able to prevent existing tracked sealed secrets from being regenerated.

To prevent regeneration, sealed secrets **MUST BE REMOVED** from the `spec.kubernetes.tracked_sealed_secrets`
list in the `customizations.yaml` file prior to executing the
"Generate Sealed Secrets" section of the [Prepare Site Init](../../install/prepare_site_init.md) procedure.

To retain the REDS/MEDS/RTS credentials:

```bash
ncn# yq delete -i /mnt/pitdata/${CSM_DISTDIR}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_reds_credentials
ncn# yq delete -i /mnt/pitdata/${CSM_DISTDIR}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_meds_credentials
ncn# yq delete -i /mnt/pitdata/${CSM_DISTDIR}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_hms_rts_credentials
```

## View Tracked Sealed Secrets

Tracked sealed secrets are regenerated every time secrets are seeded (see the
use of `utils/secrets-seed-customizations.sh` above).

To view currently tracked sealed secrets:

```bash
ncn# yq read /mnt/pitdata/${CSM_RELEASE}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets
```

Expected output looks similar to the following:

```yaml
- cray_reds_credentials
- cray_meds_credentials
- cray_hms_rts_credentials
```

## Decrypt Sealed Secrets for Review

Use the `secrets-decrypt.sh` utility in the `SHASTA-CFG` to decrypt and review previously encrypted
sealed secrets.

Syntax: `secret-decrypt.sh SEALED-SECRET-NAME SEALED-SECRET-PRIVATE-KEY CUSTOMIZATIONS-YAML`

For example:

```bash
ncn# cd /mnt/pitdata/prep/site-init &&
     ./utils/secrets-decrypt.sh cray_meds_credentials ./certs/sealed_secrets.key ./customizations.yaml | \
        jq .data.vault_redfish_defaults | sed -e 's/"//g' | base64 -d; echo
```

Expected output looks similar to the following:

```json
{"Username": "root", "Password": "..."}
```

## Fix an Incorrect Value in a Sealed Secret

This procedure describes how to correct an invalid password in the `customizations.yaml` file during an install.
In the following example, a typo was made in the `SNMPAuthPassword` field of the `vault_switch_defaults` credentials
in the `cray_reds_credentials` secret, resulting in hardware not being discovered.

The general process outlined in the following steps can be followed if a different value is incorrect.

```bash
ncn# ./utils/secrets-decrypt.sh cray_reds_credentials | jq -r '.data.vault_switch_defaults' | base64 --decode
```

Output looks similar to the following:

```json
{"SNMPUsername": "<USERID>", "SNMPAuthPassword": "<A-PASS>", "SNMPPrivPassword": "<P-PASS>"}
```

1. Decrypt the `cray_reds_credentials` secret.

   ```bash
   ncn# ./utils/secrets-decrypt.sh cray_reds_credentials > cray_reds_credentials.json
   ```

   The output file should look similar to the following.
   Note that the data values are `base64` encoded.

   ```json
   {
   "kind": "Secret",
   "apiVersion": "v1",
   "metadata": {
      "name": "cray-reds-credentials",
      "creationTimestamp": null,
      "annotations": {
         "sealedsecrets.bitnami.com/cluster-wide": "true"
      },
      "ownerReferences": [
         {
         "apiVersion": "bitnami.com/v1alpha1",
         "kind": "SealedSecret",
         "name": "cray-reds-credentials",
         "uid": "",
         "controller": true
         }
      ]
   },
   "data": {
      "vault_redfish_defaults": "eyJDcmF5IjogeyJVc2VybmFtZSI6ICJyb290IiwgIlBhc3N3b3JkIjogImluaXRpYWwwIn19",
      "vault_switch_defaults": "eyJTTk1QVXNlcm5hbWUiOiAidGVzdHVzZXIiLCAiU05NUEF1dGhQYXNzd29yZCI6ICJ0ZXN0cGFzMSIsICJTTk1QUHJpdlBhc3N3b3JkIjogInRlc3RwYXNzMiJ9"
   }
   }
   ```

1. Decode the `vault_switch_defaults` credentials to a working file.

   ```bash
   ncn# jq -r '.data.vault_switch_defaults' cray_reds_credentials.json | base64 --decode > vault_switch_defaults.json
   ```

1. Correct the password in the `vault_switch_defaults.json` file.

   ```json
   {"SNMPUsername": "<USERID>", "SNMPAuthPassword": "<A-PASS>", "SNMPPrivPassword": "<P-PASS>"}
   ```

1. Update `cray_reds_credentials.json` with an encoded version of the new password.

   ```bash
   ncn# cat <<< $(jq ".data.vault_switch_defaults=\"$(base64 --wrap=0 vault_switch_defaults.json)\"" cray_reds_credentials.json) > cray_reds_credentials.json
   ```

1. Verify that `cray_reds_credentials.json` has been updated with the new password.

   ```bash
   ncn# jq -r '.data.vault_switch_defaults' cray_reds_credentials.json | base64 --decode
   ```

   Example output:

   ```json
   {"SNMPUsername": "<USERID>", "SNMPAuthPassword": "<A-PASS>", "SNMPPrivPassword": "<P-PASS>"}
   ```

1. Replace the `cray_reds_credentials` secret in `customizations.yaml` with one containing the new credentials.

   ```bash
   ncn# cat cray_reds_credentials.json | ./utils/secrets-encrypt.sh | yq w -f - -i customizations.yaml 'spec.kubernetes.sealed_secrets.cray_reds_credentials'
   ```

1. Verify that `customizations.yaml` contains the updated password.

   ```bash
   ncn# ./utils/secrets-decrypt.sh cray_reds_credentials | jq -r '.data.vault_switch_defaults' | base64 --decode
   ```

   Example output:

   ```json
   {"SNMPUsername": "<USERID>", "SNMPAuthPassword": "<A-PASS>", "SNMPPrivPassword": "<P-PASS>"}
   ```
