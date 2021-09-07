

## System Power Off Procedures

The procedures in section detail the high-level tasks required to power off an HPE Cray EX system.

-   The Cray Advanced Platform Monitoring and Control \(CAPMC\) service controls power to major components. CAPMC sequences the power off tasks in the correct order, but **does not** gracefully shut down software services.
-   The Boot Orchestration Service \(BOS\) manages proper shutdown and power off tasks for compute nodes and User Access Nodes \(UANs\).
-   The System Admin Toolkit \(SAT\) automates shutdown services by stage, for example:

    ```screen
    sat bootsys shutdown --stage platform-services
    ```

    ```screen
    sat bootsys shutdown --stage bos-operations
    ```


### Prepare the System for Power Off

To make sure that the system is healthy before power off and all the information is collected, [Prepare the System for Power Off](Prepare_the_System_for_Power_Off.md).

### Shut Down Compute Nodes and UANs

To shut down compute nodes and User Access Nodes \(UANs\) see [Shut Down and Power Off Compute and User Access Nodes](Shut_Down_and_Power_Off_Compute_and_User_Access_Nodes.md).

### Save Management Network Switch Settings

To save management switch configuration settings, see [Save Management Network Switch Configuration Settings](Save_Management_Network_Switch_Configurations.md).

### Power Off System Cabinets

To power off standard rack and liquid-cooled cabinet PDUs, see [Power Off Compute and IO Cabinets](Power_Off_Compute_and_IO_Cabinets.md).

#### Shut Down the Management Kubernetes Cluster

Shut down the management Kubernetes cluster, see [Shut Down and Power Off the Management Kubernetes Cluster](Shut_Down_and_Power_Off_the_Management_Kubernetes_Cluster.md).

### Lockout Tagout Facility Power

If facility power must be removed from a single cabinet or cabinet group for maintenance, follow proper lockout-tagout procedures for the site.






