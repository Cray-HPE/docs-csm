# Remove Kiali

If you do not plan to use Kiali, you can remove Kiali from your environment for CVE (Common Vulnerabilities and Exposures) remediation.
**NOTE:** The removal will not persist after an upgrade, so you will need to rerun the commands to remove Kiali after the upgrade.

## Procedure

1. Delete `kiali` deployment and `cray-kiali` chart.

    ```bash
    ncn-m# kubectl delete deployment kiali -n istio-system
    ncn-m# helm uninstall cray-kiali -n operators --keep-history
    ```

1. Remove `cray-kiali` chart from `loftsman-platform` ConfigMap.

    ```bash
    ncn-m# kubectl get configmap -n loftsman loftsman-platform -o json | jq -r '.data."manifest.yaml"' > platform.yaml
    ncn-m# cp platform.yaml platform.yaml.saved
    ncn-m# yq d -i platform.yaml 'spec.charts(name=='"cray-kiali"')'
    ncn-m# kubectl create configmap -n loftsman loftsman-platform --from-file=manifest.yaml=platform.yaml \
             --dry-run=client -o yaml | kubectl apply -f -
    ```
