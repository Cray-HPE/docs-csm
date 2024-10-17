# System Power Off Procedures

The procedures in this section detail the high-level tasks required to power off an HPE Cray EX system.

## Note about Services Used During System Power Off

- The Power Control Service \(PCS\) service controls power to major components. PCS sequences the power off tasks in the correct order, but  **does not** determine if the required software services are running on the components.
- The Cray Advanced Platform Monitoring and Control \(CAPMC\) service can also control power to major components. CAPMC sequences the power off tasks in the correct order, but **does not** determine if the required software services are running on the components.
- The Boot Orchestration Service \(BOS\) manages proper shutdown and power off tasks for compute nodes and User Access Nodes \(UANs\).
- The System Admin Toolkit \(SAT\) automates shutdown services by stage.

## Prepare the System for Power Off

To make sure that the system is healthy before power off and all the information is collected, refer to [Prepare the System for Power Off](Prepare_the_System_for_Power_Off.md).

## Shut Down Compute Nodes and UANs

To shut down compute nodes and User Access Nodes \(UANs\), refer to [Shut Down and Power Off Managed Nodes](Shut_Down_and_Power_Off_Managed_Nodes.md).

## Power Off the External File Systems

To power off the external Lustre file system (ClusterStor), refer to [Power Off the External Lustre File System](Power_Off_the_External_Lustre_File_System.md).

To power off the external Spectrum Scale (GPFS) file system, refer to site procedures.

## Save Management Network Switch Settings

To save management switch configuration settings, refer to [Save Management Network Switch Configuration Settings](Save_Management_Network_Switch_Configurations.md).

## Power Off System Cabinets

If any of the external file systems are in air-cooled cabinets shared with air-cooled compute nodes or management nodes, then
the power off of the PDU circuits in these cabinets should be delayed until the external Lustre or Spectrum Scale (GPFS) file
systems have been cleanly shut down.

To power off standard rack and liquid-cooled cabinet PDUs, refer to [Power Off Compute Cabinets](Power_Off_Compute_Cabinets.md).

To power off standard racks which have only storage nodes and switches, refer to [Power Off Storage Cabinets](Power_Off_Storage_Cabinets.md).

## Shut Down the Management Kubernetes Cluster

To shut down the management Kubernetes cluster, refer to [Shut Down and Power Off the Management Kubernetes Cluster](Shut_Down_and_Power_Off_the_Management_Kubernetes_Cluster.md).

## Power Off Management Cabinets

To power off management cabinets, refer to [Power Off Management Cabinets](Power_Off_Management_Cabinets.md).

## `Lockout Tagout` Facility Power

If facility power must be removed from a single cabinet or cabinet group for maintenance, follow proper `lockout-tagout` procedures for the site.
