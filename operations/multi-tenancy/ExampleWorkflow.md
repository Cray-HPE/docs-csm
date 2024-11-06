# Example Workflow

* [Overview](#overview)
* [Configuration](#configuration)
    * [Tenant Configuration](#tenant-configuration)
        * [Tenant Names](#tenant-names)
        * [Tenant API version](#tenant-api-version)
    * [`SlurmCluster` Configuration](#slurmcluster-configuration)
        * [`SlurmCluster` Names](#slurmcluster-names)
        * [`SlurmCluster` IP Addresses](#slurmcluster-ip-addresses)
        * [`SlurmCluster` API version](#slurmcluster-api-version)
        * [`SlurmCluster` Configurable Values](#slurmcluster-configurable-values)
        * [`SlurmCluster` Version Numbers](#slurmcluster-version-numbers)
    * [`SlurmCluster` Slurm configuration](#slurmcluster-slurm-configuration)
        * [`SlurmCluster` Slingshot VNI Allocation](#slurmcluster-slingshot-vni-allocation)
        * [`SlurmCluster` Partitions and Nodes](#slurmcluster-partitions-and-nodes)
        * [`SlurmCluster` Secrets (for `nonroot` users)](#slurmcluster-secrets-for-nonroot-users)
    * [USS Configuration](#uss-configuration)
* [Updates](#updates)
* [Step-by-Step Guide](#step-by-step-guide)
    * [Create and apply tenant configuration file](#create-and-apply-tenant-configuration-file)
    * [Create and apply the `SlurmCluster` configuration file](#create-and-apply-the-slurmcluster-configuration-file)
    * [Edit and apply Slurm configuration file](#edit-and-apply-slurm-configuration-file)
    * [Edit Slurm configuration file `sssd.conf`](#edit-slurm-configuration-file-sssdconf)
    * [Configure USS group variables](#configure-uss-group-variables)
    * [Create BOS session template](#create-bos-session-template)
    * [Create CFS configuration](#create-cfs-configuration)
    * [Boot and Run](#boot-and-run)
* [Status and Troubleshooting](#status-and-troubleshooting)
    * [Tenant command examples](#tenant-command-examples)
    * [`SlurmCluster` command examples](#slurmcluster-command-examples)
    * [HSM command examples](#hsm-command-examples)
    * [HNS command example](#hns-command-example)
* [Upgrade all tenants after a Slurm upgrade](#upgrade-all-tenants-after-a-slurm-upgrade)
* [Appendices](#appendices)
    * [Appendix A - `Development` tenant](#appendix-a---development-tenant)
    * [Appendix B - `Development SlurmCluster`](#appendix-b---development-slurmcluster)
    * [Appendix C - Slurm configuration](#appendix-c---slurm-configuration)
    * [Appendix D - USS group variables](#appendix-d---uss-group-variables)

## Overview

A tenant is a collection of nodes that is dedicated to one particular set of users on an HPE Cray EX system running CSM.
This guide is intended to provide a comprehensive set of instructions for a system administrator to configure, deploy, and run applications on, one or two tenants.

In this document we provide examples for a hypothetical system called `Development`, which has two tenants, and each tenant has a `SlurmCluster`.

Note that this document reflects the current state of the Multi-Tenancy feature.  For example, VNI blocks must be manually configured today, but they will be automatically configured in a future release.

Here are the steps required:

* Configure desired tenants and `SlurmClusters`
* Deploy each tenant and its `SlurmCluster`
* Configure each `SlurmCluster's` `slurm.conf` and `sssd.conf`
* Make any required changes (e.g. `VNIs`) to primary (`user` namespace) `slurm.conf`
* Configure USS group variables for all tenants
* Create one BOS session template for all tenants
* Create one CFS configuration for all tenants
* Boot nodes into tenants
* In each tenant, login to UAN (if available), or any Compute node
* In each tenant, launch Slurm jobs - both commands and applications

## Configuration

This section provides additional information on the configuration necessary to fully setup a tenant.

### Tenant Configuration

Tenants are created and configured by creating a tenant custom resource definition in the form of a `yaml` file.
For more information see [Create A Tenant](./Create_a_Tenant.md)

For the purposes of this guide, the tenant configuration settings are made in each tenant's configuration file, e.g. `devten01a.yaml`.

#### Tenant Names

* Choose your naming convention for each system and tenant
* Example:
    * system `Development`
    * two tenants `devten01a` and `devten02a`
    * future iterations might use suffix `01b`, `01c`, etc

* Example of these settings in configuration file `devten01a.yaml`:

    ```yaml
    apiVersion: tapms.hpe.com/v1alpha3
    kind: Tenant
    metadata:
      name: devten01a
    spec:
      childnamespaces:
      - slurm
      - user
      tenantname: vcluster-devten01a
      tenantkms:
        enablekms: true
      tenanthooks: []
      tenantresources:
      - enforceexclusivehsmgroups: true
        hsmgrouplabel: devten01a
        type: compute
        xnames:
        - x1000c0s0b0n0
    ```

#### Tenant API Version

* Tenant `apiVersion` should use the latest available in the CSM release, e.g. `v1alpha3` for CSM 1.6

### `SlurmCluster` Configuration

These configuration settings are made:

* In each `SlurmCluster's` configuration file, e.g. `devcls01a.yaml`
* In each `SlurmCluster's` `/etc/slurm/slurm.conf` file (in each `slurmctld` pod)

#### `SlurmCluster` Names

* Choose your naming convention for each system and `SlurmCluster`
* Example:
    * system `Development`
    * `SlurmClusters` `devcls01a` and `devcls02a`
    * future iterations might use suffix `01b`, `01c`, etc
* **Name length limitation**:
    * longer names are automatically generated from `SlurmCluster` name
    * for example, `devcls01a-slurmdb` (16 characters)
    * name length limitation is 22 characters

* Example of settings in configuration file `devcls01a.yaml`:

    ```yaml
    namespace: vcluster-devten01a-slurm
    tapmsTenantName: vcluster-devten01a
    hsmGroup: devten01a
    ```

#### `SlurmCluster` IP Addresses

**`IMPORTANT`** Each High-Speed Network (HSN) IP address must be unique, within all the `SlurmClusters` on any one system.

* These HSN IP addresses are assigned in the USS configuration, below
    * **You will need to know the base HSN IP address for each system**
* Four HSN IP addresses are used in each `SlurmCluster`
* Example:
    * System `Development` base HSN IP address 10.156.0.0
    * Primary `SlurmCluster` (`user` namespace) uses 10.156.12.100, .101, .102, .103
    * First tenant `SlurmCluster` (`vcluster-devten01-slurmdb` namespace) will use 10.156.12.104, .105, .106, .107
    * Second tenant `SlurmCluster` (`vcluster-devten02-slurmdb` namespace) will use 10.156.12.108, .109, .110, .111

#### `SlurmCluster` API version

* `SlurmCluster` `apiVersion` must match Slurm release (for example `v1alpha1`)

#### `SlurmCluster` Configurable Values

* Settings for `cpu` and `memory` and `initialDelaySeconds` are shown in the example file `devcls01a.yaml`, below
* These settings were provided by the WLM team, who should be consulted for any changes

#### `SlurmCluster` Version Numbers

* Version numbers are shown in the example file `devcls01a.yaml`, below
* The version numbers must match the versions of these products on the system

* Example:

    ```yaml
    - cray/cray-slurmctld:1.6.1
    - cray/cray-slurmdbd:1.6.1
    - cray/munge-munge:1.5.0
    - cray/cray-sssd:1.4.0
    - cray/cray-slurm-config:1.3.0
    ```

### `SlurmCluster` Slurm configuration

These configuration settings are made in each `SlurmCluster's` `/etc/slurm/slurm.conf` file (in each `slurmctld` pod)

#### `SlurmCluster` Slingshot VNI Allocation

**`IMPORTANT`** Each block of HPE Slingshot `VNIs` on the High-Speed Network (HSN) must not overlap with other blocks on the same system.

* Note that there is one `/etc/slurm/slurm.conf` file in each tenant's `SlurmCluster`
* Example with no tenants:
    * For primary `user` namespace:
        * `SwitchType=switch/hpe_slingshot`
        * `SwitchParameters=vnis=1025-65535`
* Example with one tenant:
    * For primary `user` namespace:
        * `SwitchType=switch/hpe_slingshot`
        * `SwitchParameters=vnis=1025-32767`
    * For `vcluster-devten01a-slurm` namespace:
        * `SwitchType=switch/hpe_slingshot`
        * `SwitchParameters=vnis=32768-65535`
* Example with two tenants:
    * For primary `user` namespace:
        * `SwitchType=switch/hpe_slingshot`
        * `SwitchParameters=vnis=1025-32767`
    * For `vcluster-devten01a-slurm` namespace:
        * `SwitchType=switch/hpe_slingshot`
        * `SwitchParameters=vnis=32868-57353`
    * For `vcluster-devten02a-slurm` namespace:
        * `SwitchType=switch/hpe_slingshot`
        * `SwitchParameters=vnis=57354-65535`

#### `SlurmCluster` Partitions and Nodes

The general advice to tailor the compute node configuration for each tenant is to look at the `slurm.conf` for the primary (`user` namespace) Slurm instance.
Borrow the `NodeSet`, `PartitionName`, and `NodeName` directives that apply to each tenant.

* In this example, we have 'moved' two Compute nodes to the `slurm.conf` in namespace `vcluster-devten01a-slurm`.

    ```ini
    # PARTITIONS
    NodeSet=Compute Feature=Compute
    PartitionName=workq Nodes=Compute MaxTime=INFINITE State=UP OverSubscribe=EXCLUSIVE
    # BEGIN COMPUTE NODES
    NodeName=nid[001002-001003] Sockets=2 CoresPerSocket=64 ThreadsPerCore=2 RealMemory=456704 Feature=Compute
    ```

#### `SlurmCluster` Secrets (for `nonroot` users)

These configuration settings are made in each `SlurmCluster's` `/etc/sssd/sssd.conf` file (in each `slurmctld` pod)
You should not need to create or edit the `sssd.conf` file.
Simply clone that file from the primary `SlurmCluster` (`user` namespace) to each tenant namespace.

### USS Configuration

These changes are made to the `uss-config-management` git repo.
Tenants are disambiguated by their HSM group name (for example `hsmgrouplabel` `"devten01a"` in `devten01a.yaml`, and `hsmGroup` `"devten01a"` in `devcls01a.yaml`).
All tenants can be booted and configured with a single CFS configuration that contains the appropriate git commit ID in the USS layers.

* Example: `group_vars/devten01a/slurm.yml`

    ```yaml
    munge_vault_path: secret/slurm/vcluster-devten01a-slurm/devcls01a/munge
    slurm_conf_url: https://rgw-vip.local/wlm/vcluster-devten05-slurm/devcls01a/
    slurmd_options: "--conf-server 10.156.124.104,10.156.124.105"
    ```

* Example:  `group_vars/devten02a/slurm.yml`

    ```yaml
    munge_vault_path: secret/slurm/vcluster-devten02a-slurm/devcls02a/munge
    slurm_conf_url: https://rgw-vip.local/wlm/vcluster-devten02a-slurm/devcls02a/
    slurmd_options: "--conf-server 10.156.124.108,10.156.124.109"
    ```

## Updates

After initial creation, the `SlurmCluster` resource may be updated with new
settings. This is useful to correct errors with the initial deployment, or
to update to new Slurm versions.

1. (`ncn-mw#`) Edit the `SlurmCluster` file (For example, `devcls01a.yaml`).
1. (`ncn-mw#`) Apply the changes:

   ```bash
   kubectl apply -f devcls01a.yaml
   ```

1. (`ncn-mw#`) The Slurm operator will update the relevant Kubernetes resources
   to reflect the new configuration.

For example, if a new version of Slurm is installed on the system, the tenant
can update to the new Slurm version by setting new container versions in the
`SlurmCluster` file and applying the changes.

## Step-by-Step Guide

Legend for these examples:

* `devten01a.yaml` - configuration file for tenant `devten01a`
* `devcls01a.yaml` - configuration file for `SlurmCluster` `devcls01a`

### Create and apply tenant configuration file

Filename:  `devten01a.yaml`

1. (`ncn-mw#`) Make sure tenant name is not already in use:

    ```bash
    kubectl get tenant -n tenants -o yaml vcluster-devten01a
    ```

1. (`ncn-mw#`) Make sure HSM group is not already in use:

    ```bash
    cray hsm groups describe devten01a
    ```

1. (`ncn-mw#`) Create your `tenant.yaml` file, and apply it:
    * See Appendix A for an example

    ```bash
    vi devten01a.yaml
    kubectl apply -n tenants -f devten01a.yaml
    ```

1. (`ncn-mw#`) Wait for 'Deploying' state to become 'Deployed':

    ```bash
    kubectl get tenant -n tenants -o yaml vcluster-devten01a
    ```

1. (`ncn-mw#`) Confirm HSM group:

    ```bash
    cray hsm groups describe devten01a
    ```

Repeat this step as needed for additional tenants.

### Create and apply the `SlurmCluster` configuration file

Filename:  `devcls01a.yaml`

1. (`ncn-mw#`) Make sure cluster name is not already in use:

    ```bash
    kubectl get pods -A | grep vcluster-devcls01a-slurm
    ```

1. (`ncn-mw#`) Create your `cluster.yaml` file, and apply it:
    * See Appendix B for an example

    ```bash
    vi devcls01a.yaml
    kubectl apply -f devcls01a.yaml
    ```

1. (`ncn-mw#`) Wait for pods to initialize:

    ```bash
    kubectl get pods -A | grep vcluster-devten01a-slurm
    ```

Repeat this step as needed for additional `SlurmClusters`.

### Edit and apply Slurm configuration file

``SlurmCluster``:  `devcls01a`
Filename:  `/etc/slurm/slurm.conf`

1. (`ncn-mw#`) Get the running configuration:

    ```bash
    kubectl get configmap -n vcluster-devten01a-slurm devcls01a-slurm-conf -o yaml > devcls01a-slurm-conf.yaml
    ```

1. (`ncn-mw#`) Extract the `slurm.conf`:

    ```bash
    yq r devcls01a-slurm-conf.yaml 'data."slurm.conf"' > slurm.conf
    ```

1. (`ncn-mw#`) Edit the `slurm.conf`:
    * See Appendix C

    ```bash
    vi slurm.conf
    ```

1. (`ncn-mw#`) Update the configuration:

    ```bash
    yq w -i devcls01a-slurm-conf.yaml 'data."slurm.conf"' "$(cat slurm.conf)"
    ```

1. (`ncn-mw#`) Apply the configuration:

    ```bash
    kubectl apply -f devcls01a-slurm-conf.yaml
    ```

1. (`ncn-mw#`) Look up the pod for the tenant `slurmcluster`:

    ```bash
    SLURMCTLD_POD=$(kubectl get pod -n vcluster-devten01a-slurm -lapp.kubernetes.io/name=slurmctld -o name)
    ```

1. (`ncn-mw#`) Reconfigure:

    ```bash
    kubectl exec -n vcluster-devten01a-slurm ${SLURMCTLD_POD} -c slurmctld -- scontrol reconfigure
    ```

Repeat this step as needed for additional `SlurmClusters`.

### Edit Slurm configuration file `sssd.conf`

`SlurmCluster`:  `devcls01a`
Filename:  `/etc/sssd/sssd.conf`

1. (`ncn-mw#`) Get the `user` namespace `sssd.conf` so it can be cloned:

    ```bash
    kubectl get configmap -n user sssd-conf -o jsonpath='{.data.sssd\.conf}' > sssd.conf
    ```

1. (`ncn-mw#`) Delete an existing `stub` file in the tenant, if present:

    ```bash
    kubectl delete secret -n vcluster-devten01a-slurm devcls01a-sssd-conf
    ```

1. (`ncn-mw#`) Clone the `user` namespace file into the tenant:

    ```bash
    kubectl create secret generic -n vcluster-devten01a-slurm noclus01a-sssd-conf --from-file sssd.conf
    ```

1. (`ncn-mw#`) Restart the tenant's `slurmctld` pods:

    ```bash
    kubectl rollout restart deployment -n vcluster-devten01a-slurm devcls01a-slurmctld devcls01a-slurmctld-backup
    ```

1. (`ncn-mw#`) Restart the tenant's `slurmdbd` pods:

    ```bash
    kubectl rollout restart deployment -n vcluster-devten01a-slurm devcls01a-slurmdbd devcls01a-slurmdbd-backup
    ```

1. (`ncn-mw#`) Check for all restarted pods to be in Running state:

    ```bash
    kubectl get pods -A | egrep 'slurmctld|slurmdbd'
    ```

Repeat this step as needed for additional `SlurmClusters`.

### Configure USS group variables

Filename:  `group_vars/devten01a/slurm.yml`

1. (`ncn-mw#`) Clone the USS repository:

    ```bash
    git clone https://api-gw-service-nmn.local/vcs/cray/uss-config-management.git
    ```

1. (`ncn-mw#`) Go to repo:

    ```bash
    cd uss-config-management
    ```

1. (`ncn-mw#`) Check out integration branch (1.1.0 shown here):

    ```bash
    git checkout integration-1.1.0
    ```

1. (`ncn-mw#`) Create subdirectory for tenant:

    ```bash
    mkdir group_vars/devten01a
    ```

1. (`ncn-mw#`) Edit the file `group_vars/devten01a/slurm.yml`
    * See an appropriate example in Appendix D

1. (`ncn-mw#`) Add the new file:

    ```bash
    git add group_vars/devten01a/slurm.yml
    ```

1. (`ncn-mw#`) Commit the new file:

    ```bash
    git commit -am "descriptive comment"
    ```

1. (`ncn-mw#`) Push to integration branch (1.1.0 shown here):

    ```bash
    git push origin integration-1.1.0
    ```

1. (`ncn-mw#`) Remember the first commit ID in the output:

    ```bash
    git log -a |cat
    ```

    Repeat this step as needed for additional tenants.

### Create BOS session template

Note that you will need one template for each node type (UAN,Compute) and architecture (X86,ARM) in the tenants.
You can use a single BOS session template for many tenants of the same node type and architecture.

1. (`ncn-mw#`) Look up the name of the default template(s) for tenants (for example X86 Compute) and save as JSON file(s):

    ```bash
    cray bos sessiontemplates describe --format json ssi-compute-cr_2024.x86_64-cr_2024_1 > ssi-compute-cr_2024.x86_64-cr_2024_1.json
    ```

1. (`ncn-mw#`) Make a copy of the default template:

    ```bash
    cp ssi-compute-cr_2024.x86_64-cr_2024_1.json ssi-compute-cr_2024.x86_64-cr_2024_1-tenants.json
    ```

* Edit the new copy:
    * Delete block of lines starting with `enable_cfs:`, `name:`, and `tenant:` and remove the comma from the preceding line
    * Change the name of the CFS configuration in the BOS session template to add a `-tenants` suffix, as seen in the next section

1. (`ncn-mw#`) Upload the new template, specifying the filename and the name of the new template:

    ```bash
    cray bos sessiontemplates create --format json --file ssi-compute-cr_2024.x86_64-cr_2024_1-tenants.json ssi-compute-cr_2024.x86_64-cr_2024_1-tenants
    ```

Repeat this step as needed for different node types and architectures.

### Create CFS configuration

Note that you will need one configuration for each node type (UAN,Compute) in the tenant.
You can use a single BOS session template for many tenants of the same node type and architecture.

1. (`ncn-mw#`) Save the default configuration as a JSON file:

    ```bash
    cray cfs configurations describe --format json ssi-compute-cr_2024-cr_2024_1 > ssi-compute-cr_2024-cr_2024_1.json
    ```

1. (`ncn-mw#`) Make a copy of the default JSON file:

    ```bash
    cp ssi-compute-cr_2024-cr_2024_1.json ssi-compute-cr_2024-cr_2024_1-tenants.json
    ```

* Edit the new copy:
    * Delete lines starting with `lastUpdated`:
    * Delete the last instance in the file of name: and remove the comma from the preceding line
    * Be SURE to replace the commit ID for each JSON block that refers to `uss-config-management.git`; you will use the commit ID from "git log" command in the earlier step that created the USS `group_vars` file

1. (`ncn-mw#`) Upload the new configuration, specifying the filename and the name of the new configuration:

    ```bash
    cray cfs configurations update --file ssi-compute-cr_2024-cr_2024_1-tenants.json ssi-compute-cr_2024-cr_2024_1-tenants
    ```

Repeat this step as needed for different node types and architectures.

### Boot and Run

* BOS and CFS:
    * You will need one or more BOS session template(s) for your tenant, see above
    * The BOS session template(s) refer to CFS configuration(s), see above

1. (`ncn-mw#`) Boot Compute nodes for a node architecture in tenant:

    ```bash
    cray bos sessions create --template-name ssi-compute-cr_2024.x86_64-cr_2024_1-tenants --operation boot --limit x9000c1s0b1n0,x9000c1s0b1n1
    ```

After CFS completes, login to either a tenant UAN (if available), or tenant Compute.

1. (`ncn-mw#`) See what nodes are available:

    ```bash
    sinfo
    ```

1. (`ncn-mw#`) Launch a command or application:

    ```bash
    srun -N2 uname -rin
    srun -N2 ./all2all
    ```

## Status and Troubleshooting

### Tenant command examples

* (`ncn-mw#`) View a specific tenant, brief:

    ```bash
    kubectl get tenant -n tenants -o yaml vcluster-devten01a
    ```

* (`ncn-mw#`) View a specific tenant, verbose:

    ```bash
    kubectl describe tenant -n tenants vcluster-devten01a
    ```

* (`ncn-mw#`) View the logs for all tenants:

    ```bash
    TAPMS_POD=$( kubectl get pods -n tapms-operator --no-headers | awk '{print $1}' );
    kubectl logs --timestamps -n tapms-operator $TAPMS_POD
    ```

### `SlurmCluster` command examples

* (`ncn-mw#`) View the pods for all clusters:

    ```bash
    kubectl get pods -A | grep vcluster
    ```

* (`ncn-mw#`) View the pods for a specific cluster:

    ```bash
    kubectl get pods -A | grep vcluster-devten01a-slurm
    ```

* (`ncn-mw#`) View logs for a specific cluster:

    ```bash
    NAMESPACE=vcluster-devten01a-slurm;
    SLURMCTLD_POD=$( kubectl get pods -n $NAMESPACE |grep slurmctld |grep -v backup | awk '{print $1}' );
    kubectl logs --timestamps -n $NAMESPACE $SLURMCTLD_POD -c slurmctld
    ```

### HSM command examples

* (`ncn-mw#`) All HSM groups, including all tenants:

    ```bash
    cray hsm groups list --format yaml
    ```

* (`ncn-mw#`) Specific tenant:

    ```bash
    cray hsm groups describe --format yaml devten01a
    ```

### HNS command example

* (`ncn-mw#`) All tenants:

    ```bash
    kubectl hns tree tenants
    ```

## Upgrade all tenants after a Slurm upgrade

This procedure is required for each tenant, after Slurm has been upgraded on the system (for example, after using IUF to upgrade products).

You will need the configuration file that you used to create each tenant's `SlurmCluster`.
For this Slurm upgrade, there is no need to change the `SlurmCluster` name; the only change is to the Slurm version inside each tenant.

> * `SlurmCluster`: `devcls01a`
> * Filename: `devcls01a.yaml`

* (`ncn-mw#`) Edit the `SlurmCluster` configuration file:

    ```bash
    cp -p devcls01a.yaml devcls01a.yaml{,.bak}
    vi devcls01a.yaml
    ```

* (`ncn-mw#`) Double-check the differences:

    ```bash
    diff devcls01a.yaml devcls01a.yaml.bak
    ```

    Possible output:

    ```diff
    10c10
    <     image: cray/cray-slurmctld:1.7.0-slurm
    ---
    >     image: cray/cray-slurmctld:1.6.1
    21c21
    <     image: cray/cray-slurmdbd:1.7.0-slurm
    ---
    >     image: cray/cray-slurmdbd:1.6.1
    ```

* (`ncn-mw#`) Re-apply the `SlurmCluster` configuration file:

    ```bash
    kubectl apply -f devcls01a.yaml
    ```

* (`ncn-mw#`) Wait for all pods to return to Running state:

    ```bash
    kubectl get pods -A |grep vcluster
    ```

Repeat this step as needed for additional `SlurmClusters`.

## Appendices

### Appendix A - `Development` tenant

* This is filename `devten01.yaml`; complete file is shown.

    ```yaml
    apiVersion: tapms.hpe.com/v1alpha3
    kind: Tenant
    metadata:
      name: vcluster-devten01a
    spec:
      childnamespaces:
      - slurm
      - user
      tenantname: vcluster-devten01a
      tenanthooks: []
      tenantresources:
      - enforceexclusivehsmgroups: true
        hsmgrouplabel: devten01a
        type: compute
        xnames:
        - x9000c1s0b1n0
        - x9000c1s0b1n1
      - enforceexclusivehsmgroups: true
        hsmgrouplabel: devten01a
        type: application
        xnames:
        - x3000c0s29b0n0
    ```

### Appendix B - `Development` `SlurmCluster`

**`IMPORTANT`** The values for `cpu` and `memory` and `initialDelaySeconds` are recommended by the WLM team.

* This is filename `devcls01a.yaml`; complete file is shown.

    ```yaml
    apiVersion: "wlm.hpe.com/v1alpha1"
    kind: SlurmCluster
    metadata:
      name: devcls01a
      namespace: vcluster-devcls01a-slurm
    spec:
      tapmsTenantName: vcluster-devcls01a
      tapmsTenantVersion: v1alpha3
      slurmctld:
        image: cray/cray-slurmctld:1.6.1
        ip: 10.150.124.100
        host: devcls01a-slurmctld
        backupIP: 10.150.124.101
        backupHost: devcls01a-slurmctld-backup
        livenessProbe:
          enabled: true
          initialDelaySeconds: 120
          periodSeconds: 60
          timeoutSeconds: 60
      slurmdbd:
        image: cray/cray-slurmdbd:1.6.1
        ip: 10.150.124.102
        host: devcls01a-slurmdbd
        backupIP: 10.150.124.103
        backupHost: devcls01a-slurmdbd-backup
        livenessProbe:
          enabled: true
          initialDelaySeconds: 43200
          periodSeconds: 30
          timeoutSeconds: 5
      munge:
        image: cray/munge-munge:1.5.0
      sssd:
        image: cray/cray-sssd:1.4.0
      config:
        image: cray/cray-slurm-config:1.3.0
        hsmGroup: devcls01a
      pxc:
        enabled: true
        image:
          repository: cray/cray-pxc
          tag: 1.3.0
        initImage:
          repository: cray/cray-pxc-operator
          tag: 1.3.0
        configuration: |
          [mysqld]
          innodb_log_file_size=4G
          innodb_lock_wait_timeout=900
          wsrep_trx_fragment_size=1G
          wsrep_trx_fragment_unit=bytes
          log_error_suppression_list=MY-013360
        data:
          storageClassName: k8s-block-replicated
          accessModes:
            - ReadWriteOnce
          storage: 1Ti
        livenessProbe:
          initialDelaySeconds: 300
          periodSeconds: 10
          timeoutSeconds: 5
        resources:
          requests:
            cpu: "1"
            memory: 4Gi
          limits:
            cpu: "8"
            memory: 32Gi
        backup:
          image:
            repository: cray/cray-pxc-backup
            tag: 1.3.0
          data:
            storageClassName: k8s-block-replicated
            accessModes:
              - ReadWriteOnce
            storage: 512Gi
          # Backup daily at 9:10PM (does not conflict with other CSM DB backups)
          schedule: "10 21 * * *"
          keep: 3
          resources:
            requests:
              cpu: "1"
              memory: 4Gi
            limits:
              cpu: "8"
              memory: 16Gi
        haproxy:
          image:
            repository: cray/cray-pxc-haproxy
            tag: 1.3.0
          resources:
            requests:
              cpu: "1"
              memory: 128Mi
            limits:
              cpu: "16"
              memory: 512Mi
    ```

### Appendix C - Slurm configuration

First, you are responsible for divvying up the HPE Slingshot VNI space among the primary `SlurmCluster` ('user' namespace) and any tenant `SlurmClusters`.
Start with the primary `SlurmCluster`, and then configure each tenant.
Here is an example for primary and one tenant:

* This is filename `/etc/slurm/slurm.conf` for `user` namespace; partial file is shown.

    ```ini
    ...
    SwitchType=switch/hpe_slingshot
    SwitchParameters=vnis=1025-32767
    ...
    ```

* This is filename `/etc/slurm/slurm.conf` for `vcluster-devten01-slurm` namespace; partial file is shown.

    ```ini
    ...
    SwitchType=switch/hpe_slingshot
    SwitchParameters=vnis=32768-65535
    ...
    ```

Second, insert the `NodeSet`, `PartitionName`, and `NodeName` directives that apply to your tenant.
In this example on `Development`, we have two X86 Compute nodes (1002 and 1003), and one X86 UAN (`uan02`).

* This is filename `/etc/slurm/slurm.conf` for `vcluster-devten01-slurm` namespace; partial file is shown.

    ```ini
    ...
    # PARTITIONS
    NodeSet=Compute Feature=Compute
    PartitionName=workq Nodes=Compute MaxTime=INFINITE State=UP OverSubscribe=EXCLUSIVE
    # BEGIN COMPUTE NODES
    NodeName=nid[001002-001003] Sockets=2 CoresPerSocket=64 ThreadsPerCore=2 RealMemory=456704 Feature=Compute
    # END COMPUTE NODES
    NodeName=uan02 Sockets=2 CoresPerSocket=64 ThreadsPerCore=2 RealMemory=227328 Feature=Application_UAN
    ...
    ```

### Appendix D - USS group variables

* This is file `group_vars/devten01a/slurm.yml`; complete file is shown.

    ``` yaml
    munge_vault_path: secret/slurm/vcluster-devten01a-slurm/devcls01a/munge
    slurm_conf_url: https://rgw-vip.local/wlm/vcluster-devten05-slurm/devcls01a/
    slurmd_options: "--conf-server 10.156.124.104,10.156.124.105"
    ```
