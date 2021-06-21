## NCN and Management Node Locking

The ability to ignore non-compute nodes \(NCNs\) is turned off by default. Management nodes and NCNs are also not locked by default. The administrator must lock the NCNs to prevent unwanted actions from affecting these nodes.

This section only covers using locks with the Hardware State Manager \(HSM\). For more information on ignoring nodes, refer to the following sections:

-   Firmware Action Service \(FAS\): Refer to "Ignore Node within FAS".
-   Cray Advanced Platform Monitoring and Control \(CAPMC\): Refer to [Ignore Node with CAPMC](../power_management/Ignore_Nodes_with_CAPMC.md).

The following actions can be prevented when NCNs are locked.

-   Firmware upgrades with FAS
-   Power off operations with CAPMC
-   Reset operations with CAPMC

Doing any of these actions by accident will shut down an NCN. If the NCN is a Kubernetes master or worker node, this can have serious negative effects on system operations. If a single node is taken down by mistake, it is possible that services will recover. If all NCNs are taken down, or all Kubernetes workers are taken down by mistake, the system must be restarted.

After critical nodes are locked, power/reset \(CAPMC\) or firmware \(FAS\) operations cannot affect the nodes unless they are unlocked. For example, any locked node that is included in a list of nodes to be reset will result in a failure.

### When to Lock Nodes

To best protect system health, NCNs should be locked as early as possible in the install/upgrade cycle. The later in the process, the more risk there is of accidentally taking down a critical node. NCN locking must be done after Kubernetes is running and the HSM service is operational.

Check if Kubernetes and HSM are running with the following command:

```screen
linux# kubectl -n services get pods | grep smd
cray-smd-848bcc875c-6wqsh           2/2     Running    0          9d
cray-smd-848bcc875c-hznqj           2/2     Running    0          9d
cray-smd-848bcc875c-tp6gf           2/2     Running    0          6d22h
cray-smd-init-2tnnq                 0/2     Completed  0          9d
cray-smd-postgres-0                 2/2     Running    0          19d
cray-smd-postgres-1                 2/2     Running    0          6d21h
cray-smd-postgres-2                 2/2     Running    0          19d
cray-smd-wait-for-postgres-4-7c78j  0/3     Completed  0          9d
```

The cray-smd-xxx pods need to be in the Running state.

### When to Unlock Nodes

Any time a Management node or NCN has to be power cycled, reset, or have its firmware updated, it will first need to be unlocked. After the operation is complete, the targeted nodes should once again be locked.

See below for instructions and examples.

### Lock Management NCNs

Use the standard HSM CLI to perform locking.

To lock all nodes with the Management role:

```screen
linux# cray hsm locks lock create --role Management --processing-model rigid
Failure = []

[Counts]
Total = 8
Success = 8
Failure = 0

[Success]
ComponentIDs = [ "x3000c0s5b0n0", "x3000c0s4b0n0", "x3000c0s7b0n0", "x3000c0s6b0n0", "x3000c0s3b0n0", "x3000c0s2b0n0", "x3000c0s9b0n0", "x3000c0s8b0n0",]
```

To lock single nodes or lists of specific nodes:

```screen
linux# cray hsm locks lock create --role Management \
--component-ids NODE_XNAME --processing-model rigid
Failure = []

[Counts]
Total = 1
Success = 1
Failure = 0

[Success]
ComponentIDs = [ "x3000c0s6b0n0",]
```

### Unlock Management NCNs

The HSM CLI commands can also be used to unlock nodes.

To unlock all nodes with the Management role:

```screen
linux# cray hsm locks unlock create --role Management --processing-model rigid
Failure = []

[Counts]
Total = 8
Success = 8
Failure = 0

[Success]
ComponentIDs = [ "x3000c0s7b0n0", "x3000c0s6b0n0", "x3000c0s3b0n0", "x3000c0s2b0n0", "x3000c0s9b0n0", "x3000c0s8b0n0", "x3000c0s5b0n0", "x3000c0s4b0n0",]
```

To unlock a single node or lists of nodes:

```screen
linux# cray hsm locks unlock create --role Management \
--component-ids x3000c0s6b0n0 --processing-model rigid
Failure = []

[Counts]
Total = 1
Success = 1
Failure = 0

[Success]
ComponentIDs = [ "x3000c0s6b0n0",]
```


