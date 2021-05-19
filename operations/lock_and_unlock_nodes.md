# Lock and Unlock Nodes

Starting with Shasta v1.4, CAPMC and FAS have the ability to ignore management nodes by honoring
a lock state, however this ability is turned off by default.  The administrator must lock the
management nodes to prevent unwanted actions from affecting these nodes.  

This section only covers using locks with the Hardware State Manager (HSM). For more information
on ignoring nodes, refer to the following sections:

   * Firmware Action Service (FAS): Refer to "Ignore Node within FAS" in the _HPE Cray EX Hardware Management Administration Guide 1.5 S-8015_
   * Cray Advanced Platform Monitoring and Control (CAPMC): Refer to "Ignore Node with CAPMC" in the _HPE Cray EX Hardware Management Administration Guide 1.5 S-8015_

The following actions can be prevented when a node is locked.
   * Firmware upgrades with FAS
   * Power off operations with CAPMC
   * Reset operations with CAPMC

Doing any of these actions by accident will shut down a management node. If the node is a Kubernetes master or worker
node, this can have serious negative effects on system operations. If a single node is taken down by mistake, it is
possible that services will recover. If all management nodes are taken down, or all Kubernetes workers are taken down by
mistake, the system must be restarted.

After critical nodes are locked, power/reset (CAPMC) or firmware (FAS) operations cannot affect the nodes unless
they are unlocked. For example, any locked node that is included in a list of nodes to be reset will result in a
failure.

### Topics:

   * [When To Lock Management Nodes](#when-to-lock-management-nodes) 
   * [When To Unlock Management Nodes](#when-to-unlock-management-nodes) 
   * [How To Lock Management Nodes](#how-to-lock-management-nodes)
   * [How To Unlock Management Nodes](#how-to-unlock-management-nodes) 

## Details

<a name="when-to-lock-management-nodes"></a>
### When To Lock Management Nodes

To best protect system health, management nodes should be locked as early as possible in the
install/upgrade cycle.   The later in the process, the more risk of accidentally taking
down a critical node.  Management node locking must be done after Kubernetes is running and
the HSM (Hardware State Manager) service is operational.

Check whether HSM is running with the following command.

```bash
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

The `cray-smd` pods need to be in the 'Running' state, except for `cray-smd-init` and
`cray-smd-wait-for-postgres` which should be in 'Completed' state..

<a name="when-to-unlock-management-nodes"></a>
### When To Unlock Management Nodes

Any time a management NCN has to be power cycled, reset, or have its firmware updated
it will first need to be unlocked.  After the operation is complete the targeted nodes
should once again be locked.

<a name="how-to-lock-management-nodes"></a>
### How To Lock Management Nodes

Use the `cray hsm locks lock` command to perform locking. 

* To lock all nodes with the _Management_ role.

   The *processing-model rigid* parameter means that the operation must succeed on all
   target nodes or the entire operation will fail.

   ```bash
   linux# cray hsm locks lock create --role Management --processing-model rigid
   Failure = []
   
   [Counts]
   Total = 8
   Success = 8
   Failure = 0
   
   [Success]
   ComponentIDs = [ "x3000c0s5b0n0", "x3000c0s4b0n0", "x3000c0s7b0n0", "x3000c0s6b0n0", "x3000c0s3b0n0", "x3000c0s2b0n0", "x3000c0s9b0n0", "x3000c0s8b0n0",]
   ```

* To lock single nodes or lists of specific nodes.

   ```bash
   linux# cray hsm locks lock create --role Management --component-ids x3000c0s6b0n0 --processing-model rigid
   Failure = []
   
   [Counts]
   Total = 1
   Success = 1
   Failure = 0
   
   [Success]
   ComponentIDs = [ "x3000c0s6b0n0",]
   ```

<a name="how-to-unlock-management-nodes"></a>
### How To Unlock Management Nodes

Use the `cray hsm locks unlock` command to perform unlocking. 

* To lock all nodes with the _Management_ role.

   ```bash
   linux# cray hsm locks unlock create --role Management --processing-model rigid
   Failure = []
   
   [Counts]
   Total = 8
   Success = 8
   Failure = 0
   
   [Success]
   ComponentIDs = [ "x3000c0s7b0n0", "x3000c0s6b0n0", "x3000c0s3b0n0", "x3000c0s2b0n0", "x3000c0s9b0n0", "x3000c0s8b0n0", "x3000c0s5b0n0", "x3000c0s4b0n0",]
   ```

* To unlock single nodes or lists of specific nodes.

   ```bash
   linux# cray hsm locks unlock create --role Management --component-ids x3000c0s6b0n0 --processing-model rigid
   Failure = []
   
   [Counts]
   Total = 1
   Success = 1
   Failure = 0
   
   [Success]
   ComponentIDs = [ "x3000c0s6b0n0",]
   ```

