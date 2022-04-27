# `kube-multus` pod is in `ImagePullBackOff`

## Description

There is a known problem where `kube-multus` pods may fail to restart due to an `ImagePullBackOff` error. The `multus:v3.1` image will need to be re-tagged in Nexus and the `kube-multus` pod will need to be restarted.

Run the following command to determine if any `kube-multus` pods are failing due to this issue. If any pods are in `ImagePullBackOff`, proceed with the fix.

```bash
ncn# kubectl get pods -n kube-system -l app=multus | grep ImagePullBackOff

kube-multus-ds-amd64-4wkb5   0/1    ImagePullBackOff    0          18h
```

## Fix

1. Re-tag the `multus` image in Nexus.

   ```bash
   ncn# podman run --rm --network host quay.io/skopeo/stable copy --src-tls-verify=false --dest-tls-verify=false docker://registry.local/docker.io/nfvpe/multus:v3.1 docker://registry.local/nfvpe/multus:v3.1
   ```

1. Restart the `kube-multus` pod that was found above to be in `ImagePullBackOff`.

   ```bash
   ncn# kubectl delete pod <KUBE-MULTUS-POD-NAME> -n kube-system
   ```

1. Verify all `kube-multus` pods are now `Running`.

   ```bash
   ncn# kubectl get pods -n kube-system -l app=multus
   ```
