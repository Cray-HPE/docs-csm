## Initialize and Geolocate Nodes

This procedure initializes and geolocates compute nodes. Initialization provides base configuration for system hardware. Geolocation adds compute nodes to the Hardware State Manager \(HSM\) service.

This procedure is performed automatically during installation of the system's software. Perform this procedure manually as part of cold-starting a system, which must be done whenever there is a power outage or when new compute nodes are added to the system.

### Prerequisites

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.
-   Management network switches have been configured for the River Endpoint Discovery Service \(REDS\). See [Configure a Management Switch for REDS](Configure_a_Management_Switch_for_REDS.md).
-   Check the REDS pod's state by executing the following command to ensure that it is in the `Running` state.

    ```bash
    ncn-m001# kubectl get pods -n services | grep reds
    cray-reds-66d99d895c-2cpk9             2/2        Running   0    48m
    ```

    If it is not running, see Scenario 1 of [Troubleshoot Common REDS Issues](Troubleshoot_Common_REDS_Issues.md).

-   Check to see if the pod for MEDS is in a `Running` state.

    ```bash
    ncn-m001# kubectl get pods -n services | grep meds
    cray-meds-8b76c7566-bhtml              2/2        Running   0    12d
    ```

### Procedure


1.  View the Redfish endpoints inventory to determine whether any endpoints are already present.

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints list
    ```

    If the endpoint for the node to be discovered is already present, skip the rest of this procedure. Otherwise, proceed to the next step.

2.  Power on all nodes that need to be initialized and geolocated.

    This can be done by pressing the power button on the machine or by using the BMC console interface \(if BMC credentials are known\). If the node is already powered on, power it off for a minimum of two minutes before powering it back on.

3.  Wait about five minutes for all nodes to power on.

4.  View the Redfish endpoints inventory again to verify that new endpoints have been added.

    ```bash
    ncn-m001# cray hsm inventory redfishEndpoints list
    ```


The power-cycled compute nodes have been initialized and geolocated. The geolocation process powers nodes off when discovery is complete. Nodes that do not power down have had discovery issues.

If geolocation has failed for one or more compute nodes, see [Troubleshoot Common REDS Issues](Troubleshoot_Common_REDS_Issues.md).

