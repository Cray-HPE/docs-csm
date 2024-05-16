# `cray-product-catalog` upgrade error 

- [Description](#description)
- [Workaround](#workaround)

## Description

During a system upgrade it is possible to encounter the following error during the "Upgrade Services" stage while running `upgrade.sh`:

```
Error releasing chart cray-product-catalog v1.8.3: Shell error: Error: UPGRADE FAILED: pre-upgrade hooks failed: timed out waiting for the condition chart=cray-product-catalog command=ship namespace=services version=1.8.3
```

This can occur for any version of the product catalog, only occurs on systems where many product versions have been installed.

## Workaround

1. (`ncn-mw#`) Backup the current data to a file:

    ```bash
    kubectl get cm -n services cray-product-catalog -o yaml > cray-product-catalog-backup.yaml
    ```

1. (`ncn-mw#`) Delete the contents of the "data:" stanza in the product catalog:

    ```bash
    kubectl patch cm -n services cray-product-catalog -p '{ "data": null }'
    ```

1. (`ncn-mw#`) Delete the "cpc-backup" configmap, if it exists (it's okay if it does not exist).

    ```bash
    kubectl delete cm -n services cpc-backup
    ```

1. (`ncn-mw#`) Upgrade the chart as usual.

1. (`ncn-mw#`) Edit the configmap and add back in the 'data:' stanza from the file saved in step #1:

    ```bash
    kubectl edit cm -n services cray-product-catalog
    ```
