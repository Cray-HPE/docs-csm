# Troubleshoot CFS Sessions Failing to Start

This guide offers an overview of how [CFS sessions](Configuration_Sessions.md) are created
and started, in order to help troubleshoot related issues.
Also see the [CFS Flow Diagram](CFS_Flow_Diagrams.md).

* [Manual sessions](#manual-sessions)
* [Automated sessions](#automated-sessions)
* [Booting nodes](#booting-nodes)
* [Examples](#examples)

## Manual sessions

In this context, a manual CFS session is one that is created when an administrator
directly makes an API or CLI request to create the session.

After performing some basic validation, the CFS API server does the following things
in order:

1. Sends a message on the Kafka bus to the [CFS Operator](CFS_Operator.md), informing
   it of the new session.
1. Writes the new session data to the CFS database, with session `status` of `pending`.

When the CFS operator receives the Kafka message, it does the following things in order:

1. Creates a Kubernetes job to run the CFS session.
1. Makes an API call to CFS to update the session with the Kubernetes job ID.
1. Waits for the Kubernetes job to have a start time set (indicating that it is started running).
1. Makes an API call to CFS to update the session `status` to `running`.

## Automated sessions

In this context, an automated CFS session is one that is created by the
[CFS Batcher](CFS_Batcher.md).

Batcher periodically makes API calls to CFS to identify all [components](Configuration_Management_of_System_Components.md) that meet the
following criteria:

* Enabled
* Error count is less than the [batcher retry policy](CFS_Global_Options.md#default-batcher-retry-policy)
* Desired [configuration](Configuration_Layers.md) is set
* Component status is `pending` (which means that their desired configuration state does not match their actual configuration state)

It groups these components into batches and periodically makes an API call to CFS
to create a session to configure the components. What happens outside of batcher
works exactly the same way as [Manual sessions](#manual-sessions).

Batcher also monitors the `status` of all of the sessions that it creates. If any of them
remain in in `pending` state for too long, it makes an API call to CFS to delete them.

## Booting nodes

When a node boots, the [CFS State Reporter](CFS_State_Reporter.md) runs.
It makes a CFS API call to patch the node. This patch enables the node in CFS
and clears its `state` field. This causes the [Automated sessions](#automated-sessions)
procedure to kick in.

## Examples

* If a node is rebooted but no session is created in CFS, then check the following:

    1. Verify that CFS state reporter successfully ran on the node (`systemctl status cfs-state-reporter`).
    1. Describe the CFS component and verify that it meets the batcher criteria.
    1. Check the `cray-cfs-batcher` and `cray-cfs-api` Kubernetes pod logs to look for errors.

* If a CFS session is created but remains in `pending` state:

    Check the `cray-cfs-operator` and `cray-cfs-api` Kubernetes pod logs to look for errors.

    In particular, this may be caused by the following known issue:
    [CFS Sessions Stuck Pending](../../troubleshooting/known_issues/CFS_Sessions_Stuck_Pending.md).
