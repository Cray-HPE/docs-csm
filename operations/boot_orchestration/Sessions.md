# BOS Sessions

The Boot Orchestration Service (BOS) creates a session when it is asked to perform an operation on a session template.
Sessions provide a way to track the status of many nodes at once as they perform the same operation with the same session template information.
When creating a session, both the operation and session template are required parameters.

* [BOA functionality](#boa-functionality)
* [BOS v1 session limitations](#bos-v1-session-limitations)

The v1 version of BOS supports these operations:

* Boot - Boot a designated collection of nodes.
* Shutdown - Shutdown a designated collection of nodes.
* Reboot - Reboot a designated collection of nodes.
* Configure - Configure a designated collection of booted nodes.

BOS sessions can be used to boot compute nodes with customized image roots.

The Boot Orchestration Agent \(BOA\) implements each session and sees it through to completion. A BOA is a Kubernetes job. It runs once to completion. If there are transient failures,
BOA will exit and Kubernetes will reschedule it so that it can re-execute its session.

A session requires two parameters, a session template ID and an operation to perform on that template. The BOS API's `session` endpoint can display a list of all of the sessions that have been
created, including previous and currently running sessions. The endpoint can also display the details of a given session when the specific session ID is provided as a parameter.
Sessions can also be deleted through the API.

BOS supports a RESTful API. This API can be interacted with directly using tools like cURL. It can also be interacted with through the Cray Command Line Interface \(CLI\). See [Manage a BOS Session](Manage_a_BOS_Session.md) for more information.

## BOA functionality

BOA moves nodes towards the requested state, but if a node fails during any of the immediate steps, it takes note of it. BOA will then provide a command in the output of the
BOA log that can be used to retry the action. This behavior impacts all BOS operations.

A good example is a 6,000 node system where 3 nodes fail to power off during a BOS operation. BOA will continue and attempt to re-provision the remaining 5,997 nodes.
After the command is finished, it will provide output information about what the administrator needs to do to retry the last 3 nodes that failed.

## BOS v1 session limitations

The following limitations currently exist with BOS sessions:

* No checking is done to prevent the launch of multiple sessions with overlapping lists of nodes.
  Concurrently running sessions may conflict with each other.
* The boot ordinal and shutdown ordinal are not honored.
* The partition parameter is not honored.
* All nodes proceed at the same pace. BOA will not move on to the next step of the boot process until
  all components have succeeded or failed the current step.
* The Configuration Framework Service \(CFS\) has its own limitations.
  Refer to the [Configuration Management](../configuration_management/Configuration_Management.md) documentation for more information.
