# Redeploy Services Impacted by Adding or Permanently Removing Storage Nodes

This procedure redeploys S3 and `sysmgmt-health` services to add or remove storage node endpoints.

**This procedure can be skipped if a worker or master node has been added.** In that case, proceed to the next step to [Validate NCN](Validate_NCN.md) or return to the main [Add, Remove, Replace, or Move NCNs](Add_Remove_Replace_NCNs.md) page.

**This procedure can be skipped if a worker or master node have been removed.** In that case, proceed to the next step to [Validate Health](Validate_Health.md) or return to the main [Add, Remove, Replace, or Move NCNs](Add_Remove_Replace_NCNs.md) page.

Otherwise, if a storage node has been added or removed, proceed with the following steps.

## Prerequisite

The `docs-csm` RPM has been installed on the NCN. Verify that the following file exists:

```bash
ls /usr/share/docs/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs/update_customizations.sh
```

## Update the `nmn_ncn_storage` list

Update the `nmn_ncn_storage` list to include the IP addresses for any added or removed storage nodes.

### Acquire `site-init`

Before redeploying the desired charts, update the `customizations.yaml` file in the `site-init` secret in the `loftsman` namespace.

1. If the `site-init` repository is available as a remote repository, then clone it to `ncn-m001`. Otherwise, ensure that the `site-init` repository is available on `ncn-m001`.

   ```bash
   git clone "$SITE_INIT_REPO_URL" site-init
   ```

1. Acquire `customizations.yaml` from the currently running system.

   ```bash
   kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > site-init/customizations.yaml
   ```

1. Review, add, and commit `customizations.yaml` to the local `site-init` repository as appropriate.

   > **`NOTE:`** If `site-init` was cloned from a remote repository in step 1,
   > there may not be any differences and hence nothing to commit. This is
   > okay. If there are differences between what is in the repository and what
   > was stored in the `site-init`, then it suggests settings were changed at some
   > point.

   ```bash
   cd site-init
   git diff
   git add customizations.yaml
   git commit -m 'Add customizations.yaml from site-init secret'
   ```

### Modify the customizations

Modify the customizations to include the added or removed storage node.

1. Retrieve an API token.

   ```bash
   export TOKEN=$(curl -s -S -d grant_type=client_credentials \
       -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \
       -o jsonpath='{.data.client-secret}' | base64 -d` \
       https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
       | jq -r '.access_token')
   ```

1. Update the customizations `spec.network.netstaticips.nmn_ncn_storage` for the added or removed storage IP address.

   ```bash
   cd /usr/share/docs/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs
   ./update_customizations.sh
   ```

1. Check that the updated `customizations.yaml` contains the change to add or remove a storage IP address.

   ```bash
   yq r /tmp/customizations.original.yaml -P > /tmp/customizations.original.yaml.pretty
   diff /tmp/customizations.original.yaml.pretty /tmp/customizations.yaml
   ```

   Example output:

   ```text
   10.252.1.13
   ```

1. Check in changes made to `customizations.yaml`.

   ```bash
   cd site-init
   cp /tmp/customizations.yaml customizations.yaml
   git diff
   git add customizations.yaml
   git commit -m 'Update customizations.yaml nmn_ncn_storage storage IPs'
   ```

1. Push to the remote repository as appropriate.

    ```bash
    git push
    ```

1. Update `site-init` sealed secret in `loftsman` namespace.

    ```bash
    kubectl delete secret -n loftsman site-init
    kubectl create secret -n loftsman generic site-init --from-file=/tmp/customizations.yaml
    ```

### Redeploy S3

Redeploy S3 to pick up any changes for storage node endpoints. Follow the [Redeploying a Chart](../../CSM_product_management/Redeploying_a_Chart.md) procedure with the following specifications:

- Name of chart to be redeployed: `cray-s3`
- Base name of manifest: `platform`
- No customization changes need to be made during the redeploy procedure -- they were already done earlier on this page.
- (`ncn-mw#`) When reaching the step to validate that the redeploy was successful, perform the following step:

    **Only follow this step as part of the previously linked chart redeploy procedure.**

    Check that the new endpoint has been updated.

    ```bash
    kubectl get endpoints -l app.kubernetes.io/instance=cray-s3 -n ceph-rgw -o jsonpath='{.items[*].subsets[].addresses}' | jq -r '.[] | .ip'
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

Follow the [Redeploying a Chart](../../CSM_product_management/Redeploying_a_Chart.md) procedure with the following specifications:

- Name of chart to be redeployed: `cray-sysmgmt-health`
- Base name of manifest: `platform`
- No customization changes need to be made during the redeploy procedure -- they were already done earlier on this page.
- (`ncn-mw#`) When reaching the step to validate that the redeploy was successful, perform the following step:

    **Only follow this step as part of the previously linked chart redeploy procedure.**

    Check that the new endpoint has been updated.

    ```bash
    kubectl get endpoints -l app=cray-sysmgmt-health-ceph-exporter -n sysmgmt-health -o jsonpath='{.items[*].subsets[].addresses}' | jq -r '.[] | .ip'
    kubectl get endpoints -l app=cray-sysmgmt-health-ceph-node-exporter -n sysmgmt-health -o jsonpath='{.items[*].subsets[].addresses}' | jq -r '.[] | .ip'
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
rm /tmp/customizations.yaml /tmp/customizations.original.yaml /tmp/customizations.original.yaml.pretty
```

## Next step

Proceed to the next step:

- If a storage NCN was added, proceed to [Validate NCN](Validate_NCN.md) or return to the main [Add, Remove, Replace, or Move NCNs](Add_Remove_Replace_NCNs.md) page.
- If a storage NCN was removed, proceed to [Validate Health](Validate_Health.md) or return to the main [Add, Remove, Replace, or Move NCNs](Add_Remove_Replace_NCNs.md) page.
