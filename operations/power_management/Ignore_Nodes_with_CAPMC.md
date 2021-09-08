

## Ignore Nodes with CAPMC

Update the Cray Advanced Platform Monitoring and Control \(CAPMC\) configmap to ignore non-compute nodes \(NCNs\) and ensure they cannot be powered off or reset.

Modifying the CAPMC configmap to ignore nodes can prevent them from accidentally being power cycled.

Nodes can also be locked with the Hardware State Manager \(HSM\) API. Refer to [Lock and Unlock Management Nodes](../hardware_state_manager/Lock_and_Unlock_Management_Nodes.md) for more information.

### Prerequisites

This procedure requires administrative privileges.

### Procedure

1.  Edit the CAPMC configmap.

    ```bash
    ncn-m001# kubectl -n services edit configmaps cray-capmc-configuration
    ```

2.  Uncomment the \# BlockRole = \["Management"\] value in the \[PowerControls.Off\], \[PowerControls.On\], and \[PowerControls.ForceRestart\] sections.

3.  Save and quit the configmap.

    CAPMC restarts using the new configmap.

