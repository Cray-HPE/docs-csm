# Modifying a Tenant

This page provides information about how to modify a tenant. Modifications that are supported are limited to:

- Updating the list of component names (xnames) assigned to this tenant.
- Adding/deleting `childNamespaces`.

## Table of contents

- [Modify the existing TAPMS CR](#modify-the-existing-tapms-cr)
- [Apply the modified TAPMS CR](#apply-the-modified-tapms-cr)
- [Modify the `slurm` operator CR](#modify-the-slurm-operator-cr)
- [Apply the `slurm` operator CR](#apply-the-slurm-operator-cr)
- [Modify the Slurm configuration](#modify-the-slurm-configuration)

## Modify the existing TAPMS CR

- An example of a change to add an xname to a tenant:

    ```yaml
    apiVersion: tapms.hpe.com/v1alpha1
    kind: Tenant
    metadata:
      name: vcluster-blue
    spec:
      childnamespaces:
        - user
        - slurm
      tenantname: vcluster-blue
      tenantresources:
        - type: compute
          hsmgrouplabel: blue
          enforceexclusivehsmgroups: true
          xnames:
            - x0c3s5b0n0
            - x0c3s6b0n0
            - x0c3s7b0n0 <-- Adding this xname
    ```

## Apply the modified TAPMS CR

- (`ncn-mw#`) When a tenant CRD is applied, `tapms` will determine any changes to the tenant, and reconcile any changes to `childNamespaces` and `xnames`.

    ```bash
    kubectl apply -n tenants -f <tenant.yaml>
    ```

    Example output:

    ```text
    tenant.tapms.hpe.com/vcluster-blue configured
    ```

- (`ncn-mw#`) It can take up to a minute for `tapms` to reconcile the change. The following command can be used to monitor the status of the tenant:

    ```bash
    kubectl get tenant -n tenants vcluster-blue -o yaml
    ```

    Example output:

    ```yaml
    apiVersion: tapms.hpe.com/v1alpha1
    kind: Tenant
    metadata:
      annotations:
        kubectl.kubernetes.io/last-applied-configuration: |
          {"apiVersion":"tapms.hpe.com/v1alpha1","kind":"Tenant","metadata":{"annotations":{},"name":"vcluster-blue","namespace":"tenants"},"spec":{"childnamespaces":["user","slurm"],"tenantname":"vcluster-blue","tenantresources":[{"enforceexclusivehsmgroups":true,"hsmgrouplabel":"blue","type":"compute","xnames":["x0c3s5b0n0","x0c3s6b0n0"]}]}}
      creationTimestamp: "2022-08-23T18:37:25Z"
      finalizers:
      - tapms.hpe.com/finalizer
      generation: 3
      name: vcluster-blue
      namespace: tenants
      resourceVersion: "3157072"
      uid: 074b6db1-f504-4e9c-8245-259e9b22d2e6
    spec:
      childnamespaces:
      - user
      - slurm
      state: Deployed
      tenantname: vcluster-blue
      tenantresources:
      - enforceexclusivehsmgroups: true
        hsmgrouplabel: blue
        type: compute
        xnames:
        - x0c3s5b0n0
        - x0c3s6b0n0
        - x0c3s7b0n0
    status:
      childnamespaces:
      - vcluster-blue-user
      - vcluster-blue-slurm
      tenantresources:
      - enforceexclusivehsmgroups: true
        hsmgrouplabel: blue
        type: compute
        xnames:
        - x0c3s5b0n0
        - x0c3s6b0n0
        - x0c3s7b0n0
      uuid: 074b6db1-f504-4e9c-8245-259e9b22d2e6
    ```

- (`ncn-mw#`) The `cray` command can now be used to display changes to the HSM group:

    ```bash
    cray hsm groups describe blue --format toml
    ```

    Example output:

    ```toml
    label = "blue"
    description = ""
    exclusiveGroup = "tapms-exclusive-group-label"
    tags = [ "vcluster-blue",]

    [members]
    ids = [ "x0c3s5b0n0", "x0c3s6b0n0", "x0c3s7b0n0"]
    ```

## Modify the `slurm` operator CR

To make changes to a Slurm tenant deployment, first update the Slurm custom
resource file. The Slurm operator will attempt to reconcile the following
changes:

- Changing the munge key length
- Changing the `slurmctld` PVC
- Changing the Percona XtraDB, `slurmctld`, or `slurmdbd` deployments

## Apply the `slurm` operator CR

- (`ncn-mw#`) To update the Slurm custom resource, apply the changed file:

    ```sh
    kubectl apply -f <cluster>.yaml
    ```

Once the custom resource has been updated, the Slurm operator will attempt to
update the relevant Kubernetes resources to reflect the changes.

## Modify the Slurm configuration

If the list of nodes assigned to a tenant changes, the Slurm configuration
must be updated by rerunning the Kubernetes job that generates it. This
procedure can also be used to change Slurm configuration settings, or add new
Slurm configuration files.

- (`ncn-mw#`) Get the current configuration:

    ```sh
    kubectl get configmap -n slurm-operator <cluster>-config-templates -o yaml >slurm-config-templates.yaml
    ```

- (`ncn-mw#`) To edit an existing configuration file (for example, `slurm.conf`):

    ```sh
    yq r slurm-config-templates.yaml 'data."slurm.conf"' >slurm.conf
    # Edit slurm.conf
    yq w -i slurm-config-templates.yaml 'data."slurm.conf"' "$(cat slurm.conf)"
    ```

- (`ncn-mw#`) To add a new configuration file (for example, `topology.conf`):

    ```sh
    yq w -i slurm-config-templates.yaml 'data."topology.conf"' "$(cat topology.conf)"
    ```

- (`ncn-mw#`) Apply changes to the configuration templates:

    ```sh
    kubectl apply -f slurm-config-templates.yaml
    ```

- (`ncn-mw#`) Rerun the Slurm configuration job:

    ```sh
    kubectl get job -n slurm-operator <cluster>-slurm-config -o yaml >slurm-config.yaml
    yq d -i slurm-config.yaml spec.template.metadata
    yq d -i slurm-config.yaml spec.selector
    kubectl delete -f slurm-config.yaml
    kubectl create -f slurm-config.yaml
    ```

- (`ncn-mw#`) Once the job has completed, reconfigure Slurm:

    ```sh
    SLURMCTLD_POD=$(kubectl get pod -n <namespace> -lapp.kubernetes.io/name=slurmctld -o jsonpath='{.items[0].metadata.name}')
    kubectl exec -n <namespace> ${SLURMCTLD_POD} -c slurmctld -- scontrol reconfigure
    ```
