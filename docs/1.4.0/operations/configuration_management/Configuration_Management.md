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

* A REST API service.
* A command-line interface \(CLI\) to the API \(via the `cray cfs` command\).
* Pre-packaged AEE\(s\) with values tuned for performant configuration for executing Ansible playbooks, and reporting plug-ins for communication with CFS.
* The CFS Hardware Sync Agent, which pulls in node information from the system inventory to the CFS database to track the node configuration state.
* The CFS Batcher, which manages the configuration state of system components \(nodes\).

Although it is not a formal part of the service, CFS integrates with a Gitea instance \(VCS\) running in the CSM service mesh for management of the configuration content life-cycle.

## High-Level Configuration Workflow

CFS remotely executes Ansible configuration content on nodes or boot images with the following workflow:

1. Creating a configuration with one or more layers within a specific Git repository, and committing it to be executed by Ansible.
2. Targeting a node, boot image, or group of nodes to apply the configuration.
3. Creating a configuration session to apply and track the status of Ansible, applying each configuration layer to the targets specified in the session metadata.

Additionally, configuration management of specific components \(nodes\) can also be achieved by doing the following:

1. Creating a configuration with one or more layers within a specific Git repository, and committing it to be executed by Ansible.
2. Setting the desired configuration state of a node to the prescribed layers.
3. Enabling the CFS Batcher to automatically configure nodes by creating one or more configuration sessions to apply the configuration layer\(s\).
