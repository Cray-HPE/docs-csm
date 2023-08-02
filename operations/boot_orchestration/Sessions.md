# BOS Sessions

The Boot Orchestration Service (BOS) creates a session when it is asked to perform an operation on a session template.
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
