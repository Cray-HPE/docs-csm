# Kyverno Policy

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
**Note:**
The **exclude** section of the policy shown in the above example is present when the policy is applied initially using Helm.
Later, if [Rack Resiliency is enabled](Enabling_Rack_Resiliency.md), the **exclude** section is patched and removed from the policy 
at the end of the Helm upgrade(using a post upgrade hook).

## How the policy works

### 1. Restart critical services

At the end of CSM upgrade from 1.6.x to 1.7.0, the critical services which are either Deployments or StatefulSets are restarted based on whether Rack Resiliency
is enabled and `Kyverno` policy is applied. During restart the policy is implemented by the Kyverno policy engine. 

During fresh install of CSM 1.7.0, at the end of [configure administrative access procedure](../../install/configure_administrative_access.md#configure-administrative-access), the critical services should be manually restarted using the [steps mentioned here] (../../install/configure_administrative_access.md#9-restart-rack-resiliency-critical-services). Similar to upgrade, the critical services are restarted only when Rack Resiliency is enabled and `Kyverno` policy is applied.

### 2. Add topology constraints

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

### 3. Add label

During restart, the label mentioned in the policy is added to all the pods belonging to the
specific critical service Deployment or StatefulSet that is being restarted.

For example, for the StatefulSet `cray-bss-bitnami-etcd`, the policy adds the `rrflag` as
shown below:

```text
cray-bss-bitnami-etcd-0                     2/2     Running   0               4d12h   app.kubernetes.io/component=etcd,app.kubernetes.io/instance=cray-hms-bss,app.kubernetes.io/managed-by=Helm,app.kubernetes.io/name=cray-bss-bitnami-etcd,app.kubernetes.io/version=3.5.21,apps.kubernetes.io/pod-index=0,controller-revision-hash=cray-bss-bitnami-etcd-855488694f,helm.sh/chart=etcd-11.2.3,rrflag=rr-cray-bss-bitnami-etcd,security.istio.io/tlsMode=istio,service.istio.io/canonical-name=cray-bss-bitnami-etcd,service.istio.io/canonical-revision=3.5.21,statefulset.kubernetes.io/pod-name=cray-bss-bitnami-etcd-0
cray-bss-bitnami-etcd-1                     2/2     Running   0               4d12h   app.kubernetes.io/component=etcd,app.kubernetes.io/instance=cray-hms-bss,app.kubernetes.io/managed-by=Helm,app.kubernetes.io/name=cray-bss-bitnami-etcd,app.kubernetes.io/version=3.5.21,apps.kubernetes.io/pod-index=1,controller-revision-hash=cray-bss-bitnami-etcd-855488694f,helm.sh/chart=etcd-11.2.3,rrflag=rr-cray-bss-bitnami-etcd,security.istio.io/tlsMode=istio,service.istio.io/canonical-name=cray-bss-bitnami-etcd,service.istio.io/canonical-revision=3.5.21,statefulset.kubernetes.io/pod-name=cray-bss-bitnami-etcd-1
cray-bss-bitnami-etcd-2                     2/2     Running   0               4d12h   app.kubernetes.io/component=etcd,app.kubernetes.io/instance=cray-hms-bss,app.kubernetes.io/managed-by=Helm,app.kubernetes.io/name=cray-bss-bitnami-etcd,app.kubernetes.io/version=3.5.21,apps.kubernetes.io/pod-index=2,controller-revision-hash=cray-bss-bitnami-etcd-855488694f,helm.sh/chart=etcd-11.2.3,rrflag=rr-cray-bss-bitnami-etcd,security.istio.io/tlsMode=istio,service.istio.io/canonical-name=cray-bss-bitnami-etcd,service.istio.io/canonical-revision=3.5.21,statefulset.kubernetes.io/pod-name=cray-bss-bitnami-etcd-2
```

### 4. Spreading pods across zones

When the scheduler launches the pod, using the selector `rrflag` the pods are spread across
racks. During the failure of a NCN node or rack, when service replicas are restarted by Kubernetes,
the policy helps the replicas being restarted to spread across zones.

**Note:** The policy has been enabled to allow running replicas on the same rack if other racks
are not available because of a failure. This ensures that the number of replicas during a failure
remains the same.
