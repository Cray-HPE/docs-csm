# Manage Critical Services

This page contains the procedures to list, add, delete and modify the critical services:

- Using Cray CLI
- By editing ConfigMap

The ConfigMap `rrs-mon-static` in the `rack-resiliency` namespace is where RR keeps its list of
critical services. The RR API/CLI commands to add services end up adding the new services to this
ConfigMap. Because the RR API/CLI does not support edits or deletes, those can only be
accomplished by directly editing the static ConfigMap. For more details on the RR ConfigMaps,
see [ConfigMaps](ConfigMaps.md).

Any change made to the RR critical services must be made both in RR itself and in the
[Kyverno Policy](Kyverno_Policy.md).

- [Check for service in cluster](#check-for-service-in-cluster)
- [Add, view, edit, or delete RR critical services](#add-view-edit-or-delete-rr-critical-services)
    - [Caution](#caution)
    - [List services using CLI](#list-services-using-cli)
    - [Describe service using CLI](#describe-service-using-cli)
    - [List services in ConfigMap](#list-services-in-configmap)
    - [Add services using CLI](#add-services-using-cli)
    - [Add services using ConfigMap](#add-services-using-configmap)
    - [Delete services using ConfigMap](#delete-services-using-configmap)
    - [Modify services using ConfigMap](#modify-services-using-configmap)
- [Update Kyverno cluster policy](#update-kyverno-cluster-policy)
    - [Add services to Kyverno policy](#add-services-to-kyverno-policy)
    - [Remove services from Kyverno policy](#remove-services-from-kyverno-policy)

## Check for service in cluster

Several procedures on this page require verifying that a particular service exists in the
cluster.

(`ncn-mw#`) Verify that a critical service is present in the Kubernetes cluster.

> In the following command, be sure to substitute the actual type, name, and
> namespace of the service.

```bash
kubectl get <deployment-or-statefulset> <name-of-the-critical-service> -n <namespace-of-the-service>
```

The command will give a "not found" error message if the service is not present in the cluster.

## Add, view, edit, or delete RR critical services

When performing any of these operations, no restart of `cray-rrs` is required in order
for the changes to take effect. However, there may be a delay before the changes are
picked up by the [Resiliency Monitoring Service (RMS)](Resiliency_Monitoring_Service.md).
For more details, see [Timing](Resiliency_Monitoring_Service.md#timing).

### Caution

- Do not delete or modify the critical services added by HPE. Nothing will prevent an administrator
  from doing this, but it is not supported.
- Having two services with the same name in different namespaces is generally not considered a best
  practice in CSM; this use case is not supported in RRS.
- Similarly, services with the same name but different types (e.g., StatefulSet and Deployment) are
  not supported.
- Avoid using the API or CLI to add critical services while following the deletion or modification
  procedures outlined on this page.

### List services using CLI

(`ncn-mw#`) List all critical services grouped by namespace.

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

### Describe service using CLI

(`ncn-mw#`) Get summarized information about a specific critical service.

```bash
cray rrs criticalservices describe <critical-service-name> --format toml
```

This command returns information such as configured instances, currently running instances, namespace, and type.

Example output:

```toml
[critical_service]
name = "cray-capmc"
namespace = "services"
type = "Deployment"
configured_instances = 3
```

### List services in ConfigMap

(`ncn-mw#`) View the list of critical services directly from the static ConfigMap.

```bash
kubectl get cm rrs-mon-static -n rack-resiliency -o jsonpath='{.data.critical-service-config.json}' | jq
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
        "...<output truncated>...",
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

### Add services using CLI

1. Verify that the critical services is present in the Kubernetes cluster.

    See [Check for service in cluster](#check-for-service-in-cluster).

1. Create JSON file with critical services configuration.

    - The file must be a text file containing a JSON representation of the critical services
      configuration.
    - The file may contain one or more services.
    - For complete details on the required format of the critical services configuration, see the
      [`CriticalServiceCmStaticType`](../../api/rrs.md#schemacriticalservicecmstatictype) schema.

    Example file:

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

1. (`ncn-mw#`) Add the service to RR.

    ```bash
    cray rrs criticalservices update --from-file <file-path> --format toml
    ```

    Example output:

    ```toml
    Update = "Successful"
    Successfully_Added_Services = [ "kube-proxy",]
    Already_Existing_Services = [ "coredns",]
    ```

1. Add the critical services to the Kyverno cluster policy.

    See [Add services to Kyverno policy](#add-services-to-kyverno-policy).

### Add services using ConfigMap

> It is strongly recommended to add critical services using the API or CLI, rather than directly
> editing the ConfigMap.

1. Verify that the critical services is present in the Kubernetes cluster.

    See [Check for service in cluster](#check-for-service-in-cluster).

1. (`ncn-mw#`) Edit the static ConfigMap and add services.

    1. Open the ConfigMap for editing.

        ```bash
        kubectl edit ConfigMap rrs-mon-static -n rack-resiliency
        ```

    1. Add additional service entries to the `critical-service-config.json` field under the
       `data` section.

    1. Save and close the editor, to apply the changes to the ConfigMap.

1. Add the critical services to the Kyverno cluster policy.

    See [Add services to Kyverno policy](#add-services-to-kyverno-policy).

### Delete services using ConfigMap

> Do not delete or modify the critical services added by HPE. Nothing will prevent an administrator
> from doing this, but it is not supported.

1. Verify that the critical services is present in the Kubernetes cluster.

    See [Check for service in cluster](#check-for-service-in-cluster).

1. (`ncn-mw#`) Edit the static ConfigMap and remove services.

    1. Open the ConfigMap for editing.

        ```bash
        kubectl edit ConfigMap rrs-mon-static -n rack-resiliency
        ```

    1. Remove service entries from the `critical-service-config.json` field under the
       `data` section.

    1. Save and close the editor, to apply the changes to the ConfigMap.

1. Remove the critical services from the Kyverno cluster policy.

    See [Remove services from Kyverno policy](#remove-services-from-kyverno-policy).

### Modify services using ConfigMap

The following attributes of a critical service may be modified.

- Name of service
- Type of service (Deployment/ StatefulSet)
- Namespace of service

> - Do not delete or modify the critical services added by HPE. Nothing will prevent an administrator
>   from doing this, but it is not supported.
> - Having two services with the same name in different namespaces is generally not considered a best
>   practice in CSM; this use case is not supported in RRS.
> - Similarly, services with the same name but different types (e.g., StatefulSet and Deployment) are
>   not supported.

The process of modifying a critical service is essentially the process of removing the current critical
service and then adding the modified critical service.

1. Remove the services being modified.

    See [Delete services using ConfigMap](#delete-services-using-configmap).

1. Add the modified services.

    See either of the following:

    - [Add services using CLI](#add-services-using-cli)
    - [Add services using ConfigMap](#add-services-using-configmap)

## Update Kyverno cluster policy

After adding, removing, or modifying critical services using any of the above methods, the Kyverno
cluster policy also must be updated to reflect those changes. The procedures to do this are included
in this section.

For more information on the Kyverno policy, see [Kyverno Policy](Kyverno_Policy.md).

### Add services to Kyverno policy

This procedure is only necessary after adding critical services to RR.

1. (`ncn-mw#`) Add the critical services to the Kyverno cluster policy.

    1. Open the policy for editing.

        ```bash
        kubectl edit clusterpolicy insert-labels-topology-constraints
        ```

    1. Under `spec.rules.match.any.resources.name`, add new entries with the names of the critical
       services that were added to RR.

    1. Save and close the editor, to apply the changes to the policy.

1. (`ncn-mw#`) For each service added, verify that it now exists in the policy.

    ```bash
    kubectl get clusterpolicy insert-labels-topology-constraints -o yaml |grep <name-of-the-critical-service>
    ```

1. (`ncn-mw#`) Restart the services that were added.

    CSM provides a script to automate this process.
    This script checks every Rack Resiliency critical service to see if the
    Kyverno policy has been applied to it or not. For any that have not, it performs rollout
    restarts on them, one at a time. During the service restart, the Kyverno policy is applied to each service.

    > The latest CSM documentation RPM must be installed on the node where this step is being performed.
    > See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).

    ```bash
    python3 /usr/share/doc/csm/upgrade/scripts/upgrade/scripts/k8s/rr_critical_service_restart.py
    ```

### Remove services from Kyverno policy

This procedure is only necessary after removing critical services from RR.

1. (`ncn-mw#`) Remove the critical services from the Kyverno cluster policy.

    1. Open the policy for editing.

        ```bash
        kubectl edit clusterpolicy insert-labels-topology-constraints
        ```

    1. Under `spec.rules.match.any.resources.name`, delete the entries with the names of the
       critical services that were removed from RR.

    1. Save and close the editor, to apply the changes to the policy.

1. (`ncn-mw#`) For each service removed, verify that it no longer exists in the policy.

    > If the service has been removed, this command should give no output.

    ```bash
    kubectl get clusterpolicy insert-labels-topology-constraints -o yaml |grep <name-of-the-critical-service>
    ```

Unlike when [adding services to the Kyverno policy](#add-services-to-kyverno-policy),
there is no need for a rollout restart.
