# System Power On Procedures

The procedures in this section detail the high-level tasks required to power on an HPE Cray EX system.

**Important:** If an emergency power off \(EPO\) event occurred, then see [Recover from a Liquid-Cooled Cabinet EPO Event](Recover_from_a_Liquid_Cooled_Cabinet_EPO_Event.md) for recovery procedures.

If user IDs or passwords are needed, then see step 1 of the [Prepare the System for Power Off](Prepare_the_System_for_Power_Off.md#procedure) procedure.

## Note about services used during system power on

- The Power Control Service \(PCS\) service controls power to major components. PCS sequences the power on tasks in the correct order, but  **does not** determine if the required software services are running on the components.
- The Cray Advanced Platform Monitoring and Control \(CAPMC\) service can also control power to major components. CAPMC sequences the power on tasks in the correct order, but **does not** determine if the required software services are running on the components.
- The Boot Orchestration Service \(BOS\) manages and configures power on and boot tasks.
- The System Admin Toolkit \(SAT\) automates boot and shutdown services by stage.

## Power on cabinet circuit breakers and PDUs

Always use the cabinet power-on sequence for the site.

The management cabinet is the first part of the system that must be powered on and booted. Management network and Slingshot fabric switches power on and boot when cabinet power is applied. After
cabinets are powered on, wait at least 10 minutes for systems to initialize.

After all the system cabinets are powered on, be sure that all management network and Slingshot network switches are powered on, and that there are no error LEDS or hardware failures.

## Power On the External File Systems

To power on an external Lustre file system (ClusterStor), refer to [Power On the External Lustre File System](Power_On_the_External_Lustre_File_System.md).

To power on the external Spectrum Scale (GPFS) file system, refer to site procedures.

**Note:** If the external file systems are not mounted on worker nodes, then continue to power them in parallel with
the power on and boot of the Kubernetes management cluster and the power on of the compute cabinets. This must be completed
before beginning to power on and boot the compute nodes and User Access Nodes (UANs).

## Power on and boot the Kubernetes management cluster

To power on the management cabinet and bring up the management Kubernetes cluster, refer to [Power On and Start the Management Kubernetes Cluster](Power_On_and_Start_the_Management_Kubernetes_Cluster.md).

## Power on compute cabinets

To power on all liquid-cooled cabinet CDUs and cabinet PDUs, refer to [Power On Compute Cabinets](Power_On_Compute_Cabinets.md).

## Power on and boot managed nodes

+**Note:** Ensure that the external Lustre and Spectrum Scale (GPFS) filesystems are available before starting to boot the compute nodes and UANs.

To power on and boot managed compute nodes and application nodes, such as the User Access Nodes (UANs), refer to
[Power On and Boot Managed Nodes](Power_On_and_Boot_Managed_Nodes.md).

## Run system health checks

After power on, refer to [Validate CSM Health](../validate_csm_health.md) to check system health and status.

## Make nodes available to users

Make nodes available to users once system health and any other post-system maintenance checks have completed.
