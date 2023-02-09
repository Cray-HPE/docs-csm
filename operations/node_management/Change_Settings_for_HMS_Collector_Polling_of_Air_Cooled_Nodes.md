# Change Settings for HMS Collector Polling of Air-Cooled Nodes

The `cray-hms-hmcollector` service polls all air-cooled hardware to gather the necessary telemetry information
for telemetry purposes. This polling occurs every 10 seconds on a continual basis. Instabilities with the AMI
Redfish implementation in the Gigabyte BMCs require a less significant approach when gathering power and
temperature telemetry data. If the BMCs are overloaded, they can become unresponsive, return incorrect data,
or encounter other errors.

All of these issues prevent other services, such as PCS/CAPMC and the Firmware Action Service \(FAS\), from
successfully acting on the BMCs. Recovery from this state requires a BMC reset and sometimes a hard power
cycle by unplugging the server and plugging it back in.

Collecting telemetry data while trying to boot air-cooled compute nodes increases the burden on the BMCs and
increases the likelihood of BMC issues. The most likely time to encounter BMCs in a bad state is when trying
to boot air-cooled compute nodes and User Access Nodes \(UANs\) using the Boot Orchestration Service, or when
trying to do a firmware or BIOS update on the nodes. Check the service logs of PCS/CAPMC and FAS for error
information returned from the BMCs.

## Recommendations for polling

The following are the best practices for using the HMS Collector polling:

- (`ncn#`) Do not query the power state of air-cooled nodes using CAPMC more than two or three times a minute.

  - This is done via the CAPMC `get_xname_status` command.
  - The Cray CLI must be configured on the node where this command is run. See [Configure the Cray CLI](../configure_cray_cli.md).

      ```bash
      cray capmc get_xname_status create --xnames LIST_OF_NODES
      ```

- Polling of air-cooled nodes should be disabled by default. Before nodes are booted, verify that `cray-hms-hmcollector` polling is disabled.

  - (`ncn-mw#`) To check if polling is disabled:

      ```bash
      kubectl get deployments.apps -n services cray-hms-hmcollector -o json | \
               jq '.spec.template.spec.containers[].env[]|select(.name=="POLLING_ENABLED")'
      ```

  - (`ncn-mw#`) To disable polling, if it is not already disabled:

      ```bash
      kubectl edit deployment -n services cray-hms-hmcollector
      ```

      Change the value for the `POLLING_ENABLED` environment variable to `false` in the `spec:` section. Save and quit the editor for the changes to take effect. The
      `cray-hms-hmcollector` pod will automatically restart.

- (`ncn-mw#`) Only enable telemetry polling when needed, such as when running jobs.

    ```bash
    kubectl edit deployment -n services cray-hms-hmcollector
    ```

    Change the value for the `POLLING_ENABLED` environment variable to `true` in the `spec:` section. Save and quit the editor for the changes to take effect. The `cray-hms-hmcollector` pod will automatically restart.

- (`ncn-mw#`) If BMCs are encountering issues at a high rate, then increase the polling interval. Do not set the polling interval to less than the default of 10 seconds.

    ```bash
    kubectl edit deployment -n services cray-hms-hmcollector
    ```

    Change the value for the `POLLING_INTERVAL` environment variable to the selected rate in seconds. This value is located in the `spec:` section. Save and quit the editor
    for the changes to take effect. The `cray-hms-hmcollector` pod will automatically restart.

## Reset BMCs in a bad state

Even with the polling recommendations above, it is still possible for the BMCs to end up in a bad state, necessitating a reset.

(`ncn#`) To restart the BMCs:

> `read -s` is used to prevent the password from being written to the screen or the shell history.

```bash
USERNAME=root
read -r -s -p "BMC ${USERNAME} password: " IPMI_PASSWORD
export IPMI_PASSWORD
ipmitool -H BMC_HOSTNAME -U "${USERNAME}" -E -I lanplus mc reset cold
```

If the reset does not recover the BMCs, then use the following steps to shut down the nodes, unplug the servers, and plug them back in:

1. (`ncn#`) Shut down the nodes.

    For each server with a BMC in a bad state:

    ```bash
    ipmitool -H BMC_HOSTNAME -U "${USERNAME}" -E -I lanplus chassis power soft
    ```

    Wait 30 seconds after shutting down the nodes before proceeding.

1. Unplug the server Power Supply Units \(PSUs\) and wait 30 seconds.

1. Plug both server PSUs back in.

    Wait at least two minutes before proceeding.

1. (`ncn#`) Verify that the BMCs are available again.

    ```bash
    ping -c 1 BMC_HOSTNAME
    ```

1. (`ncn#`) Check the power of the nodes.

    ```bash
    cray capmc get_xname_status create --xnames LIST_OF_NODES
    ```

After these steps, the nodes should be ready to be booted again with the Boot Orchestration Service (BOS).
