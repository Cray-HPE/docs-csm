# Recover from a Liquid Cooled Cabinet EPO Event

Identify an emergency power off \(EPO\) has occurred and restore cabinets to a healthy state.

**CAUTION:** Verify the reason why the EPO occurred and resolve that problem before clearing the EPO state.

If a Cray EX liquid-cooled cabinet or cooling group experiences an EPO event, the compute nodes may not boot. Use PCS to force off all the chassis affected by the EPO event.

## Procedure

1. Verify that the EPO event did not damage the system hardware.

2. From `ncn-m001`, check the status of the chassis.

    ```bash
    cray power status list --xnames "x9000c[1,3]" --format json
    ```

    Example output:

    ```json
    {
      "status": [
        {
          "xname": "x9000c1",
          "powerState": "off",
          "managementState": "available",
          "error": "",
          "supportedPowerTransitions": [
            "On",
            "Force-Off",
            "Soft-Off",
            "Off",
            "Init",
            "Hard-Restart",
            "Soft-Restart"
          ],
          "lastUpdated": "2023-02-08T23:20:31.322689726Z"
        },
        {
          "xname": "x9000c3",
          "powerState": "off",
          "managementState": "available",
          "error": "",
          "supportedPowerTransitions": [
            "On",
            "Force-Off",
            "Soft-Off",
            "Off",
            "Init",
            "Hard-Restart",
            "Soft-Restart"
          ],
          "lastUpdated": "2023-02-08T23:20:31.322689726Z"
        }
      ]
    }
    ```

3. Check the Chassis Controller Module \(CCM\) log for `Critical` messages and the EPO event.

    A cabinet has eight chassis.

    ```bash
    kubectl logs -n services -l app.kubernetes.io/name=cray-power-control \
    -c cray-power-control --tail -1 | grep EPO -A 10
    ```

4. Disable the hms-discovery Kubernetes cron job.

    ```bash
    kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
    ```

    **CAUTION:** Do not power the system on until it is safe to do so. Determine why the EPO event occurred before clearing the EPO state.

5. **If it is safe to power on the hardware**, clear all chassis in the EPO state in the cooling group.

    All chassis in cabinets 1000-1003 are forced off in this example. Power off all chassis in a cooling group simultaneously, or the EPO condition may persist.

    ```bash
    cray power transition force-off --xnames "x[1000-1003]c[0-7]" --format json
    cray power transition describe b2c7e5d2-4575-4b70-b07e-f9cbb722c02c --format json
    ```

    Example output:

    ```json
    {
      "transitionID": "b2c7e5d2-4575-4b70-b07e-f9cbb722c02c",
      "operation": "Force-Off",
      "createTime": "2023-02-09T02:02:37.454064684Z",
      "automaticExpirationTime": "2023-02-10T02:02:37.454064752Z",
      "transitionStatus": "completed",
      "taskCounts": {
        "total": 32,
        "new": 0,
        "in-progress": 0,
        "failed": 0,
        "succeeded": 32,
        "un-supported": 0
      },
      "tasks": [
        {
          "xname": "x1000c0",
          "taskStatus": "succeeded",
          "taskStatusDescription": "Transition confirmed, forceoff"
        },
        ...
      ]
    }
    ```

    The HPE Cray EX TDS cabinet contains only two chassis: 1 \(bottom\) and 3 \(top\).

    ```bash
    cray power transition force-off --xnames "x9000c[1,3]" --format json
    cray power transition describe f9445021-f9bc-4f7b-bbe1-7ef643259094 --format json
    ```

    Example output:

    ```json
    {
      "transitionID": "f9445021-f9bc-4f7b-bbe1-7ef643259094",
      "operation": "Force-Off",
      "createTime": "2023-02-09T02:02:37.454064684Z",
      "automaticExpirationTime": "2023-02-10T02:02:37.454064752Z",
      "transitionStatus": "completed",
      "taskCounts": {
        "total": 2,
        "new": 0,
        "in-progress": 0,
        "failed": 0,
        "succeeded": 2,
        "un-supported": 0
      },
      "tasks": [
        {
          "xname": "x9000c1",
          "taskStatus": "succeeded",
          "taskStatusDescription": "Transition confirmed, forceoff"
        },
        {
          "xname": "x9000c3",
          "taskStatus": "succeeded",
          "taskStatusDescription": "Transition confirmed, forceoff"
        }
      ]
    }
    ```

6. Restart the hms-discovery cron job.

    ```bash
    kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : false }}'
    ```

    About 5 minutes after hms-discovery restarts, the service will power on the chassis enclosures, switches, and compute blades. If components are not being powered back on, then power them on manually.

    ```bash
    cray power transition on --xnames "x[1000-1003]c[0-7]" --format json
    cray power transition on --xnames "x[1000-1003]c[0-7]s[0-7]" --format json
    cray power transition on --xnames "x[1000-1003]c[0-7]r[0-7]" --format json
    ```

    Verify the status of each of the power operations.

    ```bash
    cray power transition describe TRANSITION_ID --format json
    ```

7. Bring up the Slingshot Fabric.
    Refer to the following documentation for more information on how to bring up the Slingshot Fabric:
    * The *Slingshot Administration Guide* PDF for HPE Cray EX systems.
    * The *Slingshot Troubleshooting Guide* PDF.

8. After the components have powered on, boot the nodes using the Boot Orchestration Services \(BOS\).

    See [Power On and Boot Compute and User Access Nodes](../Power_On_and_Boot_Compute_Nodes_and_User_Access_Nodes.md).
