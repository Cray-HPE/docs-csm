# System Power On Procedures

The procedures in this section detail the high-level tasks required to power on an HPE Cray EX system.

**Important:** If an emergency power off \(EPO\) event occurred, then see [Recover from a Liquid-Cooled Cabinet EPO Event](Recover_from_a_Liquid_Cooled_Cabinet_EPO_Event.md) for recovery procedures.

If user IDs or passwords are needed, then see step 1 of the [Prepare the System for Power Off](Prepare_the_System_for_Power_Off.md#procedure) procedure.

## Note about services used during system power on

- The Cray Advanced Platform Monitoring and Control \(CAPMC\) service controls power to major components. CAPMC sequences the power on tasks in the correct order, but **does not** determine if the required software services are running on the components.
- The Boot Orchestration Service \(BOS\) manages and configures power on and boot tasks.
- The System Admin Toolkit \(SAT\) automates boot and shutdown services by stage.

## Power on cabinet circuit breakers and PDUs

Always use the cabinet power-on sequence for the site.

The management cabinet is the first part of the system that must be powered on and booted. Management network and Slingshot fabric switches power on and boot when cabinet power is applied. After
cabinets are powered on, wait at least 10 minutes for systems to initialize.

After all the system cabinets are powered on, be sure that all management network and Slingshot network switches are powered on, and that there are no error LEDS or hardware failures.

## Power on the external Lustre file system

To power on an external Lustre file system (ClusterStor), refer to [Power On the External Lustre File System](Power_On_the_External_Lustre_File_System.md).

## Power on and boot the Kubernetes management cluster

To power on the management cabinet and bring up the management Kubernetes cluster, refer to [Power On and Start the Management Kubernetes Cluster](Power_On_and_Start_the_Management_Kubernetes_Cluster.md).

## Power on compute cabinets

To power on all liquid-cooled cabinet CDUs and cabinet PDUs, refer to [Power On Compute Cabinets](Power_On_Compute_Cabinets.md).

## Power on and boot compute nodes and user access nodes \(UANs\)

To power on and boot compute nodes and UANs, refer to [Power On and Boot Compute and User Access Nodes](Power_On_and_Boot_Compute_Nodes_and_User_Access_Nodes.md) and make nodes available to users.

## Run system health checks

After power on, refer to [Validate CSM Health](../validate_csm_health.md) to check system health and status.
