# Recover from a Liquid Cooled Cabinet EPO Event

Identify an emergency power off \(EPO\) has occurred and restore cabinets to a healthy state.

**CAUTION:** Verify the reason why the EPO occurred and resolve that problem before clearing the EPO state.

If a Cray EX liquid-cooled cabinet or cooling group experiences an EPO event, the compute nodes may not boot. Use CAPMC to force off all the chassis affected by the EPO event.

## Procedure

1. Verify that the EPO event did not damage the system hardware.

2. From `ncn-m001`, check the status of the chassis.

    ```bash
    cray capmc get_xname_status create --xnames x9000c[1,3]
    ```

    Example output:

    ```text
    e = 0
    err_msg = ""
    off = [ "x9000c1", "x9000c3",]
    ```

3. Check the Chassis Controller Module \(CCM\) log for `Critical` messages and the EPO event.

    A cabinet has eight chassis.

    ```bash
    kubectl logs -n services -l app.kubernetes.io/name=cray-capmc \
    -c cray-capmc --tail -1 | grep EPO -A 10
    ```

    Example output:

    ```text
    2019/10/24 02:37:30 capmcd.go:805: Message: Can not issue Enclosure Chassis.Reset 'On'|'Off' while in EPO state
    2019/10/24 02:37:30 capmcd.go:808: ExtendedInfo.Message: Can not issue Enclosure Chassis.Reset 'On'|'Off' while in EPO state
    2019/10/24 02:37:30 capmcd.go:809: ExtendedInfo.Resolution: Verify physical hardware, issue Enclosure Chassis.Reset --> 'ForceOff', and resubmit the request
    2019/10/24 02:37:31 capmcd.go:136: Info: <-- Bad Request (400) POST https://x1000c7b0/redfish/v1/ Chassis/Enclosure/Actions/Chassis.Reset (1.045967005s)
    2019/10/24 02:37:31 capmcd.go:799: POST https://x1000c7b0/redfish/v1/Chassis/Enclosure/Actions/Chassis.Reset
    !HTTP Error!
    ```

4. Disable the hms-discovery Kubernetes cron job.

    ```bash
    kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
    ```

    **CAUTION:** Do not power the system on until it is safe to do so. Determine why the EPO event occurred before clearing the EPO state.

5. **If it is safe to power on the hardware**, clear all chassis in the EPO state in the cooling group.

    All chassis in cabinets 1000-1003 are forced off in this example. Power off all chassis in a cooling group simultaneously, or the EPO condition may persist.

    ```bash
    cray capmc xname_off create --xnames x[1000-1003]c[0-7] --force true
    ```

    Example output:

    ```text
    e = 0
    err_msg = ""
    ```

    The HPE Cray EX EX TDS cabinet contains only two chassis: 1 \(bottom\) and 3 \(top\).

    ```bash
    cray capmc xname_off create --xnames x9000c[1,3] --force true
    ```

    Example output:

    ```text
    e = 0
    err_msg = ""
    ```

6. Restart the hms-discovery cron job.

    ```bash
    kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : false }}'
    ```

    About 5 minutes after hms-discovery restarts, the service will power on the chassis enclosures, switches, and compute blades. If components are not being powered back on, then power them on manually.

    ```bash
    cray capmc xname_on create \
    --xnames x[1000-1003]c[0-7]r[0-7],x[1000-1003]c[0-7]s[0-7] --prereq true --continue true
    ```

    Example output:

    ```text
    e = 0
    err_msg = ""
    ```

7. Verify the Slingshot fabric is up and healthy.
    Refer to the following documentation for more information on how to verify the health of the Slingshot Fabric:
    * The *Slingshot Administration Guide* PDF for HPE Cray EX systems.
    * The *Slingshot Troubleshooting Guide* PDF.

8. After the components have powered on, boot the nodes using the Boot Orchestration Services \(BOS\).

    See [Power On and Boot Compute and User Access Nodes](Power_On_and_Boot_Compute_Nodes_and_User_Access_Nodes.md).
