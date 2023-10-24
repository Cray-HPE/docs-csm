# Ignore Nodes with CAPMC

Update the Cray Advanced Platform Monitoring and Control \(CAPMC\) ConfigMap to ignore non-compute nodes \(NCNs\) and ensure that they cannot be powered off or reset.

Modifying the CAPMC ConfigMap to ignore nodes can prevent them from accidentally being power cycled.

Nodes can also be locked with the Hardware State Manager \(HSM\) API. Refer to [Lock and Unlock Management Nodes](../hardware_state_manager/Lock_and_Unlock_Management_Nodes.md) for more information.

## Prerequisites

This procedure requires administrative privileges.

## Procedure

1. (`ncn-mw#`) Edit the CAPMC ConfigMap.

    ```bash
    kubectl -n services edit configmaps cray-capmc-configuration
    ```

1. Uncomment the `# BlockRole = ["Management"]` value in the `[PowerControls.Off]`, `[PowerControls.On]`, and `[PowerControls.ForceRestart]` sections.

1. Save and quit the ConfigMap.

    CAPMC restarts using the new ConfigMap.
