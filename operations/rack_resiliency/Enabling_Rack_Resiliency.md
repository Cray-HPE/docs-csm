# Enable and setup Rack Resiliency

## 1. Enabling Rack Resiliency

By default the Rack Resiliency feature is disabled. Administrators wishing to use this feature must enable it before the **Management Node Rollout**
step in [upgrade CSM and additional products with IUF](../iuf/workflows/upgrade_csm_and_additional_products_with_iuf.md).

Use the following procedure to enable Rack Resiliency.

### Procedure

Update and apply the `customizations.yaml` file before commencing the CSM installation or upgrade.

#### Get customization `yaml` file

```bash
kubectl -n loftsman get secret site-init -o json | jq -r '.data."customizations.yaml"' | base64 -d > /tmp/customizations.yaml
```

#### Update customization `yaml` file

Update the `spec.services.rack-resiliency.enabled` flag from `false` to `true` in the `/tmp/customizations.yaml` file.

```bash
vi /tmp/customizations.yaml
```

```bash
CUSTOMIZATIONS="$(base64 < "/tmp/customizations.yaml" | tr -d '\n')"
```

```bash
kubectl get secrets -n loftsman site-init -o json \
>     | jq ".data.\"customizations.yaml\" |= \"$CUSTOMIZATIONS\"" | kubectl apply -f -
```

Example output:

```text
secret/site-init configured
```

<b>NOTE</b>: Rack Resiliency `enabled` flag should be set to `true` for enblement to work, if it set to any other value like '1' or 'yes' it will be considered as `false`.

## 2. To define the Kubernetes and Ceph zone prefixes

An administrator can specify the prefixes for the Kubernetes and Ceph zones to be created before management node rollout mentioned in [upgrade CSM and additional products with IUF](../iuf/workflows/upgrade_csm_and_additional_products_with_iuf.md)

These prefixes will be added to the Kubernetes and Ceph zone labels accordingly and will help admins to create and visualize each racks 
as a separate zone with their own specified labels.

**`NOTE`**  The prefix can be limited to 1-1000 characters long (but no restrictions on the type of characters)
 
Use the following procedure to specify zone prefixes:

### Procedure

Update the `customizations.yaml` file before commencing the CSM installation or upgrade.

#### Kubernetes zone prefix update

Update the `spec.services.k8s_zone_prefix` section in the `customizations.yaml` file with the required Kubernetes zone prefix.

Follow similar steps to [Enabling Rack Resiliency feature](#1-enabling-rack-resiliency-feature) in order to update and apply above customization changes.

#### Ceph zone prefix update

Update the `spec.services.Ceph_zone_prefix` section in the `customizations.yaml` file with the required Ceph zone prefix.

Follow similar steps to [Enabling Rack Resiliency feature](#1-enabling-rack-resiliency-feature) in order to update and apply above customization changes.

**Important Notes:**

* If the prefixes is defined, then the zones will be created in the format of `k8s_zone_prefix + rack_id` and `ceph_zone_prefix + rack_id`.
    * If the `spec.services.k8s_zone_prefix` has a value of `test-system` and the rack-id is `x3000`, then the Kubernetes zones will be created with the labels of value `test-system-x3000`.
    * If the `spec.services.ceph_zone_prefix` has a value of `test-storage-system` and the rack-id is `x3000`, then the Ceph zones will be created with the labels of value `test-storage-system-x3000`.
* If the `spec.services.k8s_zone_prefix` has no value defined and the rack-id is `x3000`, then the Kubernetes zones will be created with the labels of value `x3000`.
* If the `spec.services.ceph_zone_prefix` has no value defined and the rack-id is `x3000`, then the Ceph zones will be created with the labels of value `x3000`.

## 3. Setup/ configure Rack Resiliency

The RR solution includes Ansible plays for use by the [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs).
These plays are deployed as part of the [`update_cfs_config` stage](../iuf/stages/update_cfs_config.md)
using the [Install and Upgrade Framework (IUF)](../../glossary.md#install-and-upgrade-framework-iuf).
It is initiated during [`management_nodes_rollout` stage](../iuf/stages/management_nodes_rollout.md) of IUF in order to enable/configure RR with:
* management nodes placement discovery
* management nodes placement validation
* zoning (Kubernetes zoning for master and worker nodes and Ceph zoning for Utility storage nodes)
* applying `kyverno` policy to critical services and rollout restart of these critical services

If placement validation criteria is met as explained in [Validate distribution of management nodes](management_plane_discovery_and_validation.md#2-validate-distribution-of-management-nodes), then RR Ansible plays will configure RR zones (Kubernetes and Ceph) and apply the `kyverno` policy; Otherwise, the Ansible plays will fail with a placement validation error message.

## 4. Deployment of RRS Helm chart for monitoring

The RRS (Rack Resiliency Service) Helm chart includes both the RRS and the RMS (Resiliency Monitoring Service).
The chart will be deployed automatically during the CSM install or upgrade process, provided that
RR is enabled and both the Kubernetes and Ceph zones exist. Otherwise, the chart will not be deployed.
Specifically, the chart will not be deployed in the following cases:
* RR is disabled



