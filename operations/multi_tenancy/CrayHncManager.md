# Cray HNC Manager

Beginning in CSM 1.3, the [HNC controller](https://github.com/kubernetes-sigs/hierarchical-namespaces) is deployed as part of the multi-tenancy solution for namespace management and object propagation.
This controller is deployed in CSM with the `cray-hnc-manager` Helm chart. This HNC controller is only managing the following namespaces related to multi-tenancy:

* `multi-tenancy`
* `slurm-operator`
* `tapms-operator`
* `tenants`
* &lt;any namespaces created for a given tenant&gt;

Generally, operations for managing tenants don't require interacting explicitly with the HNC controller, aside from the initial configuration, as `tapms` interacts with the HNC controller programmatically to construct HNC specific namespaces.

## Table of contents

* [Tenant naming requirements](#tenant-naming-requirements)
* [`kubectl` HNS plugin](#kubectl-hns-plugin)

## Tenant Naming Requirements

In order to ensure the HNC controller doesn't manage more namespaces than desired, CSM deploys this controller configured such that only the namespaces listed above are valid namespace names,
along with tenant specific namespaces, which are required to have a predictable prefix.
This prefix is configurable, and can be modified when deploying the `cray-hnc-manager` Helm chart, by changing the following value via customizations:

```bash
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
