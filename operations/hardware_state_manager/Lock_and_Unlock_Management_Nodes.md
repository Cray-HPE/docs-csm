## Lock and Unlock Management Nodes

The ability to ignore non-compute nodes (NCNs) is turned off by default. Management nodes and NCNs are also not locked by default. The administrator must lock the NCNs to prevent unwanted actions from affecting these nodes.

This section only covers using locks with the Hardware State Manager (HSM). For more information
on ignoring nodes, refer to the following sections:

   * Firmware Action Service (FAS): See [Ignore Node within FAS](../firmware/FAS_Admin_Procedures.md#ignore).
   * Cray Advanced Platform Monitoring and Control (CAPMC): See [Ignore Nodes with CAPMC](../power_management/Ignore_Nodes_with_CAPMC.md)

The following actions can be prevented when a node is locked.
   * Firmware upgrades with FAS
   * Power off operations with CAPMC
   * Reset operations with CAPMC

Doing any of these actions by accident will shut down a management node. If the node is a Kubernetes master or worker
node, this can have serious negative effects on system operations. If a single node is taken down by mistake, it is
possible that services will recover. If all management nodes are taken down, or all Kubernetes worker nodes are taken down by mistake, the system must be restarted.

After critical nodes are locked, power/reset (CAPMC) or firmware (FAS) operations cannot affect the nodes unless
they are unlocked. For example, any locked node that is included in a list of nodes to be reset will result in a
failure.

### Topics:

   * [When To Lock Management Nodes](#when-to-lock-management-nodes)
   * [When To Unlock Management Nodes](#when-to-unlock-management-nodes)
   * [How To Lock Management Nodes](#how-to-lock-management-nodes)
   * [How To Unlock Management Nodes](#how-to-unlock-management-nodes)


<a name="when-to-lock-management-nodes"></a>

### When To Lock Management Nodes

To best protect system health, NCNs should be locked as early as possible in the install/upgrade cycle. The later in the process, the more risk there is of accidentally taking down a critical node. NCN locking must be done after Kubernetes is running and the HSM service is operational.

Check whether HSM is running with the following command:

```bash
ncn# kubectl -n services get pods | grep smd
cray-smd-848bcc875c-6wqsh           2/2     Running    0          9d
cray-smd-848bcc875c-hznqj           2/2     Running    0          9d
cray-smd-848bcc875c-tp6gf           2/2     Running    0          6d22h
cray-smd-init-2tnnq                 0/2     Completed  0          9d
cray-smd-postgres-0                 2/2     Running    0          19d
cray-smd-postgres-1                 2/2     Running    0          6d21h
cray-smd-postgres-2                 2/2     Running    0          19d
cray-smd-wait-for-postgres-4-7c78j  0/3     Completed  0          9d
```

The `cray-smd` pods need to be in the 'Running' state, except for `cray-smd-init` and
`cray-smd-wait-for-postgres` which should be in 'Completed' state.

<a name="when-to-unlock-management-nodes"></a>

### When To Unlock Management Nodes

Any time a management NCN has to be power cycled, reset, or have its firmware updated
it will first need to be unlocked. After the operation is complete the targeted nodes
should once again be locked.

<a name="how-to-lock-management-nodes"></a>

### How To Lock Management Nodes

Use the `cray hsm locks lock` command to perform locking.

***NOTE: When locking NCNs, you must lock their NodeBMCs as well.***

#### To lock all nodes (and their BMCs) with the _Management_ role.

   The *processing-model rigid* parameter means that the operation must succeed on all
   target nodes or the entire operation will fail.

1. Lock the management nodes
   ```bash
   ncn# cray hsm locks lock create --role Management --processing-model rigid
   Failure = []

   [Counts]
   Total = 8
   Success = 8
   Failure = 0

   [Success]
   ComponentIDs = [ "x3000c0s5b0n0", "x3000c0s4b0n0", "x3000c0s7b0n0", "x3000c0s6b0n0", "x3000c0s3b0n0", "x3000c0s2b0n0", "x3000c0s9b0n0", "x3000c0s8b0n0",]
   ```
   
1. Lock the NodeBMCs of those management nodes
   ```bash
   ncn# cray hsm locks lock create --component-ids $(cray hsm state components list --role management --type node --format json | jq '.Components[].ID' | sed 's/n[0-9]*//;s/"//g' | tr '\n' ',' | sed 's/.$//')
   Failure = []

   [Counts]
   Total = 8
   Success = 8
   Failure = 0

   [Success]
   ComponentIDs = [ "x3000c0s5b0", "x3000c0s4b0", "x3000c0s7b0", "x3000c0s6b0", "x3000c0s3b0", "x3000c0s2b0", "x3000c0s9b0", "x3000c0s8b0",]
   ```

#### To lock single nodes or lists of specific nodes (and their BMCs).

1. Lock the management nodes
   ```bash
   ncn# cray hsm locks lock create --role Management --component-ids x3000c0s6b0n0 --processing-model rigid
   Failure = []

   [Counts]
   Total = 1
   Success = 1
   Failure = 0

   [Success]
   ComponentIDs = [ "x3000c0s6b0n0",]
   ```

1. Lock the BMC of those nodes
   ```bash
   // Remove 'n0' from all of the xnames to get a list of the NodeBMCs that need to be locked.
   ncn# cray hsm locks lock create --component-ids x3000c0s6b0 --processing-model rigid
   Failure = []

   [Counts]
   Total = 1
   Success = 1
   Failure = 0

   [Success]
   ComponentIDs = [ "x3000c0s6b0",]
   ```

<a name="how-to-unlock-management-nodes"></a>

### How To Unlock Management Nodes

Use the `cray hsm locks unlock` command to perform unlocking.

***NOTE: When unlocking NCNs, you must unlock their NodeBMCs as well.***

#### To unlock all nodes (and their BMCs) with the _Management_ role.

1. Unlock the management nodes
   ```bash
   ncn# cray hsm locks unlock create --role Management --processing-model rigid
   Failure = []

   [Counts]
   Total = 8
   Success = 8
   Failure = 0

   [Success]
   ComponentIDs = [ "x3000c0s7b0n0", "x3000c0s6b0n0", "x3000c0s3b0n0", "x3000c0s2b0n0", "x3000c0s9b0n0", "x3000c0s8b0n0", "x3000c0s5b0n0", "x3000c0s4b0n0",]
   ```

1. Unlock the BMCs of those management nodes
   ```bash
   ncn# cray hsm locks unlock create --component-ids $(cray hsm state components list --role management --type node --format json | jq '.Components[].ID' | sed 's/n[0-9]*//;s/"//g' | tr '\n' ',' | sed 's/.$//')
   Failure = []

   [Counts]
   Total = 8
   Success = 8
   Failure = 0

   [Success]
   ComponentIDs = [ "x3000c0s5b0", "x3000c0s4b0", "x3000c0s7b0", "x3000c0s6b0", "x3000c0s3b0", "x3000c0s2b0", "x3000c0s9b0", "x3000c0s8b0",]
   ```

#### To unlock single or lists of specific nodes (and their BMCs).

1. Unlock the management nodes
   ```bash
   ncn# cray hsm locks unlock create --role Management --component-ids x3000c0s6b0n0 --processing-model rigid
   Failure = []

   [Counts]
   Total = 1
   Success = 1
   Failure = 0

   [Success]
   ComponentIDs = [ "x3000c0s6b0n0",]
   ```
   
1. Unlock the BMCs of those management nodes
   ```bash
   // Remove 'n0' from all of the xnames to get a list of the NodeBMCs that need to be locked.
   ncn# cray hsm locks unlock create --component-ids x3000c0s6b0 --processing-model rigid
   Failure = []

   [Counts]
   Total = 1
   Success = 1
   Failure = 0

   [Success]
   ComponentIDs = [ "x3000c0s6b0",]
   ```

