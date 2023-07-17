# BOS Sessions

The Boot Orchestration Service (BOS) creates a session when it is asked to perform an operation on a session template.
Sessions provide a way to track the status of many nodes at once as they perform the same operation with the same session template information.
When creating a session, both the operation and session template are required parameters.

* [BOS sessions in v2](#bos-sessions-in-v2)
  * [Sessions and status](#sessions-and-status)
* [BOS sessions in v1](#bos-sessions-in-v1)
  * [BOA functionality](#boa-functionality)
  * [BOS v1 session limitations](#bos-v1-session-limitations)

## BOS sessions in v2

The v2 version of BOS supports these operations:

* Reboot - Reboot a designated collection of nodes into the desired state. This will always force a reboot.
* Boot - Boot a designated collection of nodes into the desired state. This may include a reboot if necessary.
* Shutdown - Shutdown a designated collection of nodes.

See [Manage a BOS Session](Manage_a_BOS_Session.md) for more information on creating and managing BOS sessions.

### Sessions and status

In BOS v2, components are managed independently. Each component has an associated record in BOS that contains some information about the desired and current state.
Several operators monitor for components that require actions to be taken and trigger the associated action.

Session in BOS v2 are constructs intended to help users track an operation across multiple components at once.
A session will continue to track a component until the component reaches its desired state and is disabled or until another sessions takes over managing that component.
Additional status information is also available for sessions to track information such as how many components are at each step in the process.
See [View the Status of a BOS Session](View_the_Status_of_a_BOS_Session.md) for more information.

## BOS sessions in v1

The v1 version of BOS supports these operations:

* Boot - Boot a designated collection of nodes.
* Shutdown - Shutdown a designated collection of nodes.
* Reboot - Reboot a designated collection of nodes.
* Configure - Configure a designated collection of booted nodes.

See [Manage a BOS Session](Manage_a_BOS_Session.md) for more information on creating and managing BOS sessions.

### BOA functionality

The Boot Orchestration Agent \(BOA\) is a Kubernetes job that manages all the components until the session is complete. If there are transient failures, BOA will exit and Kubernetes will reschedule it so that it can re-execute its session.

BOA moves nodes towards the requested state, but if a node fails during any of the intermediate steps, it takes note of it.
BOA will then provide a command in the output of the BOA log that can be used to retry the action.

For example, if there is a 6,000 node system and 3 nodes fail to power off during a BOS operation.
then BOA will continue and attempt to re-provision the remaining 5,997 nodes.
After the command is finished, it will provide information about what the administrator needs to do in order to retry the operation on the 3 nodes that failed.

### BOS v1 session limitations

The following limitations currently exist with BOS sessions:

* No checking is done to prevent the launch of multiple sessions with overlapping lists of nodes.
  Concurrently running sessions may conflict with each other.
* The boot ordinal and shutdown ordinal are not honored.
* The partition parameter is not honored.
* All nodes proceed at the same pace. BOA will not move on to the next step of the boot process until
  all components have succeeded or failed the current step.
