# Enable Rack Resiliency on a Running System

## Overview

* Rack Resiliency **should not** be used in a production environment. For more details, see
  [Rack Resiliency is experimental](README.md#attention-rr-is-experimental).
* By default, Rack Resiliency is disabled.
* This page documents the procedures for enabling and configuring Rack Resiliency on a Running system.
* Rack Resiliency cannot be disabled after it has been enabled during the install or upgrade.

Rack Resiliency can be enabled and configured on a system running CSM 1.7+.
> Note: For details on doing this during an install or upgrade to CSM 1.7, see
[Enable Rack Resiliency During Install or Upgrade](Enabling_RR_During_Install_or_Upgrade.md).

1. [Enable and customize](#1-enable-and-customize)
1. [Run Ansible plays](#2-run-ansible-plays)
1. [Check the Helm chart](#3-check-the-cray-rrs-helm-chart)
1. [Restart critical services](#4-restart-critical-services)
1. [Verify the status of `cray-rrs` deployment](#5-verify-the-status-of-cray-rrs-deployment)

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

Refer to [setup flows](Setup_of_Rack_Resiliency.md#setup-flows) for information on Ansible Roles to setup rack resiliency.
Follow the below procedure to deploy the RR Ansible plays post install or upgrade of CSM:

Since Rack Resiliency was disabled earlier and has just been enabled in the previous step,
the next step is to configure CFS to rerun the Ansible plays for Rack Resiliency. This is done using the script
[`refresh_master_storage_rack_resiliency_config.py`](../../scripts/operations/configuration/refresh_master_storage_rack_resiliency_config.py).
This script applies the necessary configuration and sets up Kubernetes and Ceph [zones](Zones.md)
on Master and Storage nodes, respectively.

(`ncn-mw#`) Example usage:

```bash
/usr/share/doc/csm/scripts/operations/configuration/refresh_master_storage_rack_resiliency_config.py
```

Example output:

```text
Checking if any Master NCN has the Rack Resiliency playbook layer...
✔ 3 Master NCN(s) have the Rack Resiliency playbook layer.
✔ 3 Storage NCN(s) have the Rack Resiliency playbook layer.

=== Processing Master NCNs ===
Updating 3 master CFS components...
✔ Master NCNs successfully updated.


=== Processing Storage NCNs ===
Updating 3 storage CFS components...
✔ Storage NCNs successfully updated.

All updates completed successfully. CFS batcher should soon reconfigure these NCNs.
SUCCESS
```

## 3. Check the `cray-rrs` Helm chart

The `cray-rrs` Helm chart should already be installed in the `rack-resiliency` namespace.
Verify that the `cray-rrs` Helm chart is present in `rack-resiliency` namespace using the following procedure:

1. (`ncn-mw#`) List the Helm charts.

    ```bash
    helm ls -n rack-resiliency
    ```

    Example output:

    ```text
    NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
    cray-rrs        rack-resiliency 1               2025-09-26 21:43:12.5031915 +0000 UTC   deployed        cray-rrs-1.1.0  1.1.0      
    ```

1. (`ncn-mw#`) List the resources in the `rack-resiliency` namespace.

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

    > Refer to [`cray rrs pod is in init state`](Troubleshooting.md#cray-rrs-pod-is-in-init-state) to understand why the `cray-rrs` deployment is not in `Ready` state.

1. (`ncn-mw#`) Check the `clusterpolicy`.

    ```bash
    kubectl get clusterpolicy insert-labels-topology-constraints
    ```

    Example output:

    ```text
    NAME                                 ADMISSION   BACKGROUND   READY   AGE   MESSAGE
    insert-labels-topology-constraints   true        true         True    19h   Ready
    ```

    Ensure that the `clusterpolicy` `insert-labels-topology-constraints` is in `Ready` state.

## 4. Restart critical services

Perform rollout restart of the critical services using the script [`rr_critical_service_restart.py`](../../upgrade/scripts/k8s/rr_critical_service_restart.py).

Example usage:

```bash
python /usr/share/doc/csm/upgrade/scripts/k8s/rr_critical_service_restart.py
```

Example Output:

```text
Restarted deployment/cilium-operator in namespace kube-system
Restarted deployment/coredns in namespace kube-system
Skipping deployment/cray-activemq-artemis-operator-controller-manager: 'rrflag' label is already set in namespace dvs
Skipping deployment/cray-capmc: 'rrflag' label is already set in namespace services
Skipping deployment/cray-ceph-csi-cephfs-provisioner: 'rrflag' label is already set in namespace ceph-cephfs
Skipping deployment/cray-ceph-csi-rbd-provisioner: 'rrflag' label is already set in namespace ceph-rbd
Skipping deployment/cray-certmanager-cert-manager: 'rrflag' label is already set in namespace cert-manager
Skipping deployment/cray-certmanager-cert-manager-cainjector: 'rrflag' label is already set in namespace cert-manager
...
Skipping deployment/slurmdbd-backup: 'rrflag' label is already set in namespace user
Skipping deployment/sshot-net-operator: 'rrflag' label is already set in namespace sshot-net-operator
RR critical services rollout restart successful.
configmap/rrs-mon-dynamic patched (no change)
Set rollout_complete=true in ConfigMap 'rrs-mon-dynamic'
Done!
```

## 5. Verify the status of `cray-rrs` deployment

(`ncn-mw#`) List the resources in the `rack-resiliency` namespace:

```bash
kubectl get all -n rack-resiliency
```

Example output:

```text
NAME                            READY   STATUS     RESTARTS   AGE
pod/cray-rrs-86d4465c9d-qf6f5   2/2     Ready      0          19h

NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)           AGE
service/cray-rrs   ClusterIP   10.18.164.23   <none>        80/TCP,8551/TCP   19h

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/cray-rrs   1/1     1            1           19h

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/cray-rrs-86d4465c9d   1         1         1       19h
```

The pod should have have status `Ready`. The pod should show `2/2` in the `READY` column, and the deployment should show `1/1` in the `READY` column.
