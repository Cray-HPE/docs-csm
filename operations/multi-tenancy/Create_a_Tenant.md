# Creating a Tenant

- [Overview](#overview)
- [TAPMS CRD](#tapms-crd)
- [Apply the TAPMS CR](#apply-the-tapms-cr)
- [`slurm` operator CRD](#slurm-operator-crd)
- [Apply the `slurm` operator CR](#apply-the-slurm-operator-cr)

## Overview

This page provides information about how to create a tenant. This procedure involves creating a Custom Resource Definition (CRD) and then applying the Custom Resource (CR),
for both `tapms` and the `slurm` operator.

## TAPMS CRD

Tenant provisioning is handled in a declarative fashion, by creating a CR with the specification for the tenant.

- (`ncn-mw#`) The full schema is available by executing the following command:

    ```bash
    kubectl get customresourcedefinitions.apiextensions.k8s.io tenants.tapms.hpe.com  -o yaml
    ```

- An example of a tenant custom resource (CR):

    ```yaml
    apiVersion: tapms.hpe.com/v1alpha2
    kind: Tenant
    metadata:
      name: vcluster-blue
    spec:
      childnamespaces:
      - slurm
      - user
      tenantname: vcluster-blue
      tenantresources:
      - enforceexclusivehsmgroups: true
        hsmgrouplabel: blue
        type: compute
        xnames:
        - x3000c0s19b1n0
        - x3000c0s19b3n0
      - enforceexclusivehsmgroups: true
        hsmgrouplabel: blue
        type: application
        xnames:
        - x3000c0s32b0n0
    ```

## Apply the TAPMS CR

- (`ncn-mw#`) Once the CR has been crafted for the tenant, the following command will begin the provisioning of the tenant:

    > All tenants should be applied in the `tenants` namespace.

    ```bash
    kubectl apply -n tenants -f <tenant.yaml>
    ```

    Example output:

    ```text
    tenant.tapms.hpe.com/vcluster-blue created
    ```

- (`ncn-mw#`) It can take up to a minute for `tapms` to fully create the tenant. The following command can be used to monitor the status of the tenant:

    ```bash
    kubectl get tenant -n tenants vcluster-blue -o yaml
    ```

    Example output:

    ```yaml
    apiVersion: tapms.hpe.com/v1alpha2
    kind: Tenant
    metadata:
      annotations:
        kopf.zalando.org/last-handled-configuration: |
          {"spec":{"childnamespaces":["slurm","user"],"state":"Deployed","tenantname":"vcluster-blue","tenantresources":[{"enforceexclusivehsmgroups":true,"hsmgrouplabel":"blue","type":"compute","xnames":["x3000c0s19b1n0","x3000c0s19b3n0"]},{"enforceexclusivehsmgroups":true,"hsmgrouplabel":"blue","type":"application","xnames":["x3000c0s32b0n0"]}]}}
        kubectl.kubernetes.io/last-applied-configuration: |
          {"apiVersion":"tapms.hpe.com/v1alpha2","kind":"Tenant","metadata":{"annotations":{"kopf.zalando.org/last-handled-configuration":"{\"spec\":{\"childnamespaces\":[\"user\",\"slurm\"],\"state\":\"Deployed\",\"tenantname\":\"vcluster-test1\",\"tenantresources\":[{\"enforceexclusivehsmgroups\":true,\"hsmgrouplabel\":\"test1\",\"type\":\"compute\",\"xnames\":[\"x3000c0s19b1n0\",\"x3000c0s19b3n0\"]}]}}\n"},"finalizers":["tapms.hpe.com/finalizer"],"generation":3,"name":"vcluster-blue","namespace":"tenants"},"spec":{"childnamespaces":["slurm","user"],"state":"Deployed","tenantname":"vcluster-blue","tenantresources":[{"enforceexclusivehsmgroups":true,"hsmgrouplabel":"blue","type":"compute","xnames":["x3000c0s19b1n0","x3000c0s19b3n0"]},{"enforceexclusivehsmgroups":true,"hsmgrouplabel":"blue","type":"application","xnames":["x3000c0s32b0n0"]}]}}
      creationTimestamp: "2023-05-11T14:36:12Z"
      finalizers:
      - tapms.hpe.com/finalizer
      generation: 2
      name: vcluster-blue
      namespace: tenants
      resourceVersion: "134562804"
      uid: f6ceb492-1e7b-4569-88be-f6b53bfb25fd
    spec:
      childnamespaces:
      - slurm
      - user
      state: Deployed
      tenantname: vcluster-blue
      tenantresources:
      - enforceexclusivehsmgroups: true
        hsmgrouplabel: blue
        type: compute
        xnames:
        - x3000c0s19b1n0
        - x3000c0s19b3n0
      - enforceexclusivehsmgroups: true
        hsmgrouplabel: blue
        type: application
        xnames:
        - x3000c0s32b0n0
    status:
      childnamespaces:
      - vcluster-blue-slurm
      - vcluster-blue-user
      tenantresources:
      - enforceexclusivehsmgroups: true
        hsmgrouplabel: blue
        type: compute
        xnames:
        - x3000c0s19b1n0
        - x3000c0s19b3n0
      - enforceexclusivehsmgroups: true
        hsmgrouplabel: blue
        type: application
        xnames:
        - x3000c0s32b0n0
      uuid: f6ceb492-1e7b-4569-88be-f6b53bfb25fd
    ```

- (`ncn-mw#`) The `cray` command can now be used to display the HSM group:

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
    ids = [ "x3000c0s19b1n0", "x3000c0s19b3n0", "x3000c0s32b0n0",]
    ```

- (`ncn-mw#`) The following command can now be used to display the namespace tree structure for the tenant:

    ```bash
    kubectl hns tree tenants
    ```

    Example output:

    ```text
    tenants
    └── [s] vcluster-blue
        ├── [s] vcluster-blue-slurm
        └── [s] vcluster-blue-user
    ```

## `slurm` operator CRD

Slurm provisioning is similar to tenant creation, using a CR.

(`ncn-mw#`) To see all possible configuration settings for the custom resource, run this command:

```bash
kubectl get crd slurmclusters.wlm.hpe.com -o yaml
```

Create a custom resource describing the Slurm tenant. For example, the following `mycluster.yaml` file
describes a Slurm tenant named `mycluster` within a `vcluster-blue` TAPMS tenant:

```yaml
apiVersion: "wlm.hpe.com/v1alpha1"
kind: SlurmCluster
metadata:
  name: mycluster
  namespace: vcluster-blue-slurm
spec:
  tapmsTenantName: vcluster-blue
  tapmsTenantVersion: v1alpha2
  slurmctld:
    image: cray/cray-slurmctld:1.2.5
    ip: 10.253.124.100
    host: mycluster-slurmctld
    backupIP: 10.253.124.101
    backupHost: mycluster-slurmctld-backup
    livenessProbe:
      enabled: true
      initialDelaySeconds: 120
      periodSeconds: 30
      timeoutSeconds: 5
  slurmdbd:
    image: cray/cray-slurmdbd:1.2.5
    ip: 10.253.124.102
    host: mycluster-slurmdbd
    backupIP: 10.253.124.103
    backupHost: mycluster-slurmdbd-backup
    livenessProbe:
      enabled: true
      initialDelaySeconds: 3600
      periodSeconds: 30
      timeoutSeconds: 5
  munge:
    image: cray/munge-munge:1.2.0
  sssd:
    image: cray/cray-sssd:1.1.0
  config:
    image: cray/cray-slurm-config:1.1.2
    hsmGroup: blue
  pxc:
    enabled: true
    image:
      repository: cray/cray-pxc
      tag: 0.1.0
    data:
      storageClassName: k8s-block-replicated
      accessModes:
        - ReadWriteOnce
      storage: 20Gi
    livenessProbe:
      initialDelaySeconds: 300
      periodSeconds: 10
      timeoutSeconds: 5
    resources:
      requests:
        cpu: 100m
        memory: 4Gi
      limits:
        cpu: 200m
        memory: 16Gi
    backup:
      image:
        repository: cray/cray-pxc-backup
        tag: 0.1.0
      data:
        storageClassName: k8s-block-replicated
        accessModes:
          - ReadWriteOnce
        storage: 10Gi
      # Backup daily at 9:10PM (does not conflict with other CSM DB backups)
      schedule: "10 21 * * *"
      keep: 3
      resources:
        requests:
          cpu: 100m
          memory: 4Gi
        limits:
          cpu: 200m
          memory: 16Gi
    haproxy:
      image:
        repository: cray/cray-pxc-haproxy
        tag: 0.1.0
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 200m
          memory: 512Mi
```

## Apply the `slurm` operator CR

(`ncn-mw#`) To create the tenant and deploy Slurm resources, apply the tenant file with `kubectl`:

```bash
kubectl apply -f <cluster>.yaml
```

Once the tenant has been created, the Ansible configuration for compute and application nodes must be
updated to use the tenant-specific configuration. To do this, create a `group_vars/<hsmgroup>/slurm.yaml`
file in the `slurm-config-management` VCS repository with the following content:

```yaml
munge_vault_path: slurm/<namespace>/<name>/munge
slurm_conf_url: https://rgw-vip.local/wlm/<namespace>/<name>/
```

Where `<namespace>` and `<name>` match the namespace and name of the Slurm tenant resource created above. This
will configure nodes in that tenant with the Munge key and Slurm configuration files created for that tenant.
