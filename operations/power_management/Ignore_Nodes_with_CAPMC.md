

## Ignore Nodes with CAPMC

Edit the CAPMC configmap to ignore nodes.

This procedure requires administrative privileges.

-   **ROLE**

    System administrator

-   **OBJECTIVE**

    Update the Cray Advanced Platform Monitoring and Control \(CAPMC\) configmap to ignore non-compute nodes \(NCNs\) and ensure they can not be powered off or reset.

    Nodes can also be locked with the Hardware State Manager \(HSM\) API. Refer to [NCN and Management Node Locking](NCN_and_Management_Node_Locking.md) for more information.

-   **ADMIN IMPACT**

    Modifing the CAPMC configmap to ignore nodes can prevent them from accidentally being power cycled.

-   **LIMITATIONS**

    None.

-   **NEW IN THIS RELEASE**

    This procedure is new in release 1.4.

1.  Edit the CAPMC configmap.

    ```screen
    ncn-m001# kubectl -n services edit configmaps cray-capmc-configuration
    ```
    
2.  Uncomment the \# BlockRole = \["Management"\] value in the \[PowerControls.Off\], \[PowerControls.On\], and \[PowerControls.ForceRestart\] sections.

3.  Save and quit the configmap.

    CAPMC restarts using the new configmap.

