# Remove Kiali

If not planning to use Kiali, then Kiali may be removed for CVE (Common Vulnerabilities and Exposures) remediation.
**NOTE:** The removal will not persist after a CSM upgrade, so the removal procedure must be rerun after CSM upgrades.

## Procedure

This procedure can be performed on any master node.

1. Delete `kiali` and `kiali-operator` deployments.

    ```bash
    kubectl delete deployment kiali -n istio-system
    kubectl delete deployment cray-kiali-kiali-operator -n operators
    ```

1. Uninstall `cray-kiali` chart.

    ```bash
    helm uninstall cray-kiali -n operators --keep-history
    ```

1. Remove `cray-kiali` chart from `loftsman-platform` ConfigMap.

    ```bash
    kubectl get configmap -n loftsman loftsman-platform -o json | jq -r '.data."manifest.yaml"' > platform.yaml
    cp platform.yaml platform.yaml.saved
    yq d -i platform.yaml 'spec.charts(name=='"cray-kiali"')'
    kubectl create configmap -n loftsman loftsman-platform --from-file=manifest.yaml=platform.yaml \
       --dry-run=client -o yaml | kubectl apply -f -
    ```
