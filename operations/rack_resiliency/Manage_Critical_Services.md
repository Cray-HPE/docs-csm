# Manage Critical Services

This page contains the procedures to list, add, delete and modify the critical services:
- Using Cray CLI
- By editing configmap

The ConfigMap `rrs-mon-static` in the `rack-resiliency` namespace is where RR keeps its list of critical services. The API/CLI commands to add services end up adding the new services to this ConfigMap. But because the API/CLI does not support edits or deletes, those can only be accomplished by directly editing the ConfigMap.

**NOTE**:

* Do not delete or modify the critical services added by HPE. Nothing will prevent an administrator from doing this, but it is not supported.
* Having two services with the same name in different namespaces is generally not considered a best practice in CSM, and as such, this use case is not supported in RRS.
* Similarly, services with the same name but different types (e.g., StatefulSet and Deployment) are also not supported.
* Avoid using API or CLI to add critical services while following the deletion or modification procedures outlined on this page.

#### Additional guidelines

* Always maintain valid JSON syntax
* Ensure there's no trailing comma after the last service entry
* Save and exit the editor to apply changes
* The changes take effect immediately - no restart required

### Critical services operations

* [List critical service using Cray CLI](#list-critical-services-using-cray-cli)
* [List critical service by viewing configmap](#list-critical-services-by-viewing-configmap)
* [Adding a critical service using Cray CLI](#adding-a-critical-service-using-cray-cli)
* [Adding a critical service from configmap](#adding-a-critical-service-using-configmap)
* [Delete a critical service](#delete-the-critical-service-using-configmap)
* [Modify a critical service](#modify-the-critical-service-using-configmap)
* [Add critical service(s) to Kyverno clusterpolicy](#add-critical-services-to-kyverno-clusterpolicy)
* [Delete critical services(s) from Kyverno clusterpolicy](#delete-critical-services-from-the-kyverno-clusterpolicy)

## List critical services using Cray CLI

* List all critical services grouped by namespace:

    ```bash
    (`ncn-mw#`) cray rrs criticalservices list
    ```

  Example Output:
    ```bash
    ncn-m001:~ # cray rrs criticalservices list
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

* Get summarized information about a specific critical service:

    ```bash
    (`ncn-mw#`) cray rrs criticalservices describe <critical-service-name>
    ```

  Example Output:
    ```bash
    ncn-m001:~ # cray rrs criticalservices describe cray-capmc
    [critical_service]
    name = "cray-capmc"
    namespace = "services"
    type = "Deployment"
    configured_instances = 3
    ```

    This command returns information such as configured instances, currently running instances, namespace, and type.

## List critical services by viewing configmap

* For viewing the list of critical services directly from the configmap use the below command:

    ```bash
    (`ncn-mw#`) kubectl get cm rrs-mon-static -n rack-resiliency -o jsonpath='{.data.critical-service-config\.json}' | jq
    ```

  Truncated example output (the actual output of ConfigMap will be larger):
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

## Adding a critical service using Cray CLI

* Create a new JSON file with critical services configuration:

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
    ```bash
    ncn-m001:~ # cray rrs criticalservices update --from-file new-critical-services.json
    Update = "Successful"
    Successfully_Added_Services = [ "kube-proxy",]
    Already_Existing_Services = [ "coredns",]
    ```

    This allows an administrator to specify multiple services in the same command.
    For complete details on the required format of the critical services configuration, see the
    [`CriticalServiceCmStaticType`](../../api/rrs.md#schemacriticalservicecmstatictype) schema.

* After this proceed to add critical service(s) to [kyverno `clusterpolicy`](#add-critical-services-to-kyverno-clusterpolicy)

## Adding a critical service using configmap

Verify that the list of critical services is present in the ConfigMap

```bash
(`ncn-mw#`) kubectl get cm -n rack-resiliency rrs-mon-static -o jsonpath='{.data}' | jq -r '."critical-service-config.json"'
```

### 1 Edit the ConfigMap

Start by editing the ConfigMap:

```bash
(`ncn-mw#`) kubectl edit configmap rrs-mon-static -n rack-resiliency
```

Once inside the editor, look for the `critical-service-config.json` field under the `data` section.

Example output:

```yaml
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
},
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
        },
    }
}
```

After this proceed to add critical service(s) to [kyverno `clusterpolicy`](#add-critical-services-to-kyverno-clusterpolicy)

## Delete the critical service using ConfigMap

Verify that the list of critical services is present in the ConfigMap

```bash
(`ncn-mw#`) kubectl get cm -n rack-resiliency rrs-mon-static -o jsonpath='{.data}' | jq -r '."critical-service-config.json"'
```

### 1 Edit the ConfigMap

Start by editing the ConfigMap:

```bash
(`ncn-mw#`) kubectl edit configmap rrs-mon-static -n rack-resiliency
```

Once inside the editor, look for the `critical-service-config.json` field under the `data` section.

Example output:

```yaml
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

### 2 Remove the entire critical service block, including the trailing comma

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
        },
    }
}
```

In this example, the administrator wishes to delete the `coredns` critical service. To do this, they remove the following three lines:

```json
"coredns": {
    "namespace": "kube-system",
    "type": "Deployment"
},
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
        },
    }
}
```
After this proceed to delete critical service(s) from [kyverno `clusterpolicy`](#delete-critical-services-from-the-kyverno-clusterpolicy)

## Modify the critical service using ConfigMap

Verify that the list of critical services is present in the ConfigMap

```bash
(`ncn-mw#`) kubectl get cm -n rack-resiliency rrs-mon-static -o jsonpath='{.data}' | jq -r '."critical-service-config.json"'
```

#### 1. Edit the ConfigMap

Start by editing the ConfigMap:

```bash
(`ncn-mw#`) kubectl edit configmap rrs-mon-static -n rack-resiliency
```

Once inside the editor, look for the `critical-service-config.json` field under the `data` section.

Example output:

```yaml
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

#### 2 Modify the desired field(s) in service block

Example of modifying a service:

For this example, this is the initial critical services list in the ConfigMap:

```yaml
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
        },
    }
}
```

In this example, the administrator wishes to modify the `coredns` critical service. After modifying save the changes.

```yaml
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
        },
    }
}
```

## Add critical service(s) to Kyverno `clusterpolicy`

The below instructions should be followed only after adding the critical service(s) using [Cray CLI](#adding-a-critical-service-using-cray-cli) or by [editing the configmap](#adding-a-critical-service-using-configmap).

If the service(s) are not added refer to:
* [Using Cray CLI](#adding-a-critical-service-using-cray-cli)
* [By editing configmap](#adding-a-critical-service-using-configmap)

### 1. Verify that the critical services is present in the Kubernetes cluster

```bash
(`ncn-mw#`) kubectl get deployment/statefulset \<name-of-the-critical-service\> -n \<namespace-of-the-service\>
```

In the above command, replace <name-of-the-critical-service> with the name of critical service to be verified 
and <name-of-the-service> with the correct namespace in which its configured.

If the service is configured, proceed to the next step.

### 2. Add the critical services to the Kyverno `clusterpolicy`

Edit the Kyverno `clusterpolicy` using the below command: 

```bash
(`ncn-mw#`) kubectl edit clusterpolicy insert-labels-topology-constraints
```

Under `spec.rules.match.any.resources.name` add a new entry with the name of critical service to be added.
Save the `clusterpolicy` and verify the new entry by using the below command and searching for the new entry:

```bash
kubectl get clusterpolicy insert-labels-topology-constraints -o yaml |grep \<name-of-the-critical-service\>
```

## Delete critical service(s) from the Kyverno `clusterpolicy`

The below instructions should be followed only after deleting the critical service(s) by [editing the configmap](#delete-the-critical-service-using-configmap).

If the service(s) are not deleted refer to:
* [By editing configmap](#delete-the-critical-service-using-configmap)

### 1. Verify that the critical services is present in the Kyverno `clusterpolicy`

First ensure that the critical service is already present as part of the Kyverno `clusterpolicy` using the below
command:

```bash
(`ncn-mw#`) kubectl get clusterpolicy insert-labels-topology-constraints -o yaml |grep \<name-of-the-critical-service\>
```

If the service is configured, proceed to the next step.

### 2. Delete the critical services from the Kyverno `clusterpolicy`

Edit the Kyverno `clusterpolicy` using the below command: 

```bash
(`ncn-mw#`) kubectl edit clusterpolicy insert-labels-topology-constraints
```

Under `spec.rules.match.any.resources.name` delete the entry of critical service.
Save the `clusterpolicy` and verify the new entry has been deleted by using the below command and 
searching for the deleted entry:

```bash
(`ncn-mw#`) kubectl get clusterpolicy insert-labels-topology-constraints -o yaml |grep \<name-of-the-critical-service\>
```

The command should not return any value.
