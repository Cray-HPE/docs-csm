# Configuration Management

The Configuration Framework Service (CFS) is available on systems for remote execution and configuration management of nodes and boot images.
This includes nodes available in the
[Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm) inventory (compute, management, and application nodes),
and boot images hosted by the
[Image Management Service (IMS)](../../glossary.md#image-management-service-ims).

CFS configures nodes and images via a `gitops` methodology. All configuration content is stored in a version control service (VCS), and is managed by authorized system administrators.
CFS provides a scalable [Ansible Execution Environment (AEE)](Ansible_Execution_Environments.md) for the configuration to be applied with flexible inventory and node targeting options.

## Use cases

CFS is available for the following use cases on systems:

* Image customization: Pre-configure bootable images available via IMS. This use case enables provisioning a full configuration of a target node.
  Non-node-specific settings are applied pre-boot, which reduces the amount of configuration required after a node boots, and therefore reduces the bring-up time for nodes.
* Post-boot configuration: Fully configure or reconfigure booted nodes in a scalable, performant way to add the required settings.
* "Push-based" deployment: When using post-boot configuration with only node-specific configuration data, the target undergoes node personalization.
The two-step process of pre-boot image customization and post-boot node personalization results in a fully configured node, optimized for minimal bring-up times.
* "Pull-based" deployment: Provide configuration management to nodes by prescribing a desired configuration state and ensuring the current node configuration state matches the desired state automatically.
This is achieved via the CFS Hardware Synchronization Agent and the CFS Batcher implementation.

## CFS components

CFS is comprised of a group of services and components interacting within the Cray System Management (CSM) service mesh, and provides a means for system administrators to configure nodes and boot images via Ansible. CFS includes the following components:

* CFS API, a REST API service.
* A command-line interface (CLI) to the API (via the `cray cfs` command).
* A pre-packaged Ansible Execution Environment (AEE) with values tuned for performant configuration for executing Ansible playbooks, and reporting plug-ins for communication with CFS.
* The [CFS Hardware Synchronization Agent](CFS_Hardware_Synchronization_Agent.md).
* The [CFS Operator](CFS_Operator.md).
* The [CFS Batcher](CFS_Batcher.md).
* CFS Trust, which manages the keys and certificates CFS uses to access other system components (nodes).
* CFS State Reporter, which runs on each of the system components (nodes) to alert the CFS API when a component is rebooted and requires configuration.

Although it is not a formal part of the service, CFS integrates with a Gitea instance (VCS) running in the CSM service mesh for management of the configuration content life-cycle.

## High-level configuration workflow

CFS remotely executes Ansible configuration content on nodes or boot images with the following workflow:

1. Creating a configuration with one or more layers within a specific Git repository, and committing it to be executed by Ansible.
1. Targeting a node, boot image, or group of nodes to apply the configuration.
1. Creating a configuration session to apply and track the status of Ansible, applying each configuration layer to the targets specified in the session metadata.

Additionally, configuration management of specific components \(nodes\) can also be achieved by doing the following:

1. Creating a configuration with one or more layers within a specific Git repository, and committing it to be executed by Ansible.
1. Setting the desired configuration state of a node to the prescribed layers.
1. Enabling the CFS Batcher to automatically configure nodes by creating one or more configuration sessions to apply the configuration layer\(s\).
