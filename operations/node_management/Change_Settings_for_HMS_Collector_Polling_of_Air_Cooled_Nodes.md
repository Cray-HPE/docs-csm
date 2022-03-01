## Change Settings for HMS Collector Polling of Air Cooled Nodes

The cray-hms-hmcollector service polls all Air Cooled hardware to gather the necessary telemetry information for use by other services, such as the Cray Advanced Platform Monitoring and Control \(CAPMC\) service. This polling occurs every 10 seconds on a continual basis. Instabilities with the AMI Redfish implementation in the Gigabyte BMCs requires a less significant approach when gathering power and temperature telemetry data. If the BMCs are overloaded, they can become unresponsive, return incorrect data, or encounter other errors.

All of these issues prevent other services, such as CAPMC and the Firmware Action Service \(FAS\), from successfully acting on the BMCs. Recovery from this state requires a BMC reset and sometimes a hard power cycle by unplugging the server and plugging it back in.

Collecting telemetry data while trying to boot Air Cooled compute nodes increases the burden on the BMCs and increases the likelihood of BMC issues. The most likely time to encounter BMCs in a bad state is when trying to boot Air Cooled compute nodes and User Access Nodes \(UANs\) using the Boot Orchestration Service, or when trying to do a firmware and/or BIOS update on the nodes. Check the service logs of CAPMC and FAS for error information returned from the BMCs.

### Recommendations for Polling

The following are the best practices for using the HMS Collector polling:

-   Do not query the power state of Air Cooled nodes using CAPMC more than two or three times a minute.
    -   This is done via the CAPMC `get_xname_status` command.

        ```bash
        ncn# cray capmc get_xname_status create --xnames LIST_OF_NODES
        ```

-   Polling of Air Cooled nodes should be disabled by default. Before nodes are booted, verify that `cray-hms-hmcollector` polling is disabled.
    -   To check if polling is disabled:

        ```bash
        ncn# kubectl get deployments.apps -n services cray-hms-hmcollector -o json | jq \
        '.spec.template.spec.containers[].env[]|select(.name=="POLLING_ENABLED")'
        ```

    -   To disable polling if it is not already:

        ```bash
        ncn# kubectl edit deployment -n services cray-hms-hmcollector
        ```

        Change the value for the `POLLING_ENABLED` environment variable to `false` in the `spec:` section. Save and quit the editor for the changes to take effect. The `cray-hms-hmcollector` pod will automatically restart.

-   Only enable telemetry polling when needed, such as when running jobs.

    ```bash
    ncn# kubectl edit deployment -n services cray-hms-hmcollector
    ```

    Change the value for the `POLLING_ENABLED` environment variable to `true` in the `spec:` section. Save and quit the editor for the changes to take effect. The `cray-hms-hmcollector` pod will automatically restart.

-   If BMCs are encountering issues at a high rate, increase the polling interval. Do not set the polling interval to less than the default of 10s.

    ```bash
    ncn# kubectl edit deployment -n services cray-hms-hmcollector
    ```

    Change the value for the `POLLING_INTERVAL` environment variable to the selected rate in seconds. This value is located in the `spec:` section. Save and quit the editor for the changes to take effect. The `cray-hms-hmcollector` pod will automatically restart.


### Reset BMCs in a Bad State

Even with the polling recommendations above, it is still possible for the BMCs to end up in a bad state and will require a reset.

To restart the BMCs:

```bash
ncn# export USERNAME=root
ncn# export IPMI_PASSWORD=changeme
ncn# ipmitool -H BMC_HOSTNAME -U $USERNAME -E -I lanplus mc reset cold
```

If the reset does not recover the BMCs, then use the following steps to shut down the nodes, unplug the servers, and plug them back in:

1.  Shut down the nodes.

    For each server with a BMC in a bad state:

    ```bash
    ncn# ipmitool -H BMC_HOSTNAME -U $USERNAME -E -I lanplus chassis power soft
    ```

    Wait 30 seconds after shutting down the nodes before proceeding.

2.  Unplug the server Power Supply Units \(PSUs\) and wait 30 seconds.

3.  Plug both server PSUs back in.

    Wait a couple of minutes before proceeding.

4.  Verify the BMCs are available again.

    ```bash
    ncn# ping -c 1 BMC_HOSTNAME
    ```

5.  Check the power of the nodes.

    ```bash
    ncn# cray capmc get_xname_status create --xnames LIST_OF_NODES
    ```

After these steps, the nodes should be ready to be booted again with the Boot Orchestration Service (BOS).



