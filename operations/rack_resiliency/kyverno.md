# Distributing critical services across Kubernetes zones

One of the key ways to ensure CSM critical services availability is that the failure of nodes or a single rack is to spread the replicas of these services across multiple zones and racks. To support Kubernetes in spreading the replicas of the CSM critical services during startup, a new `kyverno` policy by name  `insert-labels-topology-constraints` has been added.

This policy applies to all the Deployments and StatefulSets that have been identified as critical services for Rack Resiliency.

## `Kyverno` cluster policy

Some of the CSM critical services already have established the pod affinities to spread the replicas across nodes. Because the nodes which are picked by the Kubernetes scheduler can be on the same rack, it is necessary to include a topology constraint for these services; this helps the Kubernetes scheduler distribute the replicas across zones. This is achieved using the feature with a new `kyverno` cluster policy with the name `insert-labels-topology-constraints` added.

For more information, see [Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/).

### 1. Policy details

Use the below command to view the policy and know the services for which the policy has been enabled:

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

### 2. How the `kyverno` policy works

The `Kyverno` policy works in four steps as described below:

#### 2.1 Restarting critical services

During Deployment of the Rack Resiliency Service, the critical services which are either Deployments or StatefulSets are restarted. During restart the policy is implemented by the `Kyverno` policy engine.

#### 2.2 Adding topology constraint

The policy engine updates the topology constraint to the Deployment/ StatefulSets specification of the critical service.

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
            
#### 2.3 Add a new label as a selector to identify the pods

During restart, the label mentioned in the policy is added to all the pods belonging to the specific critical service Deployment or StatefulSets that is being restarted.

For Example, for the StatefulSets `cray-bss-bitnami-etcd` the policy adds the `rrflag` as shown below:

```text
cray-bss-bitnami-etcd-0                     2/2     Running   0               4d12h   app.kubernetes.io/component=etcd,app.kubernetes.io/instance=cray-hms-bss,app.kubernetes.io/managed-by=Helm,app.kubernetes.io/name=cray-bss-bitnami-etcd,app.kubernetes.io/version=3.5.21,apps.kubernetes.io/pod-index=0,controller-revision-hash=cray-bss-bitnami-etcd-855488694f,helm.sh/chart=etcd-11.2.3,rrflag=rr-cray-bss-bitnami-etcd,security.istio.io/tlsMode=istio,service.istio.io/canonical-name=cray-bss-bitnami-etcd,service.istio.io/canonical-revision=3.5.21,statefulset.kubernetes.io/pod-name=cray-bss-bitnami-etcd-0
cray-bss-bitnami-etcd-1                     2/2     Running   0               4d12h   app.kubernetes.io/component=etcd,app.kubernetes.io/instance=cray-hms-bss,app.kubernetes.io/managed-by=Helm,app.kubernetes.io/name=cray-bss-bitnami-etcd,app.kubernetes.io/version=3.5.21,apps.kubernetes.io/pod-index=1,controller-revision-hash=cray-bss-bitnami-etcd-855488694f,helm.sh/chart=etcd-11.2.3,rrflag=rr-cray-bss-bitnami-etcd,security.istio.io/tlsMode=istio,service.istio.io/canonical-name=cray-bss-bitnami-etcd,service.istio.io/canonical-revision=3.5.21,statefulset.kubernetes.io/pod-name=cray-bss-bitnami-etcd-1
cray-bss-bitnami-etcd-2                     2/2     Running   0               4d12h   app.kubernetes.io/component=etcd,app.kubernetes.io/instance=cray-hms-bss,app.kubernetes.io/managed-by=Helm,app.kubernetes.io/name=cray-bss-bitnami-etcd,app.kubernetes.io/version=3.5.21,apps.kubernetes.io/pod-index=2,controller-revision-hash=cray-bss-bitnami-etcd-855488694f,helm.sh/chart=etcd-11.2.3,rrflag=rr-cray-bss-bitnami-etcd,security.istio.io/tlsMode=istio,service.istio.io/canonical-name=cray-bss-bitnami-etcd,service.istio.io/canonical-revision=3.5.21,statefulset.kubernetes.io/pod-name=cray-bss-bitnami-etcd-2
```

#### 2.4 Spreading pods across zones

When the scheduler launches the pod, using the selector `rrflag` the pods are spread across racks. During the failure of a NCN node or rack, when service replicas are restarted by Kubernetes, the policy helps the replicas being restarted to spread across zones.

**Note:** The policy has been enabled to allow running replicas on the same rack if other racks are not available because of a failure. This ensures that the number of replicas during a failure remains the same.
