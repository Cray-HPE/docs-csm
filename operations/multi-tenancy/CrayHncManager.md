# Cray HNC Manager

* [Overview](#overview)
* [Terminology](#terminology)
* [Tenant naming requirements](#tenant-naming-requirements)
* [`kubectl` HNS plugin](#kubectl-hns-plugin)
* [Resource propagation](#resource-propagation)

## Overview

The [HNC controller](https://github.com/kubernetes-sigs/hierarchical-namespaces) is deployed as part of the multi-tenancy solution for namespace management and object propagation.
This controller is deployed in CSM with the `cray-hnc-manager` Helm chart. This HNC controller is only managing the following namespaces related to multi-tenancy:

* `multi-tenancy`
* `slurm-operator`
* `tapms-operator`
* `tenants`
* Any namespaces created for a given tenant

Generally, operations for managing tenants do not require interacting explicitly with the HNC controller, aside from the initial configuration.
This is because `tapms` interacts with the HNC controller programmatically to construct `HNC-specific` namespaces.

## Terminology

* Hierarchical Namespace Controller (HNC): The Kubernetes operator which controls hierarchical namespaces.
* Hierarchical Namespaces (HNS): The namespaces created and managed by the HNC.

## Tenant naming requirements

In order to ensure that the HNC controller does not manage more namespaces than desired, CSM deploys this controller configured such that only the namespaces listed above are valid namespace names,
along with tenant-specific namespaces, which are required to have a predictable prefix.
This prefix is configurable, and can be modified when deploying the `cray-hnc-manager` Helm chart, by changing the following value via customizations:

```yaml
#
# Default behavior is to require 'vcluster' as the tenant/namespace
# prefix.
#
validTenantNamePrefix: vcluster
```

## `kubectl` HNS plugin

In order to simplify HNC management CSM NCNs are installed with the `kubectl-hns` plugin (see the `Installing` section at [HNC Releases](https://github.com/kubernetes-sigs/hierarchical-namespaces/releases) for more information on how to install).

* (`ncn-mw#`) An example command of how to view a tree structure:

    ```bash
    kubectl hns tree multi-tenancy
    ```

    Example output:

    ```text
    multi-tenancy
    ├── slurm-operator
    ├── tapms-operator
    └── tenants
        └── [s] vcluster-blue
            ├── [s] vcluster-blue-slurm
            └── [s] vcluster-blue-user
    ```

* (`ncn-mw#`) This plugin can be used to perform administrator type functions. For more information, run the following command:

    ```bash
    kubectl hns --help
    ```

    Example output:

    ```text
    Manipulates hierarchical namespaces provided by HNC
    
    Usage:
      kubectl-hns [command]
    
    Available Commands:
      completion  generate the autocompletion script for the specified shell
      config      Manipulates the HNC configuration
      create      Creates a subnamespace under the given parent.
      describe    Displays information about the hierarchy configuration
      help        Help about any command
      set         Sets hierarchical properties of the given namespace
      tree        Display one or more hierarchy trees
      version     Show version of HNC plugin
    ```

## Resource propagation

* (`ncn-mw#`) By default, `hnc` will propagate the following Kubernetes objects from a parent to child namespace:

    ```bash
    kubectl hns config describe
    ```

    Example output:

    ```text
    Synchronized resources:
    * Propagating: limitrange (/v1)
    * Propagating: resourcequota (/v1)
    * Propagating: rolebindings (/v1)
    * Propagating: roles (/v1)
    ```

Note that propagating `Roles` and `RoleBindings` are default behavior for `hnc`.
If there are `Roles` and `Rolebindings` that should not be propagated to child namespaces, this behavior can be changed by adding a
Kubernetes annotation to the object in the parent namespace:

```yaml
propagate.hnc.x-k8s.io/none: "true"
```

Adding the `propagate.hnc.x-k8s.io/none: "true"` annotation to the `metadata`.`annotations` section of a given Kubernetes resource will disable
propagation to any child namespaces for that resource:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  annotations:
    meta.helm.sh/release-name: cray-drydock
    meta.helm.sh/release-namespace: loftsman
    propagate.hnc.x-k8s.io/none: "true"
  creationTimestamp: "2022-08-24T18:47:02Z"
  labels:
    app.kubernetes.io/managed-by: Helm
    helm.sh/chart: cray-drydock-2.14.5
  name: cpu-mem-limit-range
  namespace: multi-tenancy
  resourceVersion: "5944993"
  uid: ecdb28f4-6de7-482e-a42e-0a3693faeac4
spec:
  limits:
  - default:
      cpu: "2"
      memory: 2Gi
    defaultRequest:
      cpu: 10m
      memory: 64Mi
    type: Container
```

* (`ncn-mw#`) The following command can be used to add the above annotation:

    ```bash
    kubectl annotate limitrange cpu-mem-limit-range -n multi-tenancy propagate.hnc.x-k8s.io/none=true
    ```

    Example output:

    ```text
    limitrange/cpu-mem-limit-range edited
    ```

`Infrastructure Administrators` can add and remove the propagation of Kubernetes resources using the `kubectl hns` command.

* (`ncn-mw#`) Configure HNC to propagate secrets:

    ```bash
    kubectl hns config set-resource secrets --mode Propagate
    ```

    Now verify the change was accepted:

    ```bash
    kubectl hns config describe
    ```

    Example output:

    ```text
    Synchronized resources:
    * Propagating: limitrange (/v1)
    * Propagating: resourcequota (/v1)
    * Propagating: rolebindings (/v1)
    * Propagating: roles (/v1)
    * Propagating: secrets (/v1)
    ```

* (`ncn-mw#`) Configure HNC to no longer propagate secrets:

    ```bash
    kubectl hns config delete-type --resource secrets
    ```

    Example output:

    ```text
    Configuration for type with group: , resource: secrets is deleted
    ```

    Now verify the change was accepted:

    ```bash
    kubectl hns config describe
    ```

    Example output:

    ```text
    Synchronized resources:
    * Propagating: limitrange (/v1)
    * Propagating: resourcequota (/v1)
    * Propagating: rolebindings (/v1)
    * Propagating: roles (/v1)
    ```
