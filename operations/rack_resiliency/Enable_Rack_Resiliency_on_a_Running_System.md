# Enable Rack Resiliency on a Running System

Rack Resiliency can be enabled and configured on a system running CSM 1.7+.
For details on doing this during an install or upgrade to CSM 1.7, see
[Enable Rack Resiliency During Install or Upgrade](Enable_Rack_Resiliency_During_Install_or_Upgrade.md).

1. [Enable and customize](1-enable-and-customize)
1. [Run Ansible plays](#2-run-ansible-plays)
1. [Deploy Helm chart](#3-deploy-helm-chart)
1. [Restart critical services](#4-restart-critical-services)

## 1. Enable and customize

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

1. (`ncn-mw#`) Enable the feature in `customizations.yaml`.

    ```bash
    yq write -i "${TMPDIR}/customizations.yaml" \
        'spec.kubernetes.services.rack-resiliency.enabled' "true"
    ```

1. (`ncn-mw#`) Optionally, set custom zone name prefixes.

    See [Zone names](Zones.md#zone-names) for details
    on reasons for doing this and restrictions on names. This is optional; prefixes are not
    required. However, **prefixes cannot be changed, set, or removed later**.

    1. Optionally, set a site-specific [Kubernetes zone](Zones.md#kubernetes-zones) prefix.

        > In the following command, replace `k8s-prefix-string` with the desired Kubernetes zone prefix.

        ```bash
        yq write -i "${TMPDIR}/customizations.yaml" \
            'spec.kubernetes.services.rack-resiliency.k8s_zone_prefix' "k8s-prefix-string"
        ```

    1. Optionally, set a site-specific [Ceph zone](Zones.md#ceph-zones) prefix.

        > In the following command, replace `ceph-prefix-string` with the desired Ceph zone prefix.

        ```bash
        yq write -i "${TMPDIR}/customizations.yaml" \
            'spec.kubernetes.services.rack-resiliency.ceph_zone_prefix' "ceph-prefix-string"
        ```

1. (`ncn-mw#`) Update the `site-init` secret in the Kubernetes cluster.

    ```bash
    kubectl delete secret -n loftsman site-init \
        && kubectl create secret -n loftsman generic site-init \
            --from-file="${TMPDIR}/customizations.yaml"
    ```

    Expected output:

    ```text
    secret/site-init created
    ```

1. (`ncn-mw#`) Confirm that the fields are set to the desired values.

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

## 2. Run Ansible plays

Refer to [setup flows](Setup_of_Rack_Resiliency.md#setup-flows) for information on Ansible Roles to setup rack resiliency. Follow the below procedure to deploy the RR Ansible plays post install or upgrade of CSM 1.7.0:

### Deploying Kubernetes setup flow

For Kubernetes zoning, select a master node to personalize.

(`ncn-m#`) Get the xname of the selected master node.

**For Example:**

```bash
XNAME=$( ssh ncn-m001 cat /etc/cray/xname )
```

Now continue with the [steps for Rack Resiliency setup](#steps-for-rack-resiliency-setup)

### Deploying Ceph setup flow

For Ceph zoning, select a storage node to personalize.

(`ncn-m#`) Get the xname of the selected storage node.

**For Example:**

```bash
XNAME=$( ssh ncn-s001 cat /etc/cray/xname )
```

Now continue with the [steps for Rack Resiliency setup](#steps-for-rack-resiliency-setup)

### Steps for Rack Resiliency setup

1. (`ncn-m#`) Get the name of latest config applied on the cluster

    ```bash
    CONFIG=$( cray cfs components describe $XNAME --format json | jq -r '.desiredConfig' )
    ```

1. (`ncn-m#`) Get the latest config applied on the cluster

    ```bash
    cray cfs configurations describe $CONFIG --format json | jq -r '. | del(.name) | del(.lastUpdated)' > ${CONFIG}.json
    ```

1. (`ncn-m#`) Check if the rack resiliency playbook is present in the configuration

    ```bash
    cat ${CONFIG}.json | grep rack_resiliency_for_mgmt_nodes.yml
    ```

    Example Output:

    ```text
    "playbook": "rack_resiliency_for_mgmt_nodes.yml"
    ```

    **NOTE:** If the above command returns the output shown above, then 
    skip to the next step (Perform the component update). Otherwise, perform
    the following sub-steps to add the rack resiliency layer.

    1. (`ncn-m#`) Get the corresponding `csm-config` branch (@VCS) from the product catalog for CSM 1.7.0 version.

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

    1. Edit `${CONFIG}.json` by adding a new layer with commit ID found in the previous step.

        Add the following layer in the `{CONFIG}.json` file. Be sure to substitute the actual
        commit ID found in the previous step. Leave all other fields as they are shown here.

        ```json
        {
          "layers": [
            {
              "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
              "commit": "commit_id_goes_here",
              "name": "csm-ncn-rack-resiliency",
              "playbook": "rack_resiliency_for_mgmt_nodes.yml"
            },
          ]
        }
        ```

    1. (`ncn-m#`) Update the configuration in CFS.

        ```bash
        cray cfs configurations update --file ${CONFIG}.json ${CONFIG}
        ```

1. (`ncn-m#`) Perform the component update.

```bash
cray cfs components update $XNAME --state []
```

1. (`ncn-m#`) Wait for the component to be configured.

    Wait until the configuration status of the component changes to `configured`.

    ```bash
    cray cfs components describe $XNAME
    ```

    In case of configuration failure, see
    [Troubleshoot CFS Issues](../configuration_management/Troubleshoot_CFS_Issues.md).

## 3. Deploy Helm chart

Deploy [`cray-rrs`](cray-rrs_Deployment.md) in `rack-resiliency` namespace using the following procedure:

1. (`ncn-mw#`) Get current CSM installation location.

    ```bash
    . /etc/cray/upgrade/csm/myenv
    echo $CSM_ARTI_DIR
    ```

    Example output:

    ```text
    /etc/cray/upgrade/csm/test-activity/2148565/media/csm-1.7.0-rc.2
    ```

1. (`ncn-mw#`) Install the helm chart on the cluster.

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

    Post installation of `cray-rrs` helm chart, verify all Rack Resiliency related objects using the below commands:

1. (`ncn-mw#`) To check the resources in `rack-resiliency` namespace use:

    ```bash
    kubectl get all -n rack-resiliency
    ```

    Example output:

    ```text
    NAME                            READY   STATUS     RESTARTS   AGE
    pod/cray-rrs-86d4465c9d-qf6f5   0/2     Init:0/2   0          19h

    NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)           AGE
    service/cray-rrs   ClusterIP   10.18.164.23   <none>        80/TCP,8551/TCP   19h

    NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/cray-rrs   0/1     0            0           19h

    NAME                                  DESIRED   CURRENT   READY   AGE
    replicaset.apps/cray-rrs-86d4465c9d   1         0         0       19h
    ```

1. (`ncn-mw#`) Check the `clusterpolicy`.

    ```bash
    kubectl get clusterpolicy
    ```

    Example output:

    ```text
    NAME                                 ADMISSION   BACKGROUND   READY   AGE   MESSAGE
    check-image                          true        true         True    39d   Ready
    cluster-job-ttl                      true        true         True    39d   Ready
    insert-labels-topology-constraints   true        true         True    19h   Ready
    podsecurity-subrule-baseline         true        true         True    39d   Ready
    prepend-registry                     true        true         True    39d   Ready
    ```

**Note** : Ensure that the `clusterpolicy` `insert-labels-topology-constraints` is in `Ready` state.

## 4. Restart critical services

Perform rollout restart of the critical services using the [script](../../upgrade/scripts/k8s/rr_critical_service_restart.py).
