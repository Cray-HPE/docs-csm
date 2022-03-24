# System Power On Procedures

The procedures in section detail the high-level tasks required to power on an HPE Cray EX system.

**Important:** If an emergency power off \(EPO\) event occurred, see [Recover from a Liquid Cooled Cabinet EPO Event](Recover_from_a_Liquid_Cooled_Cabinet_EPO_Event.md) for recovery procedures.

-   The Cray Advanced Platform Monitoring and Control \(CAPMC\) service controls power to major components. CAPMC sequences the power on tasks in the correct order, but **does not** determine if the required software services are running on the components.
-   The Boot Orchestration Service \(BOS\) manages and configures power on and boot tasks.
-   The System Admin Toolkit \(SAT\) automates boot and shutdown services by stage, for example: 

    ```screen
    sat bootsys boot --stage platform-services
    ```

    ```screen
    sat bootsys boot --stage bos-operations
    ```


### Get User IDs and Passwords

-   Obtain user ID and password for all the system management network switches, for example:

    ```screen
    sw-spine-001.mtl
    sw-spine-002.mtl
    sw-leaf-001.mtl
    sw-leaf-002.mtl
    sw-cdu-001.mtl
    sw-cdu-002.mtl
    ```

-   Obtain the user ID and password for the ClusterStor primary management node. For example, cls01234n000.
-   Obtain the user ID and password for all edge switches.
-   Determine the correct Boot Orchestration Service \(BOS\) templates that should be used to boot compute nodes and UANs, for example:
    -   Compute nodes: `slurm`
    -   UANs: `uan-slurm`

### Power on Cabinet Circuit Breakers and PDUs

Always use the cabinet power-on sequence for the customer site.

The management cabinet is the first part of the system that must be powered on and booted. Management network and Slingshot fabric switches power on and boot when cabinet power is applied. After cabinets are powered on, wait at least 10 minutes for systems to initialize.

-   To power on all liquid-cooled cabinet CDUs and cabinet PDUs, see [Power On Compute and IO Cabinets](Power_On_Compute_and_IO_Cabinets.md).
-   To power on all remaining system cabinet CDUs and PDUs.

After all the system cabinets are powered on, be sure that all management network and Slingshot network switches are powered on and there are no error LEDS or hardware failures.

### Power on and Boot the Kubernetes Management Cluster

To power on the management cabinet and bring up the management Kubernetes cluster, refer to [Power On and Start the Management Kubernetes Cluster](Power_On_and_Start_the_Management_Kubernetes_Cluster.md).

### Power on the External Lustre File System

To power an external Lustre file system (ClusterStor), see [Power On the External Lustre File System](Power_On_the_External_Lustre_File System.md).

### Bring up the Slingshot Fabric

To bring up the Slingshot fabric, see:

-   The *Slingshot Administration Guide* for Cray EX systems PDF.
-   The *Slingshot Troubleshooting Guide* PDF.

### Power On and Boot Compute Nodes and User Access Nodes \(UANs\)

To power on and boot compute nodes and UANs, refer to [Power On and Boot Compute and User Access Nodes](Power_On_and_Boot_Compute_Nodes_and_User_Access_Nodes.md) and make nodes available to customers.

### Run System Health Checks

After power on, refer to [Validate CSM Health](../validate_csm_health.md) to check system health and status.

