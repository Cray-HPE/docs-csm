# Enabling Rack Resiliency

As mentioned in the [Architecture Overview](README.md#architecture-overview), enabling Rack Resiliency is first stage for setting up rack resiliency. By default the Rack Resiliency feature is disabled. Based on whether CSM is getting freshly installed or upgraded to a new version, use the below steps to enable rack resiliency.

## Case 1: Fresh install

Follow the steps mentioned in this [Prepare Site Init](../../install/prepare_site_init.md#enable-rack-resiliency) to enable rack resiliency and add the prefixes for Kubernetes and ceph zones.

## Case 2: Upgrade

To enable rack resiliency during upgrade with iuf, use the procedure below, before the **Management Node Rollout**
stage of [CSM upgrade](../iuf/workflows/management_rollout.md).

### Steps to enable rack resiliency and add zone prefixes

#### Retrieve the `customizations.yaml` file

```bash
kubectl -n loftsman get secret site-init -o json | jq -r '.data."customizations.yaml"' | base64 -d > /tmp/customizations.yaml
```

##### Update the `customizations.yaml` file

```bash
vi /tmp/customizations.yaml
```

**`NOTE`**  
- Adding zone prefixes is optional. No prefixes are added by default.
- The prefix can be limited to 1-1000 characters long (but no restrictions on the type of characters)

Edit the `customizations.yaml`: 

- Update the `spec.services.rack-resiliency.enabled` flag from `false` to `true`.
- Update the `spec.services.k8s_zone_prefix` and `spec.services.ceph_zone_prefix` sections with the required Kubernetes and ceph zone prefix.

Save and close the `customizations.yaml`.

Update the `site-init` secret in the Kubernetes cluster.

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

**NOTE**: Rack Resiliency `enabled` flag should be set to `true` for enablement to work, if it set to any other value like '1' or 'yes' it will be considered as `false`.

**Important Notes:**

* If the prefixes is defined, then the zones will be created in the format of `k8s_zone_prefix + rack_id` and `ceph_zone_prefix + rack_id`.
    * If the `spec.services.k8s_zone_prefix` has a value of `test-system` and the rack-id is `x3000`, then the Kubernetes zones will be created with the labels of value `test-system-x3000`.
    * If the `spec.services.ceph_zone_prefix` has a value of `test-storage-system` and the rack-id is `x3000`, then the Ceph zones will be created with the labels of value `test-storage-system-x3000`.
* If the `spec.services.k8s_zone_prefix` has no value defined and the rack-id is `x3000`, then the Kubernetes zones will be created with the labels of value `x3000`.
* If the `spec.services.ceph_zone_prefix` has no value defined and the rack-id is `x3000`, then the Ceph zones will be created with the labels of value `x3000`.
