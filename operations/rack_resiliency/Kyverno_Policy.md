# Kyverno Policy

* [Overview](#overview)
* [Policy details](#policy-details)
* [Restart critical services](#restart-critical-services)
    * [Upgrade from CSM 1.6 to CSM 1.7](#upgrade-from-csm-16-to-csm-17)
    * [Fresh install of CSM 1.7](#fresh-install-of-csm-17)
    * [Modifying critical services](#modifying-critical-services)
* [Add topology constraints](#add-topology-constraints)
* [Add label](#add-label)
* [Spreading pods across zones](#spreading-pods-across-zones)

## Overview

One of the key ways to ensure CSM critical services availability is that the failure of nodes or a
single rack is to spread the replicas of these services across multiple zones and racks.

Some of the CSM critical services already have established the pod affinities to spread the replicas
across nodes. Because the nodes which are picked by the Kubernetes scheduler can be on the same rack,
it is necessary to include a topology constraint for these services; this helps the Kubernetes
scheduler distribute the replicas across zones. This is achieved using the Kubernetes feature "Topology Spread Constraints" within a new Kyverno
cluster policy with the name `insert-labels-topology-constraints` added.

This policy applies to all the Deployments and StatefulSets that have been identified as critical
services for Rack Resiliency.

For more information on Kubernetes topology spread constraints, see
[Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/).

## Policy details

(`ncn-mw#`) View the policy and see the services for which the policy has been enabled.

```bash
kubectl get clusterpolicy insert-labels-topology-constraints -o yaml
```

Example output:

```yaml
kind: ClusterPolicy
metadata:
  annotations:
  ...
spec:
  admission: true
  background: true
  emitWarning: false
  rules:
  - match:
      any:
      - resources:
          kinds:
          - Deployment
          - StatefulSet
          names:
          - cray-dns-powerdns
          - coredns
          - sealed-secrets
          - cray-ceph-csi-cephfs-provisioner
          - cray-ceph-csi-rbd-provisioner
          - cray-activemq-artemis-operator-controller-manager
          - cray-dvs-mqtt-ss
          - cray-hmnfd-bitnami-etcd
          ...
    exclude: # Temporarily exclude resources in all namespaces
      any:
      - resources:
          namespaces:
          - "*"
    mutate:
      patchStrategicMerge:
        spec:
          template:
            metadata:
              labels:
                rrflag: rr-{{ request.object.metadata.name }}
            spec:
              +(topologySpreadConstraints):
              - labelSelector:
                  matchLabels:
                    rrflag: rr-{{ request.object.metadata.name }}
                maxSkew: 1
                topologyKey: topology.kubernetes.io/zone
                whenUnsatisfiable: ScheduleAnyway
    name: insert-rack-res-label
    skipBackgroundRequests: true
  validationFailureAction: Audit
  ...
```

**Note:** The `exclude` section of the policy shown in the above example is present when the policy is applied initially using Helm.
If [Rack Resiliency is enabled](Enabling_Rack_Resiliency.md), then the `exclude` section is removed from the policy(using a post-install/post-upgrade hook).

## Restart critical services

The Kyverno policy is applied to each service the first time that service restarts,
after the Kyverno policy is in effect for that service. There are specific times when
these restarts are expected to happen.

### Upgrade from CSM 1.6 to CSM 1.7

At the end of CSM upgrade from 1.6 to 1.7, the critical services (which are either Deployments or StatefulSets) are restarted only if Rack Resiliency
is enabled and the Kyverno policy is applied.

### Fresh install of CSM 1.7

During a fresh install of CSM 1.7, as part of
[Configure Administrative Access](../../install/configure_administrative_access.md#configure-administrative-access),
the critical services are restarted in the
[Restart Rack Resiliency critical services](../../install/configure_administrative_access.md#10-restart-rack-resiliency-critical-services)
step. The critical services are restarted only when Rack Resiliency is enabled and the Kyverno policy is applied.

### Modifying critical services

Administrators are able to modify the Rack Resiliency critical services.  If an administrator does nothing but remove critical
services, then no service restarts are necessary. However, if any critical service is added or modified, then a
service restart is performed as part of that procedure.

For more detailed information, see [Manage Critical Services](Manage_Critical_Services.md).

## Add topology constraints

The policy engine updates the topology constraint to the Deployment or StatefulSet
specifications of the critical services.

```yaml
spec:
    +(topologySpreadConstraints):
        - labelSelector:
              matchLabels:
                  rrflag: rr-{{ request.object.metadata.name }}
          maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: ScheduleAnyway
```

## Add label

During restart, the label mentioned in the policy is added to all the pods belonging to the
specific critical service Deployment or StatefulSet that is being restarted.

For example, for the StatefulSet `cray-bss-bitnami-etcd`, the policy adds the `rrflag` as
shown below:

```text
cray-bss-bitnami-etcd-0                     2/2     Running   0               4d12h   app.kubernetes.io/component=etcd,app.kubernetes.io/instance=cray-hms-bss,app.kubernetes.io/managed-by=Helm,app.kubernetes.io/name=cray-bss-bitnami-etcd,app.kubernetes.io/version=3.5.21,apps.kubernetes.io/pod-index=0,controller-revision-hash=cray-bss-bitnami-etcd-855488694f,helm.sh/chart=etcd-11.2.3,rrflag=rr-cray-bss-bitnami-etcd,security.istio.io/tlsMode=istio,service.istio.io/canonical-name=cray-bss-bitnami-etcd,service.istio.io/canonical-revision=3.5.21,statefulset.kubernetes.io/pod-name=cray-bss-bitnami-etcd-0
cray-bss-bitnami-etcd-1                     2/2     Running   0               4d12h   app.kubernetes.io/component=etcd,app.kubernetes.io/instance=cray-hms-bss,app.kubernetes.io/managed-by=Helm,app.kubernetes.io/name=cray-bss-bitnami-etcd,app.kubernetes.io/version=3.5.21,apps.kubernetes.io/pod-index=1,controller-revision-hash=cray-bss-bitnami-etcd-855488694f,helm.sh/chart=etcd-11.2.3,rrflag=rr-cray-bss-bitnami-etcd,security.istio.io/tlsMode=istio,service.istio.io/canonical-name=cray-bss-bitnami-etcd,service.istio.io/canonical-revision=3.5.21,statefulset.kubernetes.io/pod-name=cray-bss-bitnami-etcd-1
cray-bss-bitnami-etcd-2                     2/2     Running   0               4d12h   app.kubernetes.io/component=etcd,app.kubernetes.io/instance=cray-hms-bss,app.kubernetes.io/managed-by=Helm,app.kubernetes.io/name=cray-bss-bitnami-etcd,app.kubernetes.io/version=3.5.21,apps.kubernetes.io/pod-index=2,controller-revision-hash=cray-bss-bitnami-etcd-855488694f,helm.sh/chart=etcd-11.2.3,rrflag=rr-cray-bss-bitnami-etcd,security.istio.io/tlsMode=istio,service.istio.io/canonical-name=cray-bss-bitnami-etcd,service.istio.io/canonical-revision=3.5.21,statefulset.kubernetes.io/pod-name=cray-bss-bitnami-etcd-2
```

## Spreading pods across zones

When the scheduler launches the pod, using the selector `rrflag` the pods are spread across
racks. During the failure of a NCN node or rack, when service replicas are restarted by Kubernetes,
the policy helps the replicas being restarted to spread across zones.

**Note:** The policy has been enabled to allow running replicas on the same rack if other racks
are not available because of a failure. This ensures that the number of replicas during a failure
remains the same.
