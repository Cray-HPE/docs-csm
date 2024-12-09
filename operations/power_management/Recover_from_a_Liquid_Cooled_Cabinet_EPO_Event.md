# Recover from a Liquid Cooled Cabinet EPO Event

Identify an emergency power off \(EPO\) has occurred and restore cabinets to a healthy state.

**CAUTION:** Verify the reason why the EPO occurred and resolve that problem before clearing the EPO state.

If a Cray EX liquid-cooled cabinet or cooling group experiences an EPO event, the compute nodes may not boot. Use CAPMC to force off all the chassis affected by the EPO event.

## Procedure

1. Verify that the EPO event did not damage the system hardware.

1. (`ncn-mw#`) Check the status of the chassis.

    ```bash
    cray power status list --xnames x9000c[1,3] --format toml
    ```

    Example output:

    ```toml
    [[status]]
    xname = "x9000c1"
    powerState = "off"
    managementState = "available"
    error = ""
    supportedPowerTransitions = [ "On", "Force-Off", "Soft-Off", "Off", "Init", "Hard-Restart", "Soft-Restart",]
    lastUpdated = "2024-02-04T01:48:47.839347547Z"

    [[status]]
    xname = "x9000c3"
    powerState = "off"
    managementState = "available"
    error = ""
    supportedPowerTransitions = [ "On", "Force-Off", "Soft-Off", "Off", "Init", "Hard-Restart", "Soft-Restart",]
    lastUpdated = "2024-02-04T01:48:48.240138908Z"
    ```

1. (`ncn#`) Check the Chassis Controller Module \(CCM\) log for `Critical` messages and the EPO event.

    ```bash
    ssh x9000c1b0 egrep \"Critical\|= No\" /var/log/messages
    ```

    Example output:

    ```text
    Apr 8 03:47:55 x9000c1 user.info redfish-cmmd[4453]: do_cmm_enclosure_reset_forceoff: Handling Enclosure (Force)Off request: clearing EPO = No
    Apr 8 03:47:55 x9000c1 user.info redfish-cmmd[4453]: rbe_set_chassis_status: Update Chassis 'Enclosure' Status: UnavailableOffline, Critical
    Apr 11 04:00:06 x9000c1 user.info redfish-cmmd[4453]: do_cmm_enclosure_reset_forceoff: Handling Enclosure (Force)Off request: clearing EPO = No
    Apr 11 04:00:06 x9000c1 user.info redfish-cmmd[4453]: rbe_set_chassis_status: Update Chassis 'Enclosure' Status: UnavailableOffline, Critical
    ```

1. (`ncn-mw#`) Disable the `hms-discovery` Kubernetes cron job.

    ```bash
    kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
    ```

    **CAUTION:** Do not power the system on until it is safe to do so. Determine why the EPO event occurred before clearing the EPO state.

1. (`ncn-mw#`) **If it is safe to power on the hardware**, clear all chassis in the EPO state in the cooling group.

    All chassis in cabinets 1000-1003 are forced off in this example. Power off all chassis in a cooling group simultaneously, or the EPO condition may persist.

    ```bash
    cray power transition force-off --xnames x[1000-1003]c[0-7]
    ```

    The HPE Cray EX EX TDS cabinet contains only two chassis: 1 \(bottom\) and 3 \(top\).

    ```bash
    cray power transition force-off --xnames x9000c[1,3]
    ```

1. (`ncn-mw#`) Restart the `hms-discovery` cron job.

    ```bash
    kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : false }}'
    ```

    About 5 minutes after `hms-discovery` restarts, the service will power on the chassis enclosures, switches, and compute blades.
    If components are not being powered back on, then power them on manually.

    ```bash
    cray power transition on -xnames x[1000-1003]c[0-7]r[0-7],x[1000-1003]c[0-7]s[0-7] --include parents
    ```

1. Verify the Slingshot fabric is up and healthy.

    Refer to the following documentation for more information on how to verify the health of the Slingshot Fabric:

    * The *Slingshot Administration Guide* PDF for HPE Cray EX systems.
    * The *Slingshot Troubleshooting Guide* PDF.

1. After the components have powered on, boot the nodes using the Boot Orchestration Services \(BOS\).

    See [Power On and Boot Compute and User Access Nodes](Power_On_and_Boot_Compute_Nodes_and_User_Access_Nodes.md).
