# Basic high-level BOS session flow

Assumes no multi-tenancy, no staged sessions.

1. Admin calls API to create a session template.

2. API server does some basic validation of the session template, then creates it in the BOS database.

3. Admin calls API to create a session to reboot a single xname (`xname1`).

4. API server does some basic validation of the session, then creates the `pending` session in the BOS database.

5. `session-setup` operator (the next time it runs) notices the `pending` session and processes it.

    1. Does further validation and determines that this session is targeting `xname1`
   
    2. Calls BOS to update the `xname1` component as follows:
    
        * enable it
        * set the `session` field to the name of the session
        * set the `desired_state` field to reflect the desired end state for the node. This includes boot artifacts, power state, and CFS configuration.
        * clears the `error` field
        * sets the `last_action` field to `session_setup`
        * Since this is a reboot operation, it also clears the `actual_state` field (to force BOS to reboot the node even if the target state happens to match the current state)

    3. Calls BOS to update the session as follows:

        * set state to `running`
        * set `components` field to `xname1`

6. `status` operator (next time it runs) notices that `xname` is enabled and processes it.

    The operator queries HSM, CFS, and PCS to get state information about `xname1`.
    We will assume `xname1` is currently booted. The operator will discover this when it queries PCS for the power state of the node.
    The `status` operator will call BOS to update the `xname1` component to have phase `power-off-pending`

7. `power-off-gracefully` operator (next time it runs) notices the enabled component in the `power-off-pending` phase.
   It issues a power off command to PCS for the node, and then calls BOS to update the `last_action` field for the component
   to `power_off_gracefully_called`.

8. The `status` operator will see that this has happened., and will check PCS to see if the node is powered off.
   Let's assume for this example that the node is not powered off.
   The `status` operator will update the component in BOS to have phase `powering_off`.

9. After `max_power_off_wait_time` has elapsed, the next time the `power-off-forcefully` operator runs, it will notice that this node had its power off request issued that long ago.
   The operator will call PCS to do a forceful power off on the node, and it will update the BOS component to have last_action `power_off_forcefully_called`.

10. The `status` operator will see that this has happened, and will check PCS to see if the node is powered off.
   Let's assume for this example that the node is not powered off.

11. After `max_power_off_wait_time` has elapsed AGAIN, the next time the `power-off-forcefully` operator runs, it will notice that this node had its power off request issued that long ago.
   The operator will call PCS to do a forceful power off on the node, and it will update the BOS component to have last_action `power_off_forcefully_called`.

12. Let's assume the node finally powers off now.
    The next time the `status` operator runs, it will notice that `xname1` has phase `power_off_pending`, and that PCS reports its power state as off.
    The operator will call BOS to update the component phase to be `power_on_pending`.

13. The next time the `power-on` operator runs, it will see `xname1` is enabled and has this phase. It does several things:

    1. Calls IMS to tag the boot image to enable SBPS projection
    2. Calls BSS to update the node with the kernel, kernel parameters, and `initrd`, and records the token sent back by BSS.
    3. Calls CFS to update the node: disable it, clear its state, and set its desired configuration.
    4. Calls PCS to power on the node.
    5. Calls BOS to update the component with last action of `power_on_called`.

14. `status` operator will see this and update the component phase to `powering_on`.

15. When the BOS reporter runs on the node, it will contact BOS to update the actual state for `xname1` with the BSS token for the node.

16. The API server will use that BSS token to look up the associate boot artifacts in the database, and update the component actual state with those as well.

17. The next time the `status` operator runs, it will see that `xname1` is on and that its actual boot artifacts match its desired boot artifacts.
    It will check CFS to see if the desired configuration is set for the node. In this case, it is, because it was set by the `power-on` operator.
    So the `status` operator will check CFS to find the status of the node. It sees that it is in `pending` state.
    The operator calls BOS to update the component phase to be `configuring`.

18. The `configuration` operator (next time it runs) will notice this enabled node in the `configuring` phase.
    It will check CFS to see if it has its desired configuration set. Since it does, the operator does nothing.

19. Eventually the `status` operator runs and sees that `xname1` has `configured` state in CFS.
    This means the node has completely reached its desired state.
    The operator calls BOS to update the component -- it disabled it and clears its phase.

20. The next time the `session-completion` operator runs, it will look at the session, since it is in the `running` state.
    It will see that only BOS component which references this session is `xname1`, but that this component is disabled.

    1. The operator will call BOS to update the session, updating the state to `complete` and setting the end time.

    2. The operator will call BOS to save the session status to the database.

21. Every time the `session-cleanup` operator runs, it issues a delete command to BOS.
    This command is to delete all sessions which are complete and that completed longer ago than `cleanup_completed_session_ttl`.
    If the session was not manually deleted before this, it will be deleted at this time.
