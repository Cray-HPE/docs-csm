# Update SNMP Credentials on Existing Management Switches

This procedure changes the SNMPv3 credentials used on management network switches that are already
discovered by CSM, and updates the matching per-switch credentials stored in Vault.

HMS Discovery and the SNMP backed Redfish Translation Service (RTS) read SNMP credentials for each switch from
Vault at `secret/hms-creds/<switch-xname>`. HMS Discovery only writes that entry when it is empty, using the
default credentials in `secret/reds-creds/switch_defaults`. As a result, updating the default credentials does
**not** change the credentials used for switches that already exist. For existing switches, the credentials
must be changed in three places so that they match:

- The running configuration of each management switch
- The per-switch entries in Vault (`secret/hms-creds/<switch-xname>`)
- The default credentials (`cray_reds_credentials` sealed secret in `customizations.yaml` and
  `secret/reds-creds/switch_defaults` in Vault), so that switches added later use the same values

- [Prerequisites](#prerequisites)
- [Procedure](#procedure)
    1. [Set up the Vault alias](#1-set-up-the-vault-alias)
    1. [Identify the management switches](#2-identify-the-management-switches)
    1. [(Optional) Review the current SNMP credentials in Vault](#3-optional-review-the-current-snmp-credentials-in-vault)
    1. [Update SNMP on the management switches](#4-update-snmp-on-the-management-switches)
    1. [Update the SNMP credentials in Vault](#5-update-the-snmp-credentials-in-vault)
    1. [Update the default SNMP credentials](#6-update-the-default-snmp-credentials)
    1. [Restart the SNMP backed RTS](#7-restart-the-snmp-backed-rts)
    1. [Verify](#8-verify)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- The Cray command line interface (CLI) tool is initialized and configured on the system.
- The `admin` password for the management network switches is known.
- The new SNMPv3 username, authentication password, and privacy password have been chosen.
  SNMPv3 passwords must be at least 8 characters.

## Procedure

### 1. Set up the Vault alias

(`ncn-mw#`) Set the Vault alias, if it is not already set.

```bash
VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json | jq -r '.data["vault-root"]' | base64 -d)
alias vault='kubectl -n vault exec -i cray-vault-0 -c vault -- env VAULT_TOKEN="$VAULT_PASSWD" VAULT_ADDR=http://127.0.0.1:8200 VAULT_FORMAT=json vault'
```

### 2. Identify the management switches

(`ncn-mw#`) List the management switches known to SLS.

HMS Discovery uses the leaf-BMC switches (`comptype_mgmt_switch`) to discover air-cooled hardware.
Spine, leaf, and CDU switches are listed so that their credentials can be kept consistent.

```bash
for TYPE in comptype_mgmt_switch comptype_hl_switch comptype_cdu_mgmt_switch; do
    cray sls search hardware list --type "${TYPE}" --format json |
        jq -r '.[] | [.Xname, .ExtraProperties.Aliases[0], .ExtraProperties.Brand] | @tsv'
done | sort -k2
```

Example output:

```text
d100w1          sw-cdu-001      Aruba
d100w2          sw-cdu-002      Aruba
x3000c0w35      sw-leaf-bmc-001 Aruba
x3000c0w36      sw-leaf-bmc-002 Aruba
x3000c0h38s1    sw-spine-001    Aruba
x3000c0h39s1    sw-spine-002    Aruba
```

### 3. (Optional) Review the current SNMP credentials in Vault

(`ncn-mw#`) Show the SNMP username and password lengths stored in Vault for each leaf-BMC switch, without printing the passwords.

```bash
cray sls search hardware list --type comptype_mgmt_switch --format json |
    jq -r '.[] | "\(.Xname) \(.ExtraProperties.Aliases[0])"' |
    while read -r XNAME ALIAS; do
        CREDS=$(vault kv get "secret/hms-creds/${XNAME}" </dev/null 2>/dev/null |
            jq -r '.data | "Username=\(.Username) SNMPAuthPass_length=\(.SNMPAuthPass | length) SNMPPrivPass_length=\(.SNMPPrivPass | length)"')
        printf '%-12s %-17s %s\n' "${XNAME}" "${ALIAS}" "${CREDS:-MISSING}"
    done
```

Example output:

```text
x3000c0w35   sw-leaf-bmc-001   Username=testuser SNMPAuthPass_length=9 SNMPPrivPass_length=9
x3000c0w36   sw-leaf-bmc-002   Username=testuser SNMPAuthPass_length=13 SNMPPrivPass_length=13
```

Differing values indicate inconsistent credentials. `MISSING` means the switch has no Vault entry; see [Troubleshooting](#troubleshooting).

### 4. Update SNMP on the management switches

(`sw#`) On each leaf-BMC switch, configure the new SNMPv3 username, authentication password, and privacy password
by following the switch configuration steps in [Configuring SNMP in CSM](configure_snmp.md#how-snmp-is-used-in-csm),
including persisting the settings in the CANU custom configuration.

If the SNMP username changed, remove the old SNMP user from each switch after the new credentials are verified
in [Verify](#8-verify).

### 5. Update the SNMP credentials in Vault

1. (`ncn-mw#`) Store the new SNMPv3 credentials in environment variables, using the same values configured on the switches.

    ```bash
    read -p "SNMP username: " SNMP_USER
    read -s -p "SNMP authentication password: " SNMP_AUTH_PASS; echo
    read -s -p "SNMP privacy password: " SNMP_PRIV_PASS; echo
    export SNMP_USER SNMP_AUTH_PASS SNMP_PRIV_PASS
    ```

1. (`ncn-mw#`) Update the per-switch Vault entries. The existing `URL`, `Password`, and `Xname` values are preserved.

    - To update all leaf-BMC switches:

        ```bash
        for XNAME in $(cray sls search hardware list --type comptype_mgmt_switch --format json | jq -r '.[].Xname'); do
            echo "Updating SNMP credentials for ${XNAME}"
            vault kv get "secret/hms-creds/${XNAME}" |
                jq '.data | .Username = $ENV.SNMP_USER | .SNMPAuthPass = $ENV.SNMP_AUTH_PASS | .SNMPPrivPass = $ENV.SNMP_PRIV_PASS' |
                vault kv put "secret/hms-creds/${XNAME}" -
        done
        ```

    - To update a single switch:

        ```bash
        XNAME=x3000c0w35
        vault kv get "secret/hms-creds/${XNAME}" |
            jq '.data | .Username = $ENV.SNMP_USER | .SNMPAuthPass = $ENV.SNMP_AUTH_PASS | .SNMPPrivPass = $ENV.SNMP_PRIV_PASS' |
            vault kv put "secret/hms-creds/${XNAME}" -
        ```

1. (`ncn-mw#`) Run the command from [Review the current SNMP credentials in Vault](#3-optional-review-the-current-snmp-credentials-in-vault)
   and confirm that every switch shows the new username and password lengths.

### 6. Update the default SNMP credentials

Follow [Update Default Air-Cooled BMC and Leaf-BMC Switch SNMP Credentials](../../security_and_authentication/Update_Default_Air-Cooled_BMC_and_Leaf_BMC_Switch_SNMP_Credentials.md)
with the same values, including saving the updated `customizations.yaml`; otherwise the old defaults are restored during the next CSM upgrade.

### 7. Restart the SNMP backed RTS

(`ncn-mw#`) Restart the SNMP backed RTS to pick up the new credentials.

```bash
kubectl -n services rollout restart deployment cray-hms-rts-snmp
kubectl -n services rollout status deployment cray-hms-rts-snmp
```

### 8. Verify

1. (`ncn-mw#`) Wait a few minutes, then check the SNMP backed RTS logs for SNMP authentication errors.

    ```bash
    kubectl -n services logs deployment/cray-hms-rts-snmp --all-containers --since=15m |
        grep -E 'UsmStatsWrongDigests|UsmStatsUnknownUserNames|UsmStatsDecryptionErrors'
    ```

    If nothing is returned, then RTS is able to communicate with the switches using the new credentials.

1. (`ncn-mw#`) Check the most recent HMS Discovery run for SNMP errors.

    ```bash
    POD=$(kubectl -n services get pods --sort-by=.metadata.creationTimestamp -o name | grep '/hms-discovery-' | tail -n 1)
    kubectl -n services logs "${POD}" --all-containers | grep -E 'UsmStats|Failed to get ifIndex|Switches with'
    ```

1. (`ncn-mw#`) Verify that air-cooled hardware is discovered.

    ```bash
    /opt/cray/csm/scripts/hms_verification/verify_hsm_discovery.py
    ```

1. (`ncn-mw#`) Clear the credential environment variables.

    ```bash
    unset SNMP_USER SNMP_AUTH_PASS SNMP_PRIV_PASS
    ```

## Troubleshooting

| Error in logs | Meaning | Action |
|---|---|---|
| `UsmStatsWrongDigests` | The authentication password in Vault does not match the switch. | Re-check step 4 and step 5 for the affected switch. |
| `UsmStatsUnknownUserNames` | The SNMP username in Vault does not exist on the switch. | Confirm the user was created on the switch and that `Username` in Vault matches. |
| `UsmStatsDecryptionErrors` | The privacy password or privacy protocol does not match. | Confirm the privacy password and that the switch uses DES. |

- If a switch has no entry in `secret/hms-creds/<xname>`, HMS Discovery creates it on its next run using
  `secret/reds-creds/switch_defaults`. Complete [Update the default SNMP credentials](#6-update-the-default-snmp-credentials) first.
- If SNMP is disabled on a switch (for example, `show snmp` on a Mellanox switch reports `SNMP enabled: no`),
  enable it on the switch (see step 4). SNMP on spine switches is only required if they are monitored by the Prometheus SNMP Exporter.
