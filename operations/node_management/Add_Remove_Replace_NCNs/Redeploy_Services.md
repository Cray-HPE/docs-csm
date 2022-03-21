## Redeploy Services Impacted by Adding or Permanently Removing Storage Nodes

This procedure redeploys S3 and SYSMGMT_HEALTH services to add or remove storage node endpoints.

### Procedure

### 1. Update the `nmn_ncn_storage` list to include the IPs for any added or removed storage nodes.

#### 1.1 Acquire site-init.

Before redeploying the desired charts, update the `customizations.yaml` file in the `site-init` secret in the `loftsman` namespace.

1. If the `site-init` repository is available as a remote repository [as described here](../../install/prepare_site_init.md#push-to-a-remote-repository), then clone it to ncn-m001. Otherwise, ensure that the `site-init` repository is available on ncn-m001.

   ```bash
   ncn-m001# git clone "$SITE_INIT_REPO_URL" site-init
   ```

2. Acquire `customizations.yaml` from the currently running system.

   ```bash
   ncn-m001# kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > site-init/customizations.yaml
   ```

3. Review, add, and commit `customizations.yaml` to the local `site-init` repository as appropriate.

   > **`NOTE:`** If `site-init` was cloned from a remote repository in step 1,
   > there may not be any differences and hence nothing to commit. This is
   > okay. If there are differences between what is in the repository and what
   > was stored in the `site-init`, then it suggests settings were changed at some
   > point.

   ```bash
   ncn-m001# cd site-init
   ncn-m001# git diff
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m 'Add customizations.yaml from site-init secret'
   ```

#### 1.2 Modify the customizations to include the added or removed storage node .

1. Update the customizations `spec.network.netstaticips.nmn_ncn_storage` for the added or removed storage IP.

   ```bash
   ncn-m001# cd /usr/share/docs/csm/scripts/operations/node_management/Add_Remove_Replace_NCNs
   ncn-m001# ./update_customizations.sh
   ```

2. Check that the updated customizations.yaml contains the change to add or remove a storage IP.
   
   ```bash
   ncn-m001# yq r /tmp/customizations.orginal.yaml -P > /tmp/customizations.orginal.yaml.pretty
   ncn-m001# diff /tmp/customizations.orginal.yaml.pretty /tmp/customizations.yaml
   ```

3. Check in changes made to `customizations.yaml`

   ```bash
   ncn-m001# cd site-init
   ncn-m001# mv /tmp/customizations.yaml customizations.yaml
   ncn-m001# git diff
   ncn-m001# git add customizations.yaml
   ncn-m001# git commit -m 'Update customizations.yaml nmn_ncn_storage storage IPs'
   ```

4. Push to the remote repository as appropriates.

    ```bash
    ncn-m001# git push
    ```

5. Update `site-init` sealed secret in `loftsman` namespace.

    ```bash
    ncn-m001# kubectl delete secret -n loftsman site-init
    ncn-m001# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
    ```

#### 1.3 Redeploy S3 to pick up any changes for storage node endpoints.

1. Determine the version of S3:

    ```bash
    ncn-m001# S3_VERSION=$(kubectl -n loftsman get cm loftsman-platform -o jsonpath='{.data.manifest\.yaml}' | yq r - 'spec.charts.(name==cray-s3).version')
    ncn-m001# echo $S3_VERSION
    ```

2. Create `s3-manifest.yaml`:

    ```bash
    ncn-m001# cat > s3-manifest.yaml << EOF
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

3. Merge `customizations.yaml` with `s3-manifest.yaml`:

    ```bash
    ncn-m001# manifestgen -c customizations.yaml -i ./s3-manifest.yaml > ./s3-manifest.out.yaml
    ```

4. Redeploy the S3 helm chart:

    ```bash
    ncn-m001# loftsman ship \
        --charts-repo https://packages.local/repository/charts \
        --manifest-path s3-manifest.out.yaml
    ```

5. Check that the new endpoint has been added.

    ```bash
    ncn-m001#  kubectl get endpoints -l app.kubernetes.io/instance=cray-s3 -n ceph-rgw
    ```

#### 1.4 Redeploy SYSMGMT_HEALTH to pick up any changes for storage node endpoints.

1. Determine the version of SYSMGMT_HEALTH:

    ```bash
    ncn-m001# SYSMGMT_VERSION=$(kubectl -n loftsman get cm loftsman-platform -o jsonpath='{.data.manifest\.yaml}' | yq r - 'spec.charts.(name==cray-sysmgmt-health).version')
    ncn-m001# echo $SYSMGMT_VERSION
    ```

2. Determine the current resources and retention settings:

    ```bash
    ncn-m001#  kubectl -n loftsman get cm loftsman-platform -o jsonpath='{.data.manifest\.yaml}' | yq r - 'spec.charts.(name==cray-sysmgmt-health).values.prometheus-operator.prometheus.prometheusSpec.resources'
    ```

    Example Output:

    ```
    limits:
      cpu: '6'
      memory: 30Gi
    requests:
      cpu: '2'
      memory: 15Gi
    ```

    ```bash
    ncn-m001#  kubectl -n loftsman get cm loftsman-platform -o jsonpath='{.data.manifest\.yaml}' | yq r - 'spec.charts.(name==cray-sysmgmt-health).values.prometheus-operator.prometheus.prometheusSpec.retention'
    ```

    Example Output:

    ```
    48h
    ```

3. Create `sysmgmt-health-manifest.yaml` and update the `resources` and `retention` sections as needed based up the data from the above step:

    ```bash
    ncn-m001# cat > sysmgmt-health-manifest.yaml << EOF
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

3. Merge `customizations.yaml` with `sysmgmt-health-manifest.yaml`:

    ```bash
    ncn-m001# manifestgen -c customizations.yaml -i ./sysmgmt-health-manifest.yaml > ./sysmgmt-health-manifest.out.yaml
    ```

4. Redeploy the SYSMGMT_HEALTH helm chart:

    ```bash
    ncn-m001# loftsman ship \
        --charts-repo https://packages.local/repository/charts \
        --manifest-path sysmgmt-health-manifest.out.yaml
    ```

5. Check that the new endpoint has been added.

    ```bash
    ncn-m001#  kubectl get endpoints -l app=cray-sysmgmt-health-ceph-exporter -n sysmgmt-health
    ncn-m001#  kubectl get endpoints -l app=cray-sysmgmt-health-ceph-node-exporter -n sysmgmt-health
    ```
