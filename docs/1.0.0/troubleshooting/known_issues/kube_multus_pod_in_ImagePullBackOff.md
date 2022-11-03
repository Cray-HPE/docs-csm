# `kube-multus` pod is in `ImagePullBackOff`

## Description

There is a known problem where `kube-multus` pods may fail to restart due to an `ImagePullBackOff` error. The `multus:v3.1` image will need to be re-tagged in Nexus and the `kube-multus` pod will need to be restarted.

Run the following command to determine if any `kube-multus` pods are failing due to this issue. If any pods are in `ImagePullBackOff`, proceed with the fix.

```bash
ncn# kubectl get pods -n kube-system -l app=multus | grep ImagePullBackOff

kube-multus-ds-amd64-4wkb5   0/1    ImagePullBackOff    0          18h
```

## Fix

### Option 1

If you have access to the `quay.io/skopeo/stable` image in nexus or an outside repository, you can use `skopeo` to re-tag the `multus` image in nexus.

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

### Option 2

If you do not have access to the `quay.io/skopeo/stable` image, you can use this hotfix.

1. Download `https://storage.googleapis.com/csm-release-public/hotfix/casmrel-631_multus-image_hotfix-0.0.1.tar.gz` on a device that has access to the internet and transfer the file to one of the management NCNs.

1. Untar the hotfix tarball.

   ```bash
   ncn# tar -zxvf casmrel-631_multus-image_hotfix-0.0.1.tar.gz
   ```

1. Follow the instructions in `./casmrel-631_multus-image_hotfix/README.md`
