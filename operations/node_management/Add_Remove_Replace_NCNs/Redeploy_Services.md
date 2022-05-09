# Redeploy Services Impacted by Adding or Permanently Removing Storage Nodes

This procedure redeploys S3 and `sysmgmt-health` services to add or remove storage node endpoints.

**This procedure can be skipped if a worker or master node has been added.** In that case, proceed to the next step to [Validate NCN](Validate_NCN.md) or return to the main [Add, Remove, Replace, or Move NCNs](../Add_Remove_Replace_NCNs.md) page.

**This procedure can be skipped if a worker or master node have been removed.** In that case, proceed to the next step to [Validate Health](Validate_Health.md) or return to the main [Add, Remove, Replace, or Move NCNs](../Add_Remove_Replace_NCNs.md) page.

Otherwise, if a storage node has been added or removed, proceed with the following steps.

## Prerequisite

The `docs-csm` RPM has been installed on the NCN. Verify that the following file exists:

```bash
ncn-m# ls /usr/share/docs/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs/update_customizations.sh
```

## Update the `nmn_ncn_storage` List

Update the `nmn_ncn_storage` list to include the IP addresses for any added or removed storage nodes.

### Acquire `site-init`

Before redeploying the desired charts, update the `customizations.yaml` file in the `site-init` secret in the `loftsman` namespace.

1. If the `site-init` repository is available as a remote repository [as described here](../../../install/prepare_site_init.md#push-to-a-remote-repository), then clone it to `ncn-m001`. Otherwise, ensure that the `site-init` repository is available on `ncn-m001`.

   ```bash
   ncn-m# git clone "$SITE_INIT_REPO_URL" site-init
   ```

1. Acquire `customizations.yaml` from the currently running system.

   ```bash
   ncn-m# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > site-init/customizations.yaml
   ```

1. Review, add, and commit `customizations.yaml` to the local `site-init` repository as appropriate.

   > **`NOTE:`** If `site-init` was cloned from a remote repository in step 1,
   > there may not be any differences and hence nothing to commit. This is
   > okay. If there are differences between what is in the repository and what
   > was stored in the `site-init`, then it suggests settings were changed at some
   > point.

   ```bash
   ncn-m# cd site-init
   ncn-m# git diff
   ncn-m# git add customizations.yaml
   ncn-m# git commit -m 'Add customizations.yaml from site-init secret'
   ```

### Modify the Customizations

Modify the customizations to include the added or removed storage node.

1. Retrieve an API token.

   ```bash
   ncn-m# export TOKEN=$(curl -s -S -d grant_type=client_credentials \
       -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
       -o jsonpath='{.data.client-secret}' | base64 -d` \
       https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
       | jq -r '.access_token')
   ```

1. Update the customizations `spec.network.netstaticips.nmn_ncn_storage` for the added or removed storage IP address.

   ```bash
   ncn-m# cd /usr/share/docs/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs
   ncn-m# ./update_customizations.sh
   ```

1. Check that the updated `customizations.yaml` contains the change to add or remove a storage IP address.

   ```bash
   ncn-m# yq r /tmp/customizations.original.yaml -P > /tmp/customizations.original.yaml.pretty
   ncn-m# diff /tmp/customizations.original.yaml.pretty /tmp/customizations.yaml
   ```

   Example output:

   ```text
   10.252.1.13
   ```

1. Check in changes made to `customizations.yaml`.

   ```bash
   ncn-m# cd site-init
   ncn-m# cp /tmp/customizations.yaml customizations.yaml
   ncn-m# git diff
   ncn-m# git add customizations.yaml
   ncn-m# git commit -m 'Update customizations.yaml nmn_ncn_storage storage IPs'
   ```

1. Push to the remote repository as appropriate.

    ```bash
    ncn-m# git push
    ```

1. Update `site-init` sealed secret in `loftsman` namespace.

    ```bash
    ncn-m# kubectl delete secret -n loftsman site-init
    ncn-m# kubectl create secret -n loftsman generic site-init --from-file=/tmp/customizations.yaml
    ```

### Redeploy S3

Redeploy S3 to pick up any changes for storage node endpoints.

1. Determine the version of S3.

    ```bash
    ncn-m# S3_VERSION=$(kubectl -n loftsman get cm loftsman-platform -o jsonpath='{.data.manifest\.yaml}' |
                        yq r - 'spec.charts.(name==cray-s3).version')
    ncn-m# echo $S3_VERSION
    ```

1. Create `s3-manifest.yaml`.

    ```bash
    ncn-m# cat > s3-manifest.yaml << EOF
    apiVersion: manifests/v1beta1
    metadata:
        name: s3
    spec:
        charts:
        - name: cray-s3
          version: $S3_VERSION
          namespace: ceph-rgw
    EOF
    ```

1. Merge `customizations.yaml` with `s3-manifest.yaml`.

    ```bash
    ncn-m# manifestgen -c /tmp/customizations.yaml -i s3-manifest.yaml > s3-manifest.out.yaml
    ```

1. Redeploy the S3 helm chart.

    ```bash
    ncn-m# loftsman ship \
        --charts-repo https://packages.local/repository/charts \
        --manifest-path s3-manifest.out.yaml
    ```

1. Check that the new endpoint has been updated.

    ```bash
    ncn-m# kubectl get endpoints -l app.kubernetes.io/instance=cray-s3 -n ceph-rgw -o jsonpath='{.items[*].subsets[].addresses}' | jq -r '.[] | .ip'
    ```

    Example output:

    ```text
    10.252.1.13
    10.252.1.4
    10.252.1.5
    10.252.1.6
    ```

### Redeploy `sysmgmt-health`

Redeploy `sysmgmt-health` to pick up any changes for storage node endpoints.

1. Determine the version of `sysmgmt-health`.

    ```bash
    ncn-m# SYSMGMT_VERSION=$(kubectl -n loftsman get cm loftsman-platform -o jsonpath='{.data.manifest\.yaml}' |
                             yq r - 'spec.charts.(name==cray-sysmgmt-health).version')
    ncn-m# echo $SYSMGMT_VERSION
    ```

1. Determine the current resources.

    ```bash
    ncn-m# kubectl -n loftsman get cm loftsman-platform -o jsonpath='{.data.manifest\.yaml}' | 
              yq r - 'spec.charts.(name==cray-sysmgmt-health).values.prometheus-operator.prometheus.prometheusSpec.resources'
    ```

    Example output:

    ```yaml
    limits:
      cpu: '6'
      memory: 30Gi
    requests:
      cpu: '2'
      memory: 15Gi
    ```

1. Determine the current retention settings.

    ```bash
    ncn-m# kubectl -n loftsman get cm loftsman-platform -o jsonpath='{.data.manifest\.yaml}' | yq r - 'spec.charts.(name==cray-sysmgmt-health).values.prometheus-operator.prometheus.prometheusSpec.retention'
    ```

    Example output:

    ```text
    48h
    ```

1. Create `sysmgmt-health-manifest.yaml` and update the `resources` and `retention` sections as needed based upon the data from the previous steps.

    ```bash
    ncn-m# cat > sysmgmt-health-manifest.yaml << EOF
    apiVersion: manifests/v1beta1
    metadata:
        name: sysmgmt-health
    spec:
        charts:
        - name: cray-sysmgmt-health
          version: $SYSMGMT_VERSION
          namespace: sysmgmt-health
          values:
            prometheus-operator:
              prometheus:
                prometheusSpec:
                  resources:
                    limits:
                      cpu: '6'
                      memory: 30Gi
                    requests:
                      cpu: '2'
                      memory: 15Gi
                  retention: 48h
    EOF
    ```

1. Merge `customizations.yaml` with `sysmgmt-health-manifest.yaml`.

    ```bash
    ncn-m# manifestgen -c /tmp/customizations.yaml -i sysmgmt-health-manifest.yaml > sysmgmt-health-manifest.out.yaml
    ```

1. Redeploy the `sysmgmt-health` helm chart.

    ```bash
    ncn-m# loftsman ship \
        --charts-repo https://packages.local/repository/charts \
        --manifest-path sysmgmt-health-manifest.out.yaml
    ```

1. Check that the new endpoint has been updated.

    ```bash
    ncn-m# kubectl get endpoints -l app=cray-sysmgmt-health-ceph-exporter -n sysmgmt-health -o jsonpath='{.items[*].subsets[].addresses}' | jq -r '.[] | .ip'
    ncn-m# kubectl get endpoints -l app=cray-sysmgmt-health-ceph-node-exporter -n sysmgmt-health -o jsonpath='{.items[*].subsets[].addresses}' | jq -r '.[] | .ip'
    ```

    Example output:

    ```text
    10.252.1.13
    10.252.1.4
    10.252.1.5
    10.252.1.6
    ```

### Cleanup

Remove temporary files.

```bash
ncn-m# rm /tmp/customizations.yaml /tmp/customizations.original.yaml /tmp/customizations.original.yaml.pretty
```

## Next Step

Proceed to the next step:

- If a storage NCN was added, proceed to [Validate NCN](Validate_NCN.md) or return to the main [Add, Remove, Replace, or Move NCNs](../Add_Remove_Replace_NCNs.md) page.
- If a storage NCN was removed, proceed to [Validate Health](Validate_Health.md) or return to the main [Add, Remove, Replace, or Move NCNs](../Add_Remove_Replace_NCNs.md) page.
