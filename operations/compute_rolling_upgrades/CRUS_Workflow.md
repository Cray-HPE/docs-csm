# CRUS Workflow

The following workflow is intended to be a high-level overview of how to upgrade compute nodes. This workflow depicts how services interact with each other during the compute node upgrade process, and helps to provide a quicker and deeper understanding of how the system functions.

### Upgrade Compute Nodes

**Use Cases:** Administrator upgrades select compute nodes \(around 500\) to a newer compute image by using Compute Rolling Upgrade Service \(CRUS\).

**Requirement** The compute nodes are up and running and their workloads are managed by Slurm.

**Components:** This workflow is based on the interaction of CRUS with Boot Orchestration Service \(BOS\) and Slurm \(Workload Manager\).

Mentioned in this workflow:

-   Compute Rolling Upgrade Service \(CRUS\) allows an administrator to modify the boot image and/or configuration on a set of compute nodes without the need to take the entire set of nodes out of service at once. It manages the workload management status of nodes, quiescing each node before taking the node out of service, upgrading the node, rebooting the node into the upgraded state and then returning the node to service within the workload manager.
-   Boot Orchestration Service \(BOS\) is responsible for booting, configuring, and shutting down collections of nodes. The Boot Orchestration Service has the following components:
    -   Boot Orchestration Session Template is a collection of one or more boot set objects. A boot set defines a collection of nodes and the information about the boot artifacts and parameters.
    -   Boot Orchestration Session carries out an operation. The possible operations in a session are boot, shutdown, reboot, and configure.
    -   Boot Orchestration Agent \(BOA\) is automatically launched to execute the session. A BOA executes the given operation, and if the operation is a boot or a reboot, it also configures the nodes post-boot \(if configure is enabled\).
-   Slurm has a component called slurmctld that runs on a non-compute node in a container. The Slurm control daemon or slurmctld is the central management daemon of Slurm. It monitors all other Slurm daemons and resources, accepts jobs, and allocates resources to those jobs. Slurm also has a component called slurmd that runs on all compute nodes. The Slurm daemon or slurmd monitors all tasks running on the compute node, accepts tasks, launches tasks, and kills running tasks upon request.

![CRUS Upgrade Workflow](../../img/operations/crus_upgrade.gif)

**Workflow Overview:** The following sequence of steps occur during this workflow.

1.  **Administrator creates HSM groups and populates the starting group**

    Create three HSM groups with starting, failed, and upgrading labels.

    For example: crusfailed, crusupgrading, and crus\_starting.

    Add all of the 500 compute nodes to be updated to the crus\_starting group. Leave the failed and upgrading groups empty.

2.  **Administrator creates a session template**

    Create a BOS session template which points to the new image, the desired CFS configuration, and with a boot set which includes all the compute nodes to be updated. The boot set can include additional nodes, but it must contain all the nodes that need to be updated. The BOS session template you use should specify "upgrading\_label" in the "node\_groups" field of one of its boot sets.

    For example: newcomputetemplate.

3.  **Administrator creates a CRUS session**

    A new upgrade session is launched as a result of this call.

    Specify the following parameters:

    -   failed\_label: An empty Hardware State Manager \(HSM\) group which CRUS will populate with any nodes that fail their upgrades.
    -   starting\_label: An HSM group which contains the total set of nodes to be upgraded. Example: 500.
    -   upgrading\_label: An empty HSM group which CRUS will use to boot and configure the discrete sets of nodes.
    -   upgradestepsize: The number of nodes to include in each discrete upgrade step.

        The upgrade steps will never exceed this quantity, although in some cases they may be smaller. Example: 50

    -   upgradetemplateid: The name of the BOS session template to use for the upgrades. A session template is a collection of metadata for a group of nodes and their desired configuration.
    -   workloadmanagertype: Currently only slurm is supported.

4.  **CRUS to HSM**

    CRUS calls HSM to find the nodes in the starting\_label group.

5.  **CRUS to HSM**

    It then takes a number of these nodes equal to the step size \(50\), and calls HSM to put them into the upgrading\_label group.

6.  **CRUS to Slurm**

    CRUS tells Slurm to quiesce these nodes. As each node is quiesced, Slurm puts the node offline.

7.  **Slurm to CRUS**

    Slurm reports back to CRUS that all of the nodes as offline.

8.  **CRUS to BOS**

    CRUS calls BOS to create a session with the following arguments:

    -   operation: reboot
    -   templateUuid: upgrade*template*id
    -   limit: upgrading\_label

9.  **CRUS retrieves the BOA job details from BOS**

    CRUS retrieves the BOS session to get the BOA job name. CRUS waits for the BOA job to finish.

    CRUS looks at the exit code of the BOA job to determine whether or not there were errors.

    If there were errors, CRUS adds the nodes from the upgrading\_label group into the failed\_label group.

10. **CRUS to HSM**

    After the BOA job is complete, CRUS calls HSM to empty the upgrading\_label group.

11. **CRUS repeats steps for remaining nodes, then updates status**

    CRUS repeats steps **5-10** until all of the nodes from the starting\_label group have gone through these steps. After this, CRUS marks the session status as "complete".

