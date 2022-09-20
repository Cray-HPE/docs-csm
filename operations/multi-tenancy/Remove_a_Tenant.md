# Removing a tenant

This page provides describes how an infrastructure administrator (not a tenant administrator) can remove a tenant when appropriate.

**`IMPORTANT`** Removing a tenant is a permanent operation and cannot be reverted. Removing a tenant will remove all tenant related namespaces from Kubernetes, along with any Kubernetes resources in those namespaces.

## Table of Contents

* [Remove the Slurm Operator Custom Resource (CR)](#remove-the-slurm-operator-custom-resource-cr)
* [Delete the tenant's custom resource (CR)](#delete-the-tenants-custom-resource-cr)

## Remove the Slurm Operator Custom Resource (CR)

* (`ncn-mw#`) To remove a Slurm tenant instance, delete the custom resource with
    `kubectl`:

    ```sh
    kubectl delete slurmcluster -n <namespace> <name>
    ```

This will remove the Slurm pods from the tenant namespace, but leave the
persistent volumes (to avoid data loss if the cluster is recreated).

In addition, remove any tenant-specific Ansible vars files in the `group_vars`
directory of the `slurm-config-management` VCS repository.

## Delete the tenant's custom resource (CR)

Below is an example of a `kubectl` command to remove the tenant by specifying its name:

* (`ncn-mw#`)

    ```bash
    kubectl -n tenants delete tenants vcluster-blue
    tenant.tapms.hpe.com "vcluster-blue" deleted
    ```

It can take a minute or so to fully delete the tenant and its namespaces, as `tapms` will remove `xnames` from HSM groups, remove Keycloak groups, and cleanup the HNC tree structure.
