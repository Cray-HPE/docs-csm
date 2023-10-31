# HashiCorp Vault

- [Overview](#overview)
- [Storage model](#storage-model)
- [Unseal keys](#unseal-keys)
- [Administrative access](#administrative-access)
- [Kubernetes service account access](#kubernetes-service-account-access)
- [Check the status of Vault clusters](#check-the-status-of-vault-clusters)

## Overview

A deployment of HashiCorp Vault, managed via the Bitnami `Bank-vaults` operator, stores private and public Certificate Authority
\(CA\) material, and serves APIs through a PKI engine instance. This instance also serves as a general secrets engine for the system.

(`ncn-mw#`) Kubernetes service account authorization is utilized to authenticate access to Vault. The configuration of Vault, as deployed on
the system, can be viewed with the following command:

```bash
kubectl get vault -n vault cray-vault -o yaml
```

A Kubernetes operator manages the deployment of Vault, based on this definition. The operator is deployed to the `vault` namespace.
The resulting instance is deployed to the `vault` namespace.

**IMPORTANT:** Changing the `cray-vault` custom resource definition or modifying data directly in Vault is not supported unless directed by customer support.

For more information, refer to the following resources:

- [`Bank-vaults` external documentation](https://banzaicloud.com/docs/bank-vaults/overview/)
- [Vault external documentation](https://www.vaultproject.io/docs)

## Storage model

In previous releases, Vault used etcd as a high-availability \(HA\) storage back-end. Currently, Vault uses HashiCorp's Raft
implementation. Raft is now configured to run natively inside the Vault StatefulSet instead of as an independent deployment.

## Unseal keys

Vault requires unseal keys for start-up. If the unseal keys are not present, or are incorrect, Vault \(by design\) will not start.
Unseal keys are stored in the `cray-vault-unseal-keys` Kubernetes Secret on a system, which is inside the `vault` namespace.

## Administrative access

Administrative access to Vault can be accomplished through the use of the unseal secret. The use of administrative access should be
limited to situations where it is truly necessary. Otherwise, Kubernetes service account access should be used.

(`ncn-mw#`) To obtain and use the `root` token:

```bash
VAULT_TOKEN=$(kubectl get secrets cray-vault-unseal-keys -n vault -o jsonpath={.data.vault-root} | base64 -d)
kubectl exec -it -n vault -c vault cray-vault-0 -- sh -c "VAULT_ADDR=http://localhost:8200 VAULT_TOKEN=$VAULT_TOKEN vault secrets list"
```

## Kubernetes service account access

Vault is configured to allow service account access from the `services` namespace \(among others\). This access is tied to a role,
which is also subject to specific access policies.

(`ncn-mw#`) To obtain and use the service account token:

```bash
SA_SECRET=$(kubectl -n services get serviceaccounts default -o jsonpath='{.secrets[0].name}')
SA_JWT=$(kubectl -n services get secret $SA_SECRET -o jsonpath='{.data.token}' | base64 --decode)
VAULT_TOKEN=$(kubectl exec -it -n vault -c vault cray-vault-0 -- sh -c \
    "export VAULT_ADDR=http://localhost:8200; vault write auth/kubernetes/login role=services jwt=$SA_JWT -format=json" \
    | jq ".auth.client_token" | sed -e 's/"//g')
kubectl exec -it -n vault -c vault cray-vault-0 -- sh -c "VAULT_ADDR=http://localhost:8200 VAULT_TOKEN=$VAULT_TOKEN vault kv list secret/"
```

Service account tokens will eventually expire.

## Check the status of Vault clusters

(`ncn-mw#`) Check the status of Vault clusters with the following command:

```bash
for n in $(seq 0 2); do echo "======= Vault status from cray-vault-${n} ======"; kubectl exec -it -n vault -c vault cray-vault-${n} -- sh -c "VAULT_ADDR=http://localhost:8200 vault status"; done
```

Example output:

```text
======= Vault status from cray-vault-0 ======
Key                     Value
---                     -----
Seal Type               shamir
Initialized             true
Sealed                  false
Total Shares            5
Threshold               3
Version                 1.5.5
Cluster Name            vault-cluster-e19b13b8
Cluster ID              3ea3b6a2-f3f8-fda3-d997-454795dc2be5
HA Enabled              true
HA Cluster              https://cray-vault-1:8201
HA Mode                 standby
Active Node Address     http://cray-vault.vault:8200
Raft Committed Index    521
Raft Applied Index      521
======= Vault status from cray-vault-1 ======
Key                     Value
---                     -----
Seal Type               shamir
Initialized             true
Sealed                  false
Total Shares            5
Threshold               3
Version                 1.5.5
Cluster Name            vault-cluster-e19b13b8
Cluster ID              3ea3b6a2-f3f8-fda3-d997-454795dc2be5
HA Enabled              true
HA Cluster              https://cray-vault-1:8201
HA Mode                 active
Raft Committed Index    521
Raft Applied Index      521
======= Vault status from cray-vault-2 ======
Key                     Value
---                     -----
Seal Type               shamir
Initialized             true
Sealed                  false
Total Shares            5
Threshold               3
Version                 1.5.5
Cluster Name            vault-cluster-e19b13b8
Cluster ID              3ea3b6a2-f3f8-fda3-d997-454795dc2be5
HA Enabled              true
HA Cluster              https://cray-vault-1:8201
HA Mode                 standby
Active Node Address     http://cray-vault.vault:8200
Raft Committed Index    521
Raft Applied Index      521
```

Healthy clusters will have one Vault pod in active HA mode, and two Vault pods in standby HA mode. All instances should also be unsealed and initialized.
