# BOS Sessions

The Boot Orchestration Service (BOS) creates a session when it is asked to perform an operation on a [session template](Session_Templates.md).
Sessions provide a way to track the status of many nodes at once as they perform the same operation with the same session template information.
When creating a session, both the operation and session template are required parameters.

BOS v2 supports these operations:

* Reboot - Reboot a designated collection of nodes into the desired state. This will always force a reboot.
* Boot - Boot a designated collection of nodes into the desired state. This may include a reboot if necessary.
* Shutdown - Shutdown a designated collection of nodes.

See [Manage a BOS Session](Manage_a_BOS_Session.md) for more information on creating and managing BOS sessions.

## Sessions and status

In BOS v2, components are managed independently. Each component has an associated record in BOS that contains some information about the desired and current state.
Several operators monitor for components that require actions to be taken and trigger the associated action.

Session in BOS v2 are constructs intended to help users track an operation across multiple components at once.
A session will continue to track a component until the component reaches its desired state and is disabled or until another sessions takes over managing that component.
Additional status information is also available for sessions to track information such as how many components are at each step in the process.
See [View the Status of a BOS Session](View_the_Status_of_a_BOS_Session.md) for more information.

## BOS sessions and HSM locks

As part of a `pending` BOS session being started, the BOS [`session-setup` operator](BOS_Services.md#session-setup)
determines which nodes are targeted for the session. For example, it removes nodes whose architectures are not compatible with
the boot sets in the session template, and this is also when it applies the
[session limit](Limit_the_Scope_of_a_BOS_Session.md) (if one was specified).
Included in this process is a query to the [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm)
for a list of all locked nodes. (For more information on these locks, see
[Manage HMS Locks](../hardware_state_manager/Manage_HMS_Locks.md).)

Any nodes which are locked in HSM are removed from the BOS session at this time (because any
[Power Control Service (PCS)](../../glossary.md#power-control-service-pcs) operations on locked nodes are guaranteed to fail).
The status for the resulting BOS session will only show the nodes which were not removed during this process. However,
the `session-setup` operator Kubernetes pod log will contain information on which nodes were removed and for what reason.

This check only happens when the session first starts. If a node is locked in HSM while the session is already running, then BOS
will not be directly aware of that. Instead, any calls it makes to PCS for that node will fail.
Depending on how far along that node is in the BOS session, this may or may not result in that node failing to boot.

Prior to CSM 1.7, BOS never checked for HSM locks. Instead, locked nodes would be included in the session,
and the PCS failures described above would result in their boots failing. The associated error message
in BOS for that component was generally not helpful in determining the true cause of the problem.
