## Troubleshoot Common REDS Issues

This procedure provides troubleshooting steps for two different scenarios:

-   No nodes can be geolocated.
-   One of the nodes can be geolocated.

### Prerequisites

- The River Endpoint Discovery Service \(REDS\) failed to geolocate one or more nodes.
- The Cray command line interface \(CLI\) tool is initialized and configured on the system.

### Limitations

This procedure does not cover the list of all possible issues that can be encountered while using REDS. contact the Cray customer account representative to resolve issues not covered here.

### Procedure

1.  Use one of the following set of steps, depending on requirements/scenario.

    -   Perform the following set of steps if no nodes can be geolocated.
        1.  Check the status of the REDS pod to determine whether it is running.

            ```bash
            ncn-m001# kubectl get pods -n services | grep reds
            cray-reds-66d99d895c-2cpk9                       2/2       Running   0          48m
            ```

            -   If no result is returned, start REDS manually.

                ```bash
                ncn-m001# kubectl scale -n services --replicas=0 deployment cray-reds; \
                kubectl scale -n services --replicas=1 deployment cray-reds
                ```

                Wait at least three \(3\) minutes, then check the REDS pod status again. If REDS is now running, skip the rest of this procedure. If nodes still cannot be geolocated, restart this procedure.

            -   If a result is returned but the third column does not indicate `Running`, see [Troubleshoot Common Error Messages in REDS Logs](Troubleshoot_Common_Error_Messages_in_REDS_Logs.md).
            -   If a result is returned and the third column indicates `running`, there must be some other problem, so continue to the next step.
        2.  Check if REDS is able to communicate with the System Layout Service \(SLS\).

            1.  Set an environment variable.

                ```bash
                ncn-m001# REDSPOD=$(kubectl -n services get pods -l app.kubernetes.io/name=cray-reds \
                -o=custom-columns=:.metadata.name --no-headers)
                ncn-m001# echo $REDSPOD
                cray-reds-5854fdcd9d-ffgms
                ```

            2.  Check the logs.

                ```bash
                ncn-m001# kubectl -n services logs -f $REDSPOD cray-reds
                ```

            When finished viewing the log, press **Ctrl-c** to exit.

            -   If the following error message is in the log, REDS can't communicate with SLS. If nodes still cannot be geolocated, restart this procedure.

                ```
                WARNING: Unable to get new switch list:
                ```

            -   If messages like the following are in the log, then REDS can communicate with SLS. There must be some other problem, so proceed to the next step.

                ```
                Running periodic scan for XNAME
                ```

        3.  Check the logs to determine whether REDS configured the necessary artifacts in the artifact repository and BSS.

            1.  Set an environment variable.

                ```bash
                ncn-m001# REDSPOD=$(kubectl -n services get pods -l app.kubernetes.io/name=cray-reds-init \
                -o=custom-columns=:.metadata.name --no-headers)
                ncn-m001# echo $REDSPOD
                cray-reds-5854fdcd9d-ffgms
                ```

            2.  Check the logs.

                ```bash
                ncn-m001# kubectl -n services logs -f $REDSPOD cray-reds
                ```

            When finished viewing the log, press **Ctrl-c** to exit.

            -   If the last line of the log is the following, then REDS correctly configured artifacts in the artifact repository and BSS.

                ```
                Finished updates to BSS entry for Unknown-x86_64!
                ```

                There must be some other problem. Proceed to the next step.

            -   If that line is not present in the log, then there may be an issue with the artifact repository and/or BSS.
        
        4.  Observe the boot process of a node to determine whether the node is able to pull the images. Attach a monitor to the video port on the node and watch it boot. If it does not boot to a Linux login prompt, determine whether the network is up and working correctly \(for example, run ip a s on a non-compute node \(NCN\), or try pinging switches from an NCN\).
            -   If the network is not up and working correctly, troubleshoot the network.
            -   If the network is up and working correctly, then there must be some other problem. Contact the Cray customer account representative for this site.
    -   Perform the following set of steps if one of the nodes cannot be geolocated.
        1.  Look for the appropriate xname in the list of Redfish endpoints to determine whether the node has already been discovered.

            ```bash
            ncn-m001# cray hsm inventory redfishEndpoints list
            ```

        2.  Check the logs for indicators of common issues. See [Troubleshoot Common Error Messages in REDS Logs](Troubleshoot_Common_Error_Messages_in_REDS_Logs.md).
        3.  Determine whether the network is up and working correctly \(for example, run ip a s on an NCN, or try pinging switches from an NCN\).
            -   If the network is not up and working correctly, troubleshoot the network.
            -   If the network is up and working correctly, then there must be some other problem. Contact the Cray customer account representative for this site.

If the suggested troubleshooting steps do not resolve the issue, contact the Cray customer account representative for this site.
