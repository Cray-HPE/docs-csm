# Lock and Unlock Management Nodes

The ability to ignore non-compute nodes (NCNs) is turned off by default. Management nodes, NCNs, and their BMCs are also not locked by default. The administrator must lock the NCNs and their BMCs to prevent unwanted actions from affecting these nodes.

This section only covers using locks with the Hardware State Manager (HSM). For more information
on ignoring nodes, refer to the following sections:

* Firmware Action Service (FAS): See [Ignore Node within FAS](../firmware/FAS_Admin_Procedures.md#ignore-management-nodes-within-fas).
* Cray Advanced Platform Monitoring and Control (CAPMC): See [Ignore Nodes with CAPMC](../power_management/Ignore_Nodes_with_CAPMC.md)

The following actions can be prevented when a node and its BMC is locked.

* Firmware upgrades with FAS
* Power off operations with PCS/CAPMC
* Reset operations with PCS/CAPMC

Doing any of these actions by accident will shut down a management node. If the node is a Kubernetes master or worker
node, this can have serious negative effects on system operations. If a single node is taken down by mistake, it is
possible that services will recover. If all management nodes are taken down, or all Kubernetes worker nodes are taken down by mistake, the system must be restarted.

After critical nodes are locked, power/reset (PCS/CAPMC) or firmware (FAS) operations cannot affect the nodes unless
they are unlocked. For example, any locked node that is included in a list of nodes to be reset will result in a
failure.

## Topics

* [When to lock management nodes](#when-to-lock-management-nodes)
* [When to unlock management nodes](#when-to-unlock-management-nodes)
* [How to lock management nodes](#how-to-lock-management-nodes)
    * [Script](#script)
    * [Manual steps](#manual-steps)
        * [To lock all nodes (and their BMCs) with the `Management` role](#to-lock-all-nodes-and-their-bmcs-with-the-management-role)
        * [To lock single nodes or lists of specific nodes (and their BMCs)](#to-lock-single-nodes-or-lists-of-specific-nodes-and-their-bmcs)
    * [How to check for locked management nodes](#how-to-check-for-locked-management-nodes)
    * [How to unlock management nodes](#how-to-unlock-management-nodes)
        * [To unlock all nodes (and their BMCs) with the `Management` role](#to-unlock-all-nodes-and-their-bmcs-with-the-management-role)
    * [To unlock single or lists of specific nodes (and their BMCs)](#to-unlock-single-or-lists-of-specific-nodes-and-their-bmcs)
* [Additional information](#additional-information)

## When to lock management nodes

To best protect system health, NCNs and their BMCs should be locked as early as possible in the install/upgrade cycle. The later in the process, the more risk there is of accidentally taking down a critical node.
NCN locking must be done after Kubernetes is running and the HSM service is operational.

(`ncn-mw#`) Check whether HSM is running with the following command:

```bash
kubectl -n services get pods | grep smd
```

Example output:

```text
cray-smd-848bcc875c-6wqsh           2/2     Running    0          9d
cray-smd-848bcc875c-hznqj           2/2     Running    0          9d
cray-smd-848bcc875c-tp6gf           2/2     Running    0          6d22h
cray-smd-init-2tnnq                 0/2     Completed  0          9d
cray-smd-postgres-0                 2/2     Running    0          19d
cray-smd-postgres-1                 2/2     Running    0          6d21h
cray-smd-postgres-2                 2/2     Running    0          19d
cray-smd-wait-for-postgres-4-7c78j  0/3     Completed  0          9d
```

The `cray-smd` pods need to be in the `Running` state, except for `cray-smd-init` and
`cray-smd-wait-for-postgres` which should be in `Completed` state.

## When to unlock management nodes

Any time a management NCN has to be power cycled, reset, or have its firmware updated,
it and its BMC will first need to be unlocked. After the operation is complete, the targeted nodes and BMCs
should once again be locked.

## How to lock management nodes

### Script

Run the `lock_management_nodes.py` script to lock all management nodes and BMCs that are not already locked:

```bash
/opt/cray/csm/scripts/admin_access/lock_management_nodes.py
```

The return value of the script is 0 if locking was successful. A non-zero return code means that manual intervention may be needed to lock the nodes. Continue below for manual steps.

### Manual steps

Use the `cray hsm locks lock` command to perform locking.

**NOTE** When locking NCNs, it is required to lock their node BMCs as well.

**NOTE** The following steps assume both the management nodes and their BMCs are marked with the `Management` role in HSM. If they are not, see [Set BMC Management Role](Set_BMC_Management_Role.md).

#### To lock all nodes (and their BMCs) with the `Management` role

   The `processing-model rigid` parameter means that the operation must succeed on all
   target nodes or the entire operation will fail.

Lock the management nodes and BMCs.

```bash
cray hsm locks lock create --role Management --processing-model rigid --format toml
```

Example output:

```toml
Failure = []

[Counts]
Total = 16
Success = 16
Failure = 0

[Success]
ComponentIDs = [ "x3000c0s5b0n0", "x3000c0s4b0n0", "x3000c0s7b0n0", "x3000c0s6b0n0", "x3000c0s3b0n0", "x3000c0s2b0n0", "x3000c0s9b0n0", "x3000c0s8b0n0",
                 "x3000c0s5b0", "x3000c0s4b0", "x3000c0s7b0", "x3000c0s6b0", "x3000c0s3b0", "x3000c0s2b0", "x3000c0s9b0", "x3000c0s8b0",]
```

#### To lock single nodes or lists of specific nodes (and their BMCs)

> **NOTE** The BMC of `ncn-m001` typically does not exist in HSM under HSM State Components, and therefore cannot be locked.

Lock the management nodes and BMCs.

```bash
cray hsm locks lock create --role Management --component-ids x3000c0s6b0n0,x3000c0s6b0 --processing-model rigid --format toml
```

Example output:

```toml
Failure = []

[Counts]
Total = 2
Success = 2
Failure = 0

[Success]
ComponentIDs = [ "x3000c0s6b0n0", "x3000c0s6b0",]
```

## How to check for locked management nodes

> **NOTE** The BMC of `ncn-m001` typically does not exist in HSM under HSM State Components, and therefore would not show up in the following command output.

Check the lock status of the management nodes and BMCs.

```bash
cray hsm state components list --type Node --role Management --format json | \
   jq -c '.Components[]|.ID' | tr '\n' ',' | sed 's/,$/\n/' | \
   xargs cray hsm locks status create --format toml --component-ids
```

Example output:

```toml
[[Components]]
ID = "x3000c0s1b0n0"
Locked = true
Reserved = false
ReservationDisabled = false

[[Components]]
ID = "x3000c0s5b0n0"
Locked = true
Reserved = false
ReservationDisabled = false

[[Components]]
ID = "x3000c0s4b0n0"
Locked = true
Reserved = false
ReservationDisabled = false

[[Components]]
ID = "x3000c0s7b0n0"
Locked = true
Reserved = false
ReservationDisabled = false

[[Components]]
ID = "x3000c0s6b0n0"
Locked = true
Reserved = false
ReservationDisabled = false

[[Components]]
ID = "x3000c0s3b0n0"
Locked = true
Reserved = false
ReservationDisabled = false

[[Components]]
ID = "x3000c0s3b0n0"
Locked = true
Reserved = false
ReservationDisabled = false

[[Components]]
ID = "x3000c0s9b0n0"
Locked = true
Reserved = false
ReservationDisabled = false

[[Components]]
ID = "x3000c0s8b0n0"
Locked = true
Reserved = false
ReservationDisabled = false

[[Components]]
ID = "x3000c0s5b0"
Locked = true
Reserved = false
ReservationDisabled = false

[[Components]]
ID = "x3000c0s4b0"
Locked = true
Reserved = false
ReservationDisabled = false

[[Components]]
ID = "x3000c0s7b0"
Locked = true
Reserved = false
ReservationDisabled = false

[[Components]]
ID = "x3000c0s6b0"
Locked = true
Reserved = false
ReservationDisabled = false

[[Components]]
ID = "x3000c0s3b0"
Locked = true
Reserved = false
ReservationDisabled = false

[[Components]]
ID = "x3000c0s3b0"
Locked = true
Reserved = false
ReservationDisabled = false

[[Components]]
ID = "x3000c0s9b0"
Locked = true
Reserved = false
ReservationDisabled = false

[[Components]]
ID = "x3000c0s8b0"
Locked = true
Reserved = false
ReservationDisabled = false
```

## How to unlock management nodes

Use the `cray hsm locks unlock` command to perform unlocking.

**NOTE: When unlocking NCNs, it is required to unlock their node BMCs as well.**

**NOTE: The following steps assume both the management nodes and their BMCs are marked with the `Management` role in HSM. If they are not, see [Set BMC Management Role](Set_BMC_Management_Role.md).**

### To unlock all nodes (and their BMCs) with the `Management` role

Unlock the management nodes and BMCs.

```bash
cray hsm locks unlock create --role Management --processing-model rigid --format toml
```

Example output:

```toml
Failure = []

[Counts]
Total = 16
Success = 16
Failure = 0

[Success]
ComponentIDs = [ "x3000c0s7b0n0", "x3000c0s6b0n0", "x3000c0s3b0n0", "x3000c0s2b0n0", "x3000c0s9b0n0", "x3000c0s8b0n0", "x3000c0s5b0n0", "x3000c0s4b0n0",
                 "x3000c0s5b0", "x3000c0s4b0", "x3000c0s7b0", "x3000c0s6b0", "x3000c0s3b0", "x3000c0s2b0", "x3000c0s9b0", "x3000c0s8b0",]
```

### To unlock single or lists of specific nodes (and their BMCs)

Unlock the management nodes.

```bash
cray hsm locks unlock create --role Management --component-ids x3000c0s6b0n0,x3000c0s6b0 --processing-model rigid --format toml
```

Example output:

```toml
Failure = []

[Counts]
Total = 2
Success = 2
Failure = 0

[Success]
ComponentIDs = [ "x3000c0s6b0n0", "x3000c0s6b0",]
```

## Additional information

* [HSM Locking API](Hardware_Management_Services_HMS_Locking_API.md)
* [Manage HSM Locks](Manage_HMS_Locks.md)
* [BOS v2 sessions and HSM locks](../boot_orchestration/Sessions.md#bos-v2-sessions-and-hsm-locks)
* [HSM API specification](../../api/smd.md)
