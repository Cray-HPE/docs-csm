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
    apiVersion: tapms.hpe.com/v1alpha3
    kind: Tenant
    metadata:
      name: vcluster-blue
    spec:
      childnamespaces:
      - slurm
      - user
      tenantname: vcluster-blue
      tenantkms:
        enablekms: true
      tenanthooks:
      - name: blocking-hook
        url: http://10.19.12.61:6000/block
        blockingcall: true
        eventtypes:
          - UPDATE
          - DELETE
        hookcredentials:
          secretname: blocking-hook-cm
          secretnamespace: services
      - name: notify-hook
        url: http://10.19.12.61:6000
        blockingcall: false
        eventtypes:
          - UPDATE
          - DELETE
        hookcredentials:
          secretname: notify-hook-cm
          secretnamespace: services
      tenantresources:
      - enforceexclusivehsmgroups: true
        hsmgrouplabel: blue
        type: compute
        xnames:
        - x1000c0s0b0n0
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
    apiVersion: tapms.hpe.com/v1alpha3
    kind: Tenant
    metadata:
      annotations:
        kubectl.kubernetes.io/last-applied-configuration: |
          {"apiVersion":"tapms.hpe.com/v1alpha3","kind":"Tenant","metadata":{"annotations":{},"name":"vcluster-blue","namespace":"tenants"},"spec":{"childnamespaces":["slurm","user"],"tenanthooks":[{"blockingcall":true,"eventtypes":["UPDATE","DELETE"],"hookcredentials":{"secretname":"blocking-hook-cm","secretnamespace":"services"},"name":"blocking-hook","url":"http://10.19.12.61:6000/block"},{"blockingcall":false,"eventtypes":["UPDATE","DELETE"],"hookcredentials":{"secretname":"notify-hook-cm","secretnamespace":"services"},"name":"notify-hook","url":"http://10.19.12.61:6000"}],"tenantkms":{"enablekms":true},"tenantname":"vcluster-blue","tenantresources":[{"enforceexclusivehsmgroups":true,"hsmgrouplabel":"blue","type":"compute","xnames":["x1000c0s0b0n0"]}]}}
      creationTimestamp: "2023-09-27T17:14:28Z"
      finalizers:
      - tapms.hpe.com/finalizer
      generation: 8
      name: vcluster-blue
      namespace: tenants
      resourceVersion: "18509045"
      uid: 04f26622-dccb-44a1-a928-7d4750c573e7
    spec:
      childnamespaces:
      - slurm
      - user
      state: Deployed
      tenanthooks:
      - blockingcall: true
        eventtypes:
        - UPDATE
        - DELETE
        hookcredentials:
          secretname: blocking-hook-cm
          secretnamespace: services
        name: blocking-hook
        url: http://10.19.12.61:6000/block
      - blockingcall: false
        eventtypes:
        - UPDATE
        - DELETE
        hookcredentials:
          secretname: notify-hook-cm
          secretnamespace: services
        name: notify-hook
        url: http://10.19.12.61:6000
      tenantkms:
        enablekms: true
        keyname: key1
        keytype: rsa-3072
      tenantname: vcluster-blue
      tenantresources:
      - enforceexclusivehsmgroups: true
        hsmgrouplabel: blue
        type: compute
        xnames:
        - x1000c0s0b0n0
    status:
      childnamespaces:
      - vcluster-blue-slurm
      - vcluster-blue-user
      tenanthooks:
      - blockingcall: true
        eventtypes:
        - UPDATE
        - DELETE
        hookcredentials:
          secretname: blocking-hook-cm
          secretnamespace: services
        name: blocking-hook
        url: http://10.19.12.61:6000/block
      - blockingcall: false
        eventtypes:
        - UPDATE
        - DELETE
        hookcredentials:
          secretname: notify-hook-cm
          secretnamespace: services
        name: notify-hook
        url: http://10.19.12.61:6000
      tenantkms:
        keyname: key1
        keytype: rsa-3072
        publickey: '{"1":{"creation_time":"2023-09-27T17:14:50.475282593Z","name":"rsa-3072","public_key":"-----BEGIN
          PUBLIC KEY-----\nMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAyYGFfQWlJPKNiz25SAJ+\nHdsW2iENcXd1Rst0hYk5JI7h9y1enLCaSr1TkCh0sRvYu03OZSr7+crNhb4SL7mK\nXFDnkX55qKu4KcIwyz0ZAtPJJ959HlnPuL0ELglV7PIQtMqejLpQqOTU7zM5/Jh+\n++nex5SEo5BmiQGB9UQfgAORhuRI5um0DlnE/W1hHdTvprj1HfPvI+XcBOffzbPe\nK3Os/dnxeSlJ2V45fEDmgR4pCIOdPmoTaXnE/ARlsfp5riA8w0butXT+5MddGNXb\nlMfBLtlTGYPBGApuWoeMqfdgsQv6gm5m7nBT7iaJHrnFkdZVpjJKoCN/4ZEtAjUS\nVF9KL9I/KEiwSh4k4OT7MGlxPIhu7XxBMVxXNMOAo4DTOk9kdUpbgcy+W1fkv5HW\nxYElVbToSokQLiMhURZ6eaqXUcOEDpSVxsvX0oqMkZBwzJcNC3KxEDVnTJQ8VMmp\n6nmDinp4noosUJC5QbiQ8oUyg+gLXbUQUYS0DZawZ1Y3AgMBAAE=\n-----END
          PUBLIC KEY-----\n"}}'
        transitname: cray-tenant-912e5990-8fdc-46ff-b86e-11550345e737
      tenantresources:
      - enforceexclusivehsmgroups: true
        hsmgrouplabel: blue
        type: compute
        xnames:
        - x1000c0s0b0n0
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
    ids = [ "x1000c0s0b0n0", "x1000c0s1b0n0",]
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
  tapmsTenantVersion: v1alpha3
  slurmctld:
    image: cray/cray-slurmctld:1.4.0
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
    image: cray/cray-slurmdbd:1.4.0
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
    image: cray/munge-munge:1.3.0
  sssd:
    image: cray/cray-sssd:1.2.0
    sssdConf: |
      [sssd]
      config_file_version = 2
      services = nss
      domains = files
      [nss]
      [domain/files]
      id_provider = files
  config:
    image: cray/cray-slurm-config:1.1.7
    hsmGroup: blue
  pxc:
    enabled: true
    initImage:
      repository: cray/cray-pxc-operator
      tag: 1.0.1
    image:
      repository: cray/cray-pxc
      tag: 1.0.1
    configuration: |
      [mysqld]
      innodb_log_file_size=4G
      innodb_lock_wait_timeout=900
      wsrep_trx_fragment_size=1G
      wsrep_trx_fragment_unit=bytes
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
        tag: 1.0.1
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
        tag: 1.0.1
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 200m
          memory: 512Mi
```

**Note:** Container versions must be customized to the versions installed on the system

## Apply the `slurm` operator CR

(`ncn-mw#`) To create the tenant and deploy Slurm resources, apply the tenant file with `kubectl`:

```bash
kubectl apply -f <cluster>.yaml
```

Once the tenant has been created, the Ansible configuration for compute and application nodes must be
updated to use the tenant-specific configuration. To do this, create a `group_vars/<hsmgroup>/slurm.yaml`
file in the `slurm-config-management` VCS repository with the following content:

```yaml
munge_vault_path: secret/slurm/<namespace>/<name>/munge
slurm_conf_url: https://rgw-vip.local/wlm/<namespace>/<name>/
```

Where `<namespace>` and `<name>` match the namespace and name of the Slurm tenant resource created above. This
will configure nodes in that tenant with the Munge key and Slurm configuration files created for that tenant.

`Slurmctld` can be configured to run in `configless` mode. This is achieved by setting `SlurmctldParameters` value in the `slurm.conf` file.

```yaml
SlurmctldParameters=enable_configless
```

Once `configless` mode is enabled, launch `slurmd` with the `--conf-server` option to get new setting from `slurmctld`.

```bash
slurmd --conf-server <other options>
```
