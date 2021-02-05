# NCN/Management Node Locking

## Why?

In Shasta 1.4 NCN black listing is turned off by default.  Also, please note
that Management/NCN nodes are NOT locked by default either.

Thus it is up to the administrator to properly lock NCNs to prevent things 
from accidentally being done to them, namely:

* Firmware upgrades
* Power down operations
* Reset operations

Doing any of these by accident will take down an NCN.  If the NCN is a 
Kubernetes master or worker node, this can have serious negative effects on
system operation.  

If a single node is taken down by mistake it is possible that things will 
recover; if all NCNs are taken down, or all Kubernetes workers are taken down
by mistake, the system is dead and has to be completely restarted.

## When To Lock Management/NCN Nodes

If NCNs are to be locked, **it should be done as early as possible in the install/
upgrade cycle**.   The later in the process, the more risk of accidentally taking
down a critical node.

NCN locking must be done after Kubernetes is running and all HMS Hardware State Manager service is operational.

This can be checked thusly:

```bash
linux:~ # kubectl -n services get pods | grep smd
cray-smd-848bcc875c-6wqsh           2/2     Running    0          9d
cray-smd-848bcc875c-hznqj           2/2     Running    0          9d
cray-smd-848bcc875c-tp6gf           2/2     Running    0          6d22h
cray-smd-init-2tnnq                 0/2     Completed  0          9d
cray-smd-postgres-0                 2/2     Running    0          19d
cray-smd-postgres-1                 2/2     Running    0          6d21h
cray-smd-postgres-2                 2/2     Running    0          19d
cray-smd-wait-for-postgres-4-7c78j  0/3     Completed  0          9d
```

Note that the cray-smd-xxx pods are in the **Running** state.

## When To Unlock Management/NCN Nodes

Any time a management/NCN node has to be power cycled, reset, or have its
firmware updated it will first need to be unlocked.   

After the operation is complete the targeted nodes should once again be locked.
See below for instructions and examples.

## Locked Behavior

Once critical nodes are locked, then no power/reset (CAPMC) or firmware (FAS)
operations can be done to them unless they are first unlocked.   Any node
included in a list of nodes to reset, for example, which are locked, will
result in a failure.

## How To Lock Management NCNs

Use the standard CLI to perform locking.  The simplest command will lock all
nodes with a **Management** role.  The *processing-model rigid* parameter means that the
operation must succeed on all target nodes or the entire operation will fail.

Example:

```bash
linux:~ # cray hsm locks lock create --role Management --processing-model rigid
Failure = []

[Counts]
Total = 8
Success = 8
Failure = 0

[Success]
ComponentIDs = [ "x3000c0s5b0n0", "x3000c0s4b0n0", "x3000c0s7b0n0", "x3000c0s6b0n0", "x3000c0s3b0n0", "x3000c0s2b0n0", "x3000c0s9b0n0", "x3000c0s8b0n0",]
```

Single nodes or lists of specific nodes can also be locked:

```bash
linux:~ # cray hsm locks lock create --role Management --component-ids x3000c0s6b0n0 --processing-model rigid
Failure = []

[Counts]
Total = 1
Success = 1
Failure = 0

[Success]
ComponentIDs = [ "x3000c0s6b0n0",]
```


## How To Unlock Management NCNs

```bash
linux:~ # cray hsm locks unlock create --role Management --processing-model rigid
Failure = []

[Counts]
Total = 8
Success = 8
Failure = 0

[Success]
ComponentIDs = [ "x3000c0s7b0n0", "x3000c0s6b0n0", "x3000c0s3b0n0", "x3000c0s2b0n0", "x3000c0s9b0n0", "x3000c0s8b0n0", "x3000c0s5b0n0", "x3000c0s4b0n0",]
```
Single nodes or lists of specific nodes can also be locked:

```bash
linux:~ # cray hsm locks unlock create --role Management --component-ids x3000c0s6b0n0 --processing-model rigid
Failure = []

[Counts]
Total = 1
Success = 1
Failure = 0

[Success]
ComponentIDs = [ "x3000c0s6b0n0",]
```

