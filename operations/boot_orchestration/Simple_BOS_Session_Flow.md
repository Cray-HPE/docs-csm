# Simple BOS Session Flow

This is a basic, high-level summary of the flow of a BOS session. This assumes no multi-tenancy and no staged sessions.
All communications between services are using their APIs, unless otherwise specified.

1. The administrator calls BOS to [create](Manage_a_Session_Template.md#create-a-session-template)
   a [session template](Session_Templates.md).

1. API server does some basic validation of the session template, then creates it in the [BOS database](Database.md).

1. The administrator calls BOS to [create](Manage_a_BOS_Session.md#create-a-session) a
   [session](Sessions.md) to reboot a single [xname](../../glossary.md#xname) (`xname1`).

1. The [BOS API](API.md) server does some basic validation of the session, then creates the `pending` session in the BOS database.

1. The [`session-setup` operator](Operators.md#session-setup) (the next time it runs) notices the `pending`
   session and processes it.

    1. The operator performs further validation and determines that this session is targeting `xname1`.

    1. The operator calls the BOS API to update the `xname1` [component](Components.md) as follows:

        * Set the [`enabled` field](Components.md#enabled) to true.
        * Set the [`session` field](Components.md#session) to the name of the session.
        * Set the [`desired_state` field](Components.md#desired_state) to reflect the desired end state for the node.
          This includes boot artifacts, power state, and [CFS](../../glossary.md#configuration-framework-service-cfs) configuration.
        * Clears the [`error` field](Components.md#error).
        * Sets the [`last_action` field](Components.md#last_action) to `session_setup`.
        * Since this is a reboot operation, it also clears the [`actual_state` field](Components.md#actual_state)
          (this forces BOS to reboot the node even if the target state happens to match the current state).

    1. Calls the BOS API to update the session as follows:

        * Set the [`status` field](View_the_Status_of_a_BOS_Session.md#status) to `running`.
        * Set the `components` field to `xname1`.

1. The [`status` operator](Operators.md#status) (the next time it runs) notices that the `xname` component is enabled and processes it.

    The operator queries [HSM](../../glossary.md#hardware-state-manager-hsm), CFS, and
    [PCS](../../glossary.md#power-control-service-pcs) in order to get state information about `xname1`.
    For this example, assume that `xname1` is currently booted.
    The operator will discover this when it queries PCS for the power state of the node.
    The `status` operator will call the BOS API to update the `xname1` component to have
    [phase](Component_Status.md#phases) `power-off-pending`

1. The [`power-off-graceful` operator](Operators.md#power-off-graceful) (the next time it runs) notices the enabled component
   in the `power-off-pending` phase.
   It issues a power off command to PCS for the node, and then calls the BOS API to update the `last_action` field for the component
   to `power_off_gracefully_called`.

1. The `status` operator will see that this has happened., and will check PCS to see if the node is powered off.
   For this example, assume that PCS reports that the node is not powered off.
   The `status` operator will update the component in BOS to have phase `powering_off`.

1. After [`max_power_off_wait_time`](Options.md#max_power_off_wait_time) has elapsed,
   the next time the [`power-off-forceful` operator](Operators.md#power-off-forceful)
   runs, it will notice that this time period has elapsed since the node had its power off request issued.
   The operator will call PCS to do a forceful power off on the node, and then it will call the BOS API to update the
   component to have `last_action` `power_off_forcefully_called`.

1. The `status` operator will see that this has happened, and will check PCS to see if the node is powered off.
   For this example, assume that PCS still reports that the node is not powered off.

1. After `max_power_off_wait_time` has elapsed again, the next time the `power-off-forceful` operator runs,
   it will notice that this time period has elapsed since this node had its power off request issued.
   The operator will call PCS to do a forceful power off on the node, and it will update the BOS component
   to have `last_action` `power_off_forcefully_called`.

1. Assume that the node finally powers off.
   The next time the `status` operator runs, it will notice that `xname1` has phase `power_off_pending`,
   and that PCS reports its power state as off.
   The operator will call the BOS API to update the component phase to be `power_on_pending`.

1. The next time the [`power-on` operator](Operators.md#power-on) runs, it will see `xname1` is enabled
   and has this phase. It does several things:

    1. Calls [IMS](../../glossary.md#image-management-service-ims) to tag the boot image to enable
       [SBPS](../../glossary.md#scalable-boot-projection-service-sbps) projection.
    1. Calls [BSS](../../glossary.md#boot-script-service-bss) to update the node with the kernel,
       [kernel parameters](Kernel_Boot_Parameters.md), and `initrd`; it records the token sent back by BSS.
    1. Calls CFS to update the node: disable it, clear its state, and set its desired configuration.
    1. Calls PCS to power on the node.
    1. Calls BOS to update the component with last action of `power_on_called`.

1. `status` operator will see this and update the component phase to `powering_on`.

1. When the [BOS reporter](Reporter.md) runs on the node, it will contact BOS to update the actual state for `xname1` with the BSS token for the node.

1. The API server will use that BSS token to look up the associate boot artifacts in the database, and
   update the component actual state with those as well.

1. The next time the `status` operator runs, it will see that `xname1` is on and that its actual boot artifacts
   match its desired boot artifacts.
   It will check CFS to see if the desired configuration is set for the node. In this case, it is, because it was
   set by the `power-on` operator.
   So the `status` operator will check CFS to find the status of the node. It sees that it is in `pending` state.
   The operator calls the BOS API to update the component phase to be `configuring`.

1. The [`configuration` operator](Operators.md#configuration) (the next time it runs) will notice this enabled
   node in the `configuring` phase. It will check CFS to see if it has its desired configuration set. Since it
   does, the operator does nothing.

1. Eventually the `status` operator runs and sees that `xname1` has `configured` state in CFS.
   This means the node has completely reached its desired state.
   The operator calls the BOS API to update the component -- it disabled it and clears its phase.

1. The next time the [`session-completion` operator](Operators.md#session-completion) runs, it will look at the
   session, since it is in the `running` state.
   It will see that only BOS component which references this session is `xname1`, but that this component is disabled.

    1. The operator will call the BOS API to update the session, updating the state to `complete`
       and setting the [`end_time` field](View_the_Status_of_a_BOS_Session.md#end_time).

    1. The operator will call the BOS API to save the session status to the database.

1. Every time the [`session-cleanup` operator](Operators.md#session-cleanup) runs, it issues a delete command to BOS.
   This command is to delete all sessions which are complete and that completed longer ago than
   [`cleanup_completed_session_ttl`](Options.md#cleanup_completed_session_ttl).
   If the session was not manually deleted before this, it will be deleted at this time.
