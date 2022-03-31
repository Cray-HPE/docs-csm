# Ansible Inventory

The Configuration Framework Service \(CFS\) provides several options for targeting nodes or boot images for configuration by Ansible. The contents of the Ansible inventory determine which nodes are available for configuration in each CFS session and how default configuration values can be customized.

The following are the inventory options provided by CFS:

-   Dynamic inventory
-   Static inventory
-   Image Customization


### Dynamic Inventory and Host Groups

Dynamic inventory is the default inventory when creating a CFS session. CFS automatically generates an Ansible hosts file with data provided by the Hardware State Manager \(HSM\) when using a dynamic inventory. CFS automatically generates Ansible hosts groups for each group defined in HSM and creates Ansible host groups for nodes based on hardware roles and sub-roles.

Retrieve a list of HSM groups with the following command:

```bash
ncn# cray hsm groups list --format json | jq .[].label
"example-group1"
"example-group2"
```

These groups can be referenced in Ansible plays or when creating a CFS session directly.

Hardware roles and sub-roles are available as \[Role\] and \[Role\]\_\[Subrole\] Ansible host groups. For instance, if targeting just the nodes with the "Application" role, the host group name is Application. If targeting just the sub-role "UAN", which is a sub-role of the "Application" role, the host group name provided by CFS is Application\_UAN. See [HSM Roles and Subroles](../hardware_state_manager/HSM_Roles_and_Subroles.md) for more information.

Consult the `cray-hms-base-config` Kubernetes ConfigMap in the services namespace for a listing of the available roles and sub-roles on the system.

During a CFS session, the dynamic inventory is generated and placed in the hosts/01-cfs-generated.yaml file, relative to the configuration management repository root defined in the current configuration layer. Refer to the external [Ansible Inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html#using-multiple-inventory-sources) documentation for more information about managing inventory, as well as variable precedence within multiple inventory files.

CFS prefixes its dynamic inventory file with `01-` so that its variables can be easily overridden as needed because Ansible reads inventory files in lexicographic order.


### Static Inventory

Even though CFS uses dynamic inventory and the HSM groups, roles, and sub-roles to enable specific targeting of groups of nodes, it is also possible to target nodes within the system using a static inventory file. To do so, each node must be listed in an inventory file itself. This approach is useful for testing configuration changes on a small scale.

Create a static inventory file in a hosts directory at the root of the configuration management repository in Ansible INI format. For example, create it in a branch and persist the changes.

In the following example, this is done for a single node in static inventory:

```bash
ncn# mkdir -p hosts; cd hosts; cat > static <<EOF
[test_nodes]
x3000c0s25b0n0
EOF
ncn# cd ..; git add hosts/static
ncn# git commit -m "Added a single test node to static inventory"
ncn# git push
```

The process can be used to include any nodes in the system reachable over the Node Management Network \(NMN\), which contains the public SSH key pair provisioned by the install process. This inventory information will only be located in the repository to which it is added. If the desired configuration contains multiple layers, use the additionalInventoryUrl option in CFS to provide inventory information on a per-session level instead of a per-repository level. Refer to [Manage Multiple Inventories in a Single Location](Manage_Multiple_Inventories_in_a_Single_Location.md) for more information.

### Image Customization

CFS handles inventory for image customization differently because this type of configuration session does not target live nodes. When creating a configuration session meant to customize a boot image, the Image Management Service \(IMS\) image IDs are used as hosts and grouped according to input to the session creation.

See [Create an Image Customization CFS Session](Create_an_Image_Customization_CFS_Session.md) for more information.

