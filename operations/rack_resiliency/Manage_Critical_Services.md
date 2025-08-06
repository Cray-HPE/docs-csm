# Manage Critical Services

This page contains the procedures to list, add, delete and modify the critical services:

- Using Cray CLI
- By editing ConfigMap

The ConfigMap `rrs-mon-static` in the `rack-resiliency` namespace is where RR keeps its list of critical services. The API/CLI commands to add services end up adding the new services to this ConfigMap.
But because the API/CLI does not support edits or deletes, those can only be accomplished by directly editing the ConfigMap.

**NOTE**:

- Do not delete or modify the critical services added by HPE. Nothing will prevent an administrator from doing this, but it is not supported.
- Having two services with the same name in different namespaces is generally not considered a best practice in CSM, and as such, this use case is not supported in RRS.
- Similarly, services with the same name but different types (e.g., StatefulSet and Deployment) are also not supported.
- Avoid using API or CLI to add critical services while following the deletion or modification procedures outlined on this page.

## Additional guidelines for adding critical services with Cray CLI

- Always maintain valid JSON syntax
- Ensure there is no trailing comma after the last service entry
- Save and exit the editor to apply changes
- The changes take effect immediately - no restart of `cray-rrs` is required

## Critical services operations

- [List critical services using CLI](#list-critical-services-using-cli)
- [List critical services by viewing ConfigMap](#list-critical-services-by-viewing-configmap)
- [Add critical service using CLI](#add-critical-service-using-cli)
- [Add critical service using ConfigMap](#add-critical-service-using-configmap)
- [Delete critical service using ConfigMap](#delete-critical-service-using-configmap)
- [Modify critical service using ConfigMap](#modify-critical-service-using-configmap)
- [Add critical services to Kyverno clusterpolicy](#add-critical-services-to-kyverno-clusterpolicy)
- [Delete critical services from Kyverno clusterpolicy](#delete-critical-services-from-the-kyverno-clusterpolicy)

## List critical services using CLI

- (`ncn-mw#`) List all critical services grouped by namespace.

    ```bash
    cray rrs criticalservices list --format toml
    ```

    Example output:

    ```toml
    [critical_services.namespace]
    [[critical_services.namespace.kube-system]]
    name = "cilium-operator"
    type = "Deployment"

    [[critical_services.namespace.kube-system]]
    name = "coredns"
    type = "Deployment"

    [[critical_services.namespace.kube-system]]
    name = "sealed-secrets"
    type = "Deployment"

    [[critical_services.namespace.dvs]]
    name = "cray-activemq-artemis-operator-controller-manager"
    type = "Deployment"

    [[critical_services.namespace.dvs]]
    name = "cray-dvs-mqtt-ss"
    type = "StatefulSet"

    [[critical_services.namespace.services]]
    name = "cray-capmc"
    type = "Deployment"

    [[critical_services.namespace.services]]
    name = "cray-console-data"
    type = "Deployment"
    ```

- Get summarized information about a specific critical service:

    ```bash
    (`ncn-mw#`) cray rrs criticalservices describe <critical-service-name>
    ```

    Example Output:

    ```text
    [critical_service]
    name = "cray-capmc"
    namespace = "services"
    type = "Deployment"
    configured_instances = 3
    ```

    This command returns information such as configured instances, currently running instances, namespace, and type.

## List critical services by viewing ConfigMap

- For viewing the list of critical services directly from the ConfigMap use the below command:

    ```bash
    (`ncn-mw#`) kubectl get cm rrs-mon-static -n rack-resiliency -o jsonpath='{.data.critical-service-config.json}' | jq
    ```

    Truncated example output (the actual output of ConfigMap will be larger):

    ```text
    {
        "critical_services": {
            "cilium-operator": {
                "namespace": "kube-system",
                "type": "Deployment"
            },
            "coredns": {
                "namespace": "kube-system",
                "type": "Deployment"
            },
            ...
            "sshot-net-operator": {
                "namespace": "sshot-net-operator",
                "type": "Deployment"
            },
            "kube-proxy": {
                "namespace": "kube-system",
                "type": "StatefulSet"
            }
        }
    }
    ```

## Add critical service using CLI

### 1. Verify that the critical services is present in the Kubernetes cluster

```bash
(`ncn-mw#`) kubectl get deployment/statefulset <name-of-the-critical-service> -n <namespace-of-the-service>
```
In the above command, replace \<name-of-the-critical-service\> with the name of critical service to be verified
and \<namespace-of-the-service\> with the correct namespace in which its configured.

If the service is configured, proceed to the next step.

### 2. Create a new JSON file with critical services configuration:

    ```bash
    (`ncn-mw#`) cray rrs criticalservices update --from-file <file-path>
    ```

    The file must be a text file containing a JSON representation of the critical services configuration.
    For example:

    ```json
    {
        "critical_services": {
            "coredns": {
                "namespace": "kube-system",
                "type": "Deployment"
            },
            "kube-proxy": {
                "namespace": "kube-system",
                "type": "StatefulSet"
            }
        }
    }
    ```

    Example Output:

    ```text
    Update = "Successful"
    Successfully_Added_Services = [ "kube-proxy",]
    Already_Existing_Services = [ "coredns",]
    ```

    This allows an administrator to specify multiple services in the same command.
    For complete details on the required format of the critical services configuration, see the
    [`CriticalServiceCmStaticType`](../../api/rrs.md#schemacriticalservicecmstatictype) schema.

- After this proceed to add critical service(s) to [kyverno `clusterpolicy`](#add-critical-services-to-kyverno-clusterpolicy)

## Add critical service using ConfigMap

Before editing the ConfigMap, follow the [instructions](Manage_Critical_Services.md#1-verify-that-the-critical-services-is-present-in-the-kubernetes-cluster) mentioned
to check whether the service is configured on the Kubernetes cluster. Proceed to next step if the servie configured.

### 1 Edit the ConfigMap

Start by editing the ConfigMap:

```bash
(`ncn-mw#`) kubectl edit ConfigMap rrs-mon-static -n rack-resiliency
```

Once inside the editor, look for the `critical-service-config.json` field under the `data` section.

Example output:

```text
apiVersion: v1
data:
  ceph_monitoring_polling_interval: "60"
  ceph_monitoring_total_time: "600"
  ceph_pre_monitoring_delay: "60"
  critical-service-config.json: |-
    {
      "critical_services": {
        "cilium-operator": {
          "namespace": "kube-system",
          "type": "Deployment"
        },
        "coredns": {
          "namespace": "kube-system",
          "type": "Deployment"
        },
        "cray-activemq-artemis-operator-controller-manager": {
          "namespace": "dvs",
          "type": "Deployment"
        },
        "cray-capmc": {
          "namespace": "services",
          "type": "Deployment"
        },
        "cray-ceph-csi-cephfs-provisioner": {
          "namespace": "ceph-cephfs",
          "type": "Deployment"
        },
        "cray-ceph-csi-rbd-provisioner": {
          "namespace": "ceph-rbd",
          "type": "Deployment"
        }
    ...
```

### 2 Add the entire critical service block, including the trailing comma

Example of adding a critical service:

For this example, this is the initial critical services list in the ConfigMap:

```json
{
    "critical_services": {
        "cilium-operator": {
            "namespace": "kube-system",
            "type": "Deployment"
        },
        "cray-ceph-csi-rbd-provisioner": {
            "namespace": "ceph-rbd",
            "type": "Deployment"
        }
    }
}
```

In this example, the administrator wishes to add the `coredns` critical service. To do this, they remove the following three lines:

```json
"coredns": {
    "namespace": "kube-system",
    "type": "Deployment"
}
```

After adding the entry, the list will look like:

```json
{
    "critical_services": {
        "cilium-operator": {
            "namespace": "kube-system",
            "type": "Deployment"
        },
        "coredns": {
            "namespace": "kube-system",
            "type": "Deployment"
        },
        "cray-ceph-csi-rbd-provisioner": {
            "namespace": "ceph-rbd",
            "type": "Deployment"
        }
    }
}
```

After this proceed to add critical service(s) to [kyverno `clusterpolicy`](#add-critical-services-to-kyverno-clusterpolicy)

## Delete critical service using ConfigMap

Before editing the ConfigMap, follow the [instructions](Manage_Critical_Services.md#1-verify-that-the-critical-services-is-present-in-the-kubernetes-cluster) mentioned
to check whether the service is configured on the Kubernetes cluster. Proceed to next step if the servie configured.

### 1. Edit the ConfigMap

Start by editing the ConfigMap:

```bash
(`ncn-mw#`) kubectl edit ConfigMap rrs-mon-static -n rack-resiliency
```

Once inside the editor, look for the `critical-service-config.json` field under the `data` section.

Example output:

```text
apiVersion: v1
data:
  ceph_monitoring_polling_interval: "60"
  ceph_monitoring_total_time: "600"
  ceph_pre_monitoring_delay: "60"
  critical-service-config.json: |-
    {
      "critical_services": {
        "cilium-operator": {
          "namespace": "kube-system",
          "type": "Deployment"
        },
        "coredns": {
          "namespace": "kube-system",
          "type": "Deployment"
        },
        "cray-activemq-artemis-operator-controller-manager": {
          "namespace": "dvs",
          "type": "Deployment"
        },
        "cray-capmc": {
          "namespace": "services",
          "type": "Deployment"
        },
        "cray-ceph-csi-cephfs-provisioner": {
          "namespace": "ceph-cephfs",
          "type": "Deployment"
        },
        "cray-ceph-csi-rbd-provisioner": {
          "namespace": "ceph-rbd",
          "type": "Deployment"
        },
    ...
```

### 2. Remove the entire critical service block, including the trailing comma

Example of removing a critical service:

For this example, this is the initial critical services list in the ConfigMap:

```json
{
    "critical_services": {
        "cilium-operator": {
            "namespace": "kube-system",
            "type": "Deployment"
        },
        "coredns": {
            "namespace": "kube-system",
            "type": "Deployment"
        },
        "cray-ceph-csi-rbd-provisioner": {
            "namespace": "ceph-rbd",
            "type": "Deployment"
        }
    }
}
```

In this example, the administrator wishes to delete the `coredns` critical service. To do this, they remove the following three lines:

```json
"coredns": {
    "namespace": "kube-system",
    "type": "Deployment"
}
```

After deleting the entry, the list will look like:

```json
{
    "critical_services": {
        "cilium-operator": {
            "namespace": "kube-system",
            "type": "Deployment"
        },
        "cray-ceph-csi-rbd-provisioner": {
            "namespace": "ceph-rbd",
            "type": "Deployment"
        }
    }
}
```

After this proceed to delete critical service(s) from [kyverno `clusterpolicy`](#delete-critical-services-from-the-kyverno-clusterpolicy)

## Modify critical service using ConfigMap

### 1. Edit the ConfigMap

Start by editing the ConfigMap:

```bash
(`ncn-mw#`) kubectl edit ConfigMap rrs-mon-static -n rack-resiliency
```

Once inside the editor, look for the `critical-service-config.json` field under the `data` section.

Example output:

```text
apiVersion: v1
data:
  ceph_monitoring_polling_interval: "60"
  ceph_monitoring_total_time: "600"
  ceph_pre_monitoring_delay: "60"
  critical-service-config.json: |-
    {
      "critical_services": {
        "cilium-operator": {
          "namespace": "kube-system",
          "type": "Deployment"
        },
        "coredns": {
          "namespace": "kube-system",
          "type": "Deployment"
        },
        "cray-activemq-artemis-operator-controller-manager": {
          "namespace": "dvs",
          "type": "Deployment"
        },
        "cray-capmc": {
          "namespace": "services",
          "type": "Deployment"
        },
        "cray-ceph-csi-cephfs-provisioner": {
          "namespace": "ceph-cephfs",
          "type": "Deployment"
        },
        "cray-ceph-csi-rbd-provisioner": {
          "namespace": "ceph-rbd",
          "type": "Deployment"
        },
    ...
```

### 2. Modify the desired field(s) in service block

Example of modifying a service:

For this example, this is the initial critical services list in the ConfigMap:

```json
{
    "critical_services": {
        "cilium-operator": {
            "namespace": "kube-system",
            "type": "Deployment"
        },
        "coredns": {
            "namespace": "kube-system",
            "type": "Deployment"
        },
        "cray-ceph-csi-rbd-provisioner": {
            "namespace": "ceph-rbd",
            "type": "Deployment"
        }
    }
}
```

In this example, the administrator wishes to modify the `coredns` critical service. After modifying save the changes.

```json
{
    "critical_services": {
        "cilium-operator": {
            "namespace": "kube-system",
            "type": "Deployment"
        },
        "coredns": {
            "namespace": "rack-resiliency",
            "type": "Deployment"
        },
        "cray-ceph-csi-rbd-provisioner": {
            "namespace": "ceph-rbd",
            "type": "Deployment"
        }
    }
}
```

## Add critical services to Kyverno `clusterpolicy`

The below instructions should be followed only after adding the critical services using [Cray CLI](#add-critical-service-using-cli) or by [editing the ConfigMap](#add-critical-service-using-configmap).

### 1. Add the critical services to the Kyverno `clusterpolicy`

Edit the Kyverno `clusterpolicy` using the below command:

```bash
(`ncn-mw#`) kubectl edit clusterpolicy insert-labels-topology-constraints
```

Under `spec.rules.match.any.resources.name` add a new entry with the name of critical service to be added.
Save the `clusterpolicy` and verify the new entry by using the below command and searching for the new entry:

```bash
kubectl get clusterpolicy insert-labels-topology-constraints -o yaml |grep <name-of-the-critical-service>
```

### 2. Do a rollout restart

Rollout restart the critical service by using the command below:

- If the service is a `deployment` use:

```bash
kubectl rollout restart deployment -n <namespace> <service-name>
```

- If the service is a `statefulset` use:

```bash
kubectl rollout restart statefulset -n <namespace> <service-name>
```

## Delete critical services from the Kyverno `clusterpolicy`

The below instructions should be followed only after deleting the critical services by [editing the ConfigMap](#delete-critical-service-using-configmap).

Edit the Kyverno `clusterpolicy` using the below command:

```bash
(`ncn-mw#`) kubectl edit clusterpolicy insert-labels-topology-constraints
```

Under `spec.rules.match.any.resources.name` delete the entry of critical service.
Save the `clusterpolicy` and verify the new entry has been deleted by using the below command and
searching for the deleted entry:

```bash
(`ncn-mw#`) kubectl get clusterpolicy insert-labels-topology-constraints -o yaml |grep <name-of-the-critical-service>
```

The command should not return any value.
