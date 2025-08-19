# Setup Rack Resiliency Post Install/Upgrade

## Step 1: Rack Resiliency Enablement

Follow these steps to enable (and optionally customize) Rack Resiliency.

1. (`ncn-mw#`) Retrieve the `customizations.yaml` file.

    ```bash
    TMPDIR=$(mktemp -d -p ~) &&
    kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' \
        | base64 -d > "${TMPDIR}/customizations.yaml" \
        && echo "${TMPDIR}/customizations.yaml"
    ```

    Example output:

    ```text
    /root/tmp.iM4FrDrJEJ/customizations.yaml
    ```

2. (`ncn-mw#`) Enable the feature in `customizations.yaml`.

    ```bash
    yq write -i "${TMPDIR}/customizations.yaml" \
        'spec.kubernetes.services.rack-resiliency.enabled' "true"
    ```

3. (`ncn-mw#`) Optionally, set custom zone name prefixes.

    See [Zone names](../../rack_resiliency/Zones.md#zone-names) for details
    on reasons for doing this and restrictions on names. This is optional; prefixes are not
    required. However, **prefixes cannot be changed, set, or removed later**.

    1. Optionally, set a site-specific [Kubernetes zone](../../rack_resiliency/Zones.md#kubernetes-zones) prefix.

        > In the following command, replace `k8s-prefix-string` with the desired Kubernetes zone prefix.

        ```bash
        yq write -i "${TMPDIR}/customizations.yaml" \
            'spec.kubernetes.services.rack-resiliency.k8s_zone_prefix' "k8s-prefix-string"
        ```

    2. Optionally, set a site-specific [Ceph zone](../../rack_resiliency/Zones.md#ceph-zones) prefix.

        > In the following command, replace `ceph-prefix-string` with the desired Ceph zone prefix.

        ```bash
        yq write -i "${TMPDIR}/customizations.yaml" \
            'spec.kubernetes.services.rack-resiliency.ceph_zone_prefix' "ceph-prefix-string"
        ```

4. (`ncn-mw#`) Update the `site-init` secret in the Kubernetes cluster.

    ```bash
    kubectl delete secret -n loftsman site-init \
        && kubectl create secret -n loftsman generic site-init \
            --from-file="${TMPDIR}/customizations.yaml"
    ```

    Expected output:

    ```text
    secret/site-init created
    ```

5. (`ncn-mw#`) Confirm that the fields are set to the desired values.

    ```bash
    kubectl get secrets -n loftsman site-init \
        -o jsonpath='{.data.customizations\.yaml}' \
        | base64 -d | yq r - 'spec.kubernetes.services.rack-resiliency'
    ```

    Example output (in a case where only the Ceph zone prefix was set):

    ```yaml
    enabled: true
    ceph_zone_prefix: my-ceph-prefix
    ```

## Step 2: Deploy Rack Resiliency CFS ansible plays

### Setup flows

Refer to [setup flows](Setup_of_Rack_Resiliency.md#setup-flows) for information on Ansible Roles to setup rack resiliency. Since the ansible roles for setting up Kubernetes and Ceph [zones](Zones.md) have to be applied post install or upgrade, the below procedure has to be followed:

### Checking the latest Rack Resiliency ansible plays in gitea

1. (`ncn#`) Log into VCS and clone `csm-config-management.git` @ VCS.

```bash
VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_username}} | base64 --decode)
VCS_PASS=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
git clone "https://${VCS_USER}:${VCS_PASS}@api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
```

2. Navigate to `csm-config-management`

```bash
cd csm-config-management
```

3. The `rack_resiliency_for_mgmt_nodes.yml` file present inside the `csm-config-management` directory is the playbook for setting up Kubernetes and Ceph zones. This playbook also performs the [common preparation flow](Setup_of_Rack_Resiliency.md#common-preparation-flow) before setting up the zones.

### Deploying Kubernetes Ansible flow

For Kubernetes zoning, select a master node to personalize

(`ncn-m#`) Get the xname of the selected master node.

**For Example:**

```bash
XNAME=$( ssh ncn-m001 cat /etc/cray/xname )
```

Now continue with the [steps for Rack Resiliency setup](#steps-for-rack-resiliency-setup)

### Deploying Ceph Ansible flow

For Ceph zoning, select a storage node to personalize.

(`ncn-m#`) Get the xname of the selected storage node.

**For Example:**

```bash
XNAME=$( ssh ncn-s001 cat /etc/cray/xname )
```

Now continue with the [steps for Rack Resiliency setup](#steps-for-rack-resiliency-setup)

### Steps for Rack Resiliency setup

#### 1. (`ncn-m#`) Get the name of latest config applied on the cluster.

```bash
CONFIG=$( cray cfs components describe $XNAME --format json | jq -r '.desiredConfig' )
```

#### 2. (`ncn-m#`) Get the latest config applied on the cluster.

```bash
cray cfs configurations describe $CONFIG --format json | jq -r '. | del(.name) | del(.lastUpdated)' > ${CONFIG}.json
```

#### 3. (`ncn-m#`) Check if the rack resiliency playbook is present in the configuration.

```bash
cat ${CONFIG}.json | grep rack_resiliency_for_mgmt_nodes.yml
```

Example Output:

```text
"playbook": "rack_resiliency_for_mgmt_nodes.yml"
```

**NOTE:** If the above command returns the output shown above, then go to [step 4](#4-ncn-m-perform-the-component-update), else add the rack resiliency layer using the procedure below:

3.1. (`ncn-m#`) Get the corresponding `csm-config` branch (@VCS) from the product catalog for CSM 1.7.0 version.

```bash
kubectl get cm -n services cray-product-catalog -o yaml | yq - r 'data.csm' | grep ^1.7.0 -A 10
```

Example output:

```yaml
1.7.0:
  configuration:
    clone_url: https://vcs.cmn.odin.hpc.amslabs.hpecorp.net/vcs/cray/csm-config-management.git
    commit: 9c30b68a29878996761f3c8280d6e57dfb79e8c8
    import_branch: cray/csm/1.43.0
    import_date: 2025-07-28 15:51:40.054187
    ssh_url: git@vcs.cmn.odin.hpc.amslabs.hpecorp.net:cray/csm-config-management.git
```

3.2. (`ncn-m#`) Edit the config file by adding a new layer with latest commit id retrieved in step 3.1.

```bash
vim ${CONFIG}.json
```

- Add the below layer in `{CONFIG}.json` file

```json
{
  "layers": [
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
      "commit": "9c30b68a29878996761f3c8280d6e57dfb79e8c8",
      "name": "csm-ncn-rack-resiliency",
      "playbook": "rack_resiliency_for_mgmt_nodes.yml"
    }
  ]
}
```

**NOTE**:
* `commit`: replace the commit id in step 3.2 with the commit id fetched from step 3.1.
* `name`, `cloneurl` and `playbook` can be left as it is.

3.3. (`ncn-m#`) Update the config

```bash
cray cfs configurations update --file ${CONFIG}.json ${CONFIG}
```

#### 4. (`ncn-m#`) Perform the component update.

```bash
cray cfs components update $XNAME --state []
```

#### 5. (`ncn-m#`) Wait till configuration status of the component changes to configured.
```bash
cray cfs components describe $XNAME
```

In case of failure refer to [CFS troubleshooting guide](../configuration_management/Troubleshoot_CFS_Issues.md).

## Step 3: Deploy `cray-rrs` helm chart

The chart is deployed in the `rack-resiliency` namespace using the following procedure:

1. (`ncn-mw#`) Get current CSM installation location

```bash
. /etc/cray/upgrade/csm/myenv
echo $CSM_ARTI_DIR
```

Example output:

```text
/etc/cray/upgrade/csm/test-activity/2148565/media/csm-1.7.0-rc.2
```

3. (`ncn-mw#`) Install the helm chart on the cluster.

```bash
helm upgrade --install -n rack-resiliency cray-rrs $CSM_ARTI_DIR/helm/cray-rrs-1.1.0.tgz
```

Example output:
```text
NAME: cray-rrs
LAST DEPLOYED: Tue Aug 19 03:31:34 2025
NAMESPACE: rack-resiliency
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Installation info for chart cray-rrs:
```

- Post installation of `cray-rrs` helm chart, verify all Rack Resiliency related objects using the below commands:

1. (`ncn-mw#`) To check the resources in `rack-resiliency` namespace use:

```bash
kubectl get all -n rack-resiliency
```

Example output:

```text
ncn-m001:~ # kubectl get all -n rack-resiliency 
NAME                            READY   STATUS     RESTARTS   AGE
pod/cray-rrs-86d4465c9d-qf6f5   2/2     Running   0          19h

NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)           AGE
service/cray-rrs   ClusterIP   10.18.164.23   <none>        80/TCP,8551/TCP   19h

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/cray-rrs   1/1     1            1           19h

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/cray-rrs-86d4465c9d   1         1         1       19h
```

2. (`ncn-mw#`) Check the `clusterpolicy`

```bash
kubectl get clusterpolicy
```

Example Output:

```text
ncn-m001:~ # kubectl get clusterpolicy
NAME                                 ADMISSION   BACKGROUND   READY   AGE   MESSAGE
check-image                          true        true         True    39d   Ready
cluster-job-ttl                      true        true         True    39d   Ready
insert-labels-topology-constraints   true        true         True    19h   Ready
podsecurity-subrule-baseline         true        true         True    39d   Ready
prepend-registry                     true        true         True    39d   Ready
```

**Note** : Ensure that the clusterpolicy `insert-labels-topology-constraints` is in `Ready` state.


## Step 4: Perform a rollout restart of critical services

Perform rollout restart of the critical services using the [script](../../upgrade/scripts/k8s/rr_critical_service_restart.py)
