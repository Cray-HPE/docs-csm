# BOS Sessions Stuck Pending

* [Summary](#summary)
* [Symptoms](#symptoms)
* [Details](#details)
* [Remediation](#remediation)
* [Fix](#fix)

## Summary

If a [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos) [Session](../../operations/boot_orchestration/Sessions.md)
is created using a [Session Template](../../operations/boot_orchestration/Session_Templates.md) that indirectly refers to invalid
[xnames](../../glossary.md#xname), then this can prevent the BOS [`session-setup` operator](../../operations/boot_orchestration/BOS_Services.md#session-setup)
from moving any sessions out of the `pending` state.

## Symptoms

The primary symptom is that new BOS sessions will remain in the `pending` state and never progress.
If the `cray-bos-operator-session-setup` pod logs are viewed, it will repeatedly log errors, every time
it tries to process sessions.

## Details

This can only happen when a session template is created that includes
[Node groups](../../operations/boot_orchestration/Session_Templates.md#node-groups) in a boot set.
Specifically, this problem happens if the session template specifies a
[Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm)
[component group](../../operations/hardware_state_manager/Manage_Component_Groups.md)
that contains xnames that do not exist as BOS [Components](../../operations/boot_orchestration/Components.md).

## Remediation

The solution is to delete the `pending` BOS sessions that are using these session templates, or to correct
the session templates (or corresponding HSM groups).

Once this has been done for all such sessions, then the problem is resolved and BOS sessions will proceed as normal.

(`ncn-mw#`) Follow this procedure to identify and delete these sessions.

1. List all `pending` BOS sessions.

    ```bash
    cray bos v2 sessions list --status pending --format json
    ```

1. For each listed session, describe its corresponding session template.

    ```bash
    cray bos v2 sessiontemplates describe <template_name> --format json
    ```

1. If the session template contains any boot sets with `node_groups` fields, list the members of the corresponding groups.

    ```bash
    cray hsm groups members list <group_label> --format json
    ```

1. For each xname listed, verify that the corresponding BOS component exists.

    ```bash
    cray bos v2 components describe <xname>
    ```

1. If any xname does not exist as a BOS component, then do one of the following:

    * [Delete the BOS session](../../operations/boot_orchestration/Manage_a_BOS_Session.md#delete-a-session) which indirectly includes it.
    * [Remove the invalid xname from the HSM group](../../operations/hardware_state_manager/Manage_Component_Groups.md#modify-a-group).
    * [Modify the BOS session template](../../operations/boot_orchestration/Manage_a_Session_Template.md#modify-a-session-template)
      to remove the reference to the HSM group.

## Fix

This problem is fixed in CSM 1.7, by modifying BOS to ignore any invalid xnames. The fix is not backported to earlier CSM versions.
Prior to CSM 1.7, the above [Remediation](#remediation) must be used if the issue is encountered.
