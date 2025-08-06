# Enabling Rack Resiliency

As mentioned in the [Architecture overview](README.md#architecture-overview), enabling Rack Resiliency is the
first stage for setting up Rack Resiliency. By default the Rack Resiliency feature is disabled. Based on whether CSM
is getting freshly installed or upgraded to a new version, use the below steps to enable Rack Resiliency.

**NOTE:** 
* Rack Resiliency can be enabled only during fresh install of CSM 1.7 or an upgrade from CSM 1.6 to CSM 1.7. 
* Rack Resiliency cannot be disabled after it has been enabled during the install or upgrade.

## Case 1: Fresh install

Follow the steps in [Prepare Site Init](../../install/prepare_site_init.md#enable-rack-resiliency) to enable
Rack Resiliency and optionally add prefixes for Kubernetes and Ceph zones.

## Case 2: Upgrade

To enable Rack Resiliency during upgrade with IUF, use the procedure below, before the **Management Node Rollout**
stage of [CSM upgrade](../iuf/workflows/management_rollout.md).

### Steps to enable Rack Resiliency and add zone prefixes

#### Retrieve the `customizations.yaml` file

```bash
kubectl -n loftsman get secret site-init -o json | jq -r '.data."customizations.yaml"' | base64 -d > /tmp/customizations.yaml
```

##### Update the `customizations.yaml` file

```bash
vi /tmp/customizations.yaml
```

**`NOTE`**

- If site specific identities are needed for zones, zones prefixes for Kuberenets and Ceph can be configured.
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

**NOTE**: If the Rack Resiliency `enabled` flag is not present in `customizations.yaml`, or if it is set to a value that the
[Ansible `bool` filter](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/bool_filter.html)
does not recognize as true, then it will be interpreted as false.

**Important Notes:**

- If the prefixes is defined, then the zones will be created in the format of `k8s_zone_prefix + rack_id` and `ceph_zone_prefix + rack_id`.
    - If the `spec.services.k8s_zone_prefix` has a value of `test-system` and the rack-id is `x3000`, then the Kubernetes zones will be created with the labels of value `test-system-x3000`.
    - If the `spec.services.ceph_zone_prefix` has a value of `test-storage-system` and the rack-id is `x3000`, then the Ceph zones will be created with the labels of value `test-storage-system-x3000`.
- If the `spec.services.k8s_zone_prefix` has no value defined and the rack-id is `x3000`, then the Kubernetes zones will be created with the labels of value `x3000`.
- If the `spec.services.ceph_zone_prefix` has no value defined and the rack-id is `x3000`, then the Ceph zones will be created with the labels of value `x3000`.
