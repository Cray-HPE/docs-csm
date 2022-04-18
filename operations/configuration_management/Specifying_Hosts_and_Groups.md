# Specifying Hosts and Groups

When using the Configuration Framework Service (CFS), there are many steps where users may need to specify the hosts that CFS should configure. This can be done by specifying individual hosts, or groups of hosts. There are several places where a user may need to provide this information, particularly groups, and depending on where this information is provided, the behavior can change greatly.

## Inventories

CFS has multiple options for generating inventories, but regardless of which option is used, the information is then converted into an Ansible inventory/hosts file. The inventory is the list of components that Ansible can run against. Anything not in the inventory is unknown to Ansible. Components in an inventory can be placed into groups so that they can be easily referenced together either in the Ansible code or when providing a limit to CFS.

For more information on Ansible inventory, see the official [Ansible Inventory Documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html).

## Hosts

Within Ansible plays, it is possible to target different hosts and groups. These hosts and groups must exist in the inventory when Ansible is run. Combined with the inventory, this will determine which hosts have tasks run. For more information, see the [Ansible Hosts Documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_patterns.html).

## Limits

The limit parameter is a way of restricting a run to a smaller set of hosts. Users can specify hosts or groups, or combinations of the two, but no new information can be added at this point. Hosts or groups that do not appear in the inventory will still not be configured, and likewise it is not possible to change the behavior of any parts of the play. Ansible will target the same groups for each task that it would have before, but now with a more limited inventory.
