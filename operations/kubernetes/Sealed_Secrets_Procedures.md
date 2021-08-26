## Sealed Secrets Procedures

- [Tracked Sealed Secrets](#tracked-sealed-secrets)
- [Decrypting Sealed Secrets for Review](#decrypting-sealed-secrets-for-review)

<a name="tracked-sealed-secrets"></a>
### 1.1 Tracked Sealed Secrets

Tracked sealed secrets are regenerated every time secrets are seeded (see the
use of `utils/secrets-seed-customizations.sh` above). View currently tracked
sealed secrets via:

```bash
linux# yq read /mnt/pitdata/${CSM_RELEASE}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets
```

Expected output looks similar to:

```
- cray_reds_credentials
- cray_meds_credentials
- cray_hms_rts_credentials
```

In order to prevent tracked sealed secrets from being regenerated, they **MUST
BE REMOVED** from the `spec.kubernetes.tracked_sealed_secrets` list in
`/mnt/pitdata/${CSM_RELEASE}/shasta-cfg/customizations.yaml` prior to [seeding](#generate-sealed-secrets).
To retain the REDS/MEDS/RTS credentials, run:

```bash
linux# yq delete -i /mnt/pitdata/${CSM_RELEASE}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_reds_credentials
linux# yq delete -i /mnt/pitdata/${CSM_RELEASE}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_meds_credentials
linux# yq delete -i /mnt/pitdata/${CSM_RELEASE}/shasta-cfg/customizations.yaml spec.kubernetes.tracked_sealed_secrets.cray_hms_rts_credentials
```

<a name="decrypting-sealed-secrets-for-review"></a>
### 1.2 Decrypting Sealed Secrets for Review

For administrators that would like to decrypt and review previously encrypted
sealed secrets, you can use the `secrets-decrypt.sh` utility in SHASTA-CFG.

Syntax: `secret-decrypt.sh SEALED-SECRET-NAME SEALED-SECRET-PRIVATE-KEY CUSTOMIZATIONS-YAML`

```bash
linux:/mnt/pitdata/prep/site-init# ./utils/secrets-decrypt.sh cray_meds_credentials ./certs/sealed_secrets.key ./customizations.yaml | jq .data.vault_redfish_defaults | sed -e 's/"//g' | base64 -d; echo
```

Expected output looks similar to:

```
{"Username": "root", "Password": "..."}
```
