# Configuration Management

The Configuration Framework Service \(CFS\) is available on systems for remote execution and configuration management of nodes and boot images.
This includes nodes available in the Hardware State Manager \(HSM\) inventory \(compute, management, and application nodes\), and boot images hosted by the Image Management Service \(IMS\).

CFS configures nodes and images via a `gitops` methodology. All configuration content is stored in a version control service \(VCS\), and is managed by authorized system administrators.
CFS provides a scalable Ansible Execution Environment \(AEE\) for the configuration to be applied with flexible inventory and node targeting options.

## Use Cases

CFS is available for the following use cases on systems:

* Image customization: Pre-configure bootable images available via IMS. This use case enables provisioning a full configuration of a target node.
Non-node-specific settings are applied pre-boot, which reduces the amount of configuration required after a node boots, and therefore reduces the bring-up time for nodes.
* Post-boot configuration: Fully configure or reconfigure booted nodes in a scalable, performant way to add the required settings.
* "Push-based" deployment: When using post-boot configuration with only node-specific configuration data, the target undergoes node personalization.
The two-step process of pre-boot image customization and post-boot node personalization results in a fully configured node, optimized for minimal bring-up times.
* "Pull-based" deployment: Provide configuration management to nodes by prescribing a desired configuration state and ensuring the current node configuration state matches the desired state automatically.
This is achieved via the CFS Hardware Synchronization Agent and the CFS Batcher implementation.

## CFS Components

CFS is comprised of a group of services and components interacting within the Cray System Management \(CSM\) service mesh, and provides a means for system administrators to configure nodes and boot images via Ansible. CFS includes the following components:

* `CFS-API`, a REST API service.
* A command-line interface \(CLI\) to the API \(via the `cray cfs` command\).
* A pre-packaged Ansible Execution Environment \(AEE\) with values tuned for performant configuration for executing Ansible playbooks, and reporting plug-ins for communication with CFS.
* The `CFS-Hardware-Sync-Agent`, which pulls in node information from the system inventory to the CFS database to track the node configuration state.
* The `CFS-Operator`, which manages the setup and teardown of Kubernetes jobs that run the AEE.
* The `CFS-Batcher`, which manages the configuration state of system components \(nodes\).
* `CFS-Trust`, which manages the keys and certificates CFS uses to access other system components \(nodes\).
* `CFS-State-Reporter`, which runs on each of the system components \(nodes\) to alert the CFS API when a component is rebooted and requires configuration.
* `CFS-ARA`, which collects the Ansible logs from the AEE pods.

Although it is not a formal part of the service, CFS integrates with a Gitea instance \(VCS\) running in the CSM service mesh for management of the configuration content life-cycle.

## High-Level Configuration Workflow

CFS remotely executes Ansible configuration content on nodes or boot images with the following workflow:

1. Users create a configuration with one or more layers that references Ansible playbooks stored in VCS.
1. Users either specify a configuration and the components to apply it to by creating a CFS session, or by setting the desired configuration for the a component.
1. CFS creates a Kubernetes job that runs the Ansible to apply each of the playbooks in the specified configuration.

For more information on the flow of CFS sessions see the [CFS Flow Diagrams](CFS_Flow_Diagrams.md).
