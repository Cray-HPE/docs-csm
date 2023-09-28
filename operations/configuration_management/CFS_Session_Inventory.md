# CFS Session Inventory

The Configuration Framework Service \(CFS\) provides several options for targeting nodes or boot images for configuration by Ansible.
The contents of the Ansible inventory determine which nodes are available for configuration in each CFS session and how default configuration values can be customized.
For more information on what it means to define an inventory, see
[Specifying Hosts and Groups](Specifying_Hosts_and_Groups.md).

The following are the inventory options provided by CFS:

* [Dynamic inventory](#dynamic-inventory)
* [Image customization](#image-customization)
* [Other inventory options](#other-inventory-options)

## Dynamic inventory

Dynamic inventory is the default inventory when creating a CFS session.
CFS automatically generates an Ansible hosts file including all components in the Hardware State Manager \(HSM\).
CFS automatically generates Ansible hosts groups for each group defined in HSM and creates Ansible host groups for nodes based on hardware roles and sub-roles.

(`ncn-mw#`) Retrieve a list of HSM groups with the following command:

```bash
cray hsm groups list --format json | jq .[].label
```

These groups can be referenced in Ansible plays or when creating a CFS session directly.

Hardware roles and sub-roles are available as `<Role>` and `<Role>_<Subrole>` Ansible host groups. For instance, if targeting just the nodes with the `Application` role, the host group name is
`Application`. If targeting just the sub-role `UAN`, which is a sub-role of the `Application` role, the host group name provided by CFS is `Application_UAN`.
See [HSM Roles and Subroles](../hardware_state_manager/HSM_Roles_and_Subroles.md) for more information.

Consult the `cray-hms-base-config` Kubernetes ConfigMap in the `services` namespace for a listing of the available roles and sub-roles on the system.

During a CFS session, the dynamic inventory is generated and placed in the `hosts/01-cfs-generated.yaml` file, relative to the configuration management repository root defined in the current
configuration layer. Refer to the external [Ansible Inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html#using-multiple-inventory-sources) documentation for more
information about managing inventory, as well as variable precedence within multiple inventory files.

CFS prefixes its dynamic inventory file with `01-` so that its variables can be easily overridden as needed because Ansible reads inventory files in lexicographic order.

## Image customization

Inventory for image customization is also provided by the user.
This type of configuration session does not target live nodes, so HSM has no knowledge of either the host or the groups it belongs to.
Instead, when creating a configuration session meant to customize a boot image,
the Image Management Service \(IMS\) image IDs are used as hosts and grouped according to user input to the session creation.

See [Create an Image Customization CFS Session](Create_an_Image_Customization_CFS_Session.md) for more information.

## Other inventory options

The CFS API currently lists two other supported inventory options, `spec` and `repo`, however these options have been deprecated.
For those wishing to specify their own inventory beyond what is found in HSM,
see the `additional_inventory` options described in [Adding Additional Inventory](Adding_Additional_Inventory.md)
