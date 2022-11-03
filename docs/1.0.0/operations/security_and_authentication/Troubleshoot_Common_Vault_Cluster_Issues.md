# Troubleshoot Common Vault Cluster Issues

Search for underlying issues causing unhealthy Vault clusters. Check the Vault `statefulset` and various pod logs to determine what is impacting the health of the Vault.

## Procedure

1. View the Vault `statefulset`.

    ```bash
    ncn-mw# kubectl -n vault get statefulset --show-labels
    ```

    Example output:

    ```text
    NAME         READY   AGE   LABELS
    cray-vault   3/3     8d    app.kubernetes.io/name=vault,vault_cr=cray-vault
    ```

1. Check the pod logs for the `bank-vaults` container for Vault `statefulset` pods.

    ```bash
    ncn-mw# kubectl logs -n vault cray-vault-0 --tail=-1 --prefix -c bank-vaults
    ncn-mw# kubectl logs -n vault cray-vault-1 --tail=-1 --prefix -c bank-vaults
    ncn-mw# kubectl logs -n vault cray-vault-0 --tail=-1 --prefix -c bank-vaults
    ```

1. Check the Vault container logs within the pod.

    ```bash
    ncn-mw# kubectl logs -n vault cray-vault-0 --tail=-1 --prefix -c vault
    ncn-mw# kubectl logs -n vault cray-vault-1 --tail=-1 --prefix -c vault
    ncn-mw# kubectl logs -n vault cray-vault-2 --tail=-1 --prefix -c vault
    ```

1. Check the Vault operator pod logs using ephemerally named pods.

    ```bash
    ncn-mw# kubectl logs -n vault cray-vault-operator-7dbbdbb68b-zvg2g --tail=-1 --prefix
    ```
