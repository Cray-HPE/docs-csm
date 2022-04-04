# Write Ansible Code for CFS

Cray provides Ansible plays and roles for software products deemed necessary for the system to function. Customers are free to write their own Ansible plays and roles to augment what Cray provides or implement new features. Basic knowledge of Ansible is needed to write plays and roles. The information below includes recommendations and best practices for writing and running Ansible code on the system successfully with the Configuration Framework Service \(CFS\).

Help with Ansible can be found in the external Ansible documentation:

- [Ansible playbook best practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Ansible examples](https://github.com/ansible/ansible-examples)

### Ansible Code Structure

The Version Control Service \(VCS\) is setup during the Cray System Management \(CSM\) product installation, which is the appropriate place to store configuration content. Individual product installations include the Ansible code to properly configure each product.

The structure of the individual repository directories matches the [recommended directory layout](https://docs.ansible.com/ansible/2.9/user_guide/playbooks_best_practices.html#content-organization) from the external Ansible documentation. The default playbook site.yml is found at the top level, if it exists, and the Ansible roles and variables are in their appropriate directories. Inventory directories like `group_vars` and `host_vars` may exist, but they are empty and left for variable overrides and customizations by the user.

### Write Playbooks for Multiple Node Types

Within an Ansible playbook, users can designate which node groups the various tasks and roles will run against. For example, a default site.yml playbook may contain a list of roles that are run on only the `Compute` nodes, and a list of roles that will run on only `Application` nodes. This is designated using the `hosts` parameter.

For example, `hosts: Compute` would be used to target the compute nodes. Users can create additional sections that target other node types, or adjust the hosts that the included roles will run against as necessary. It is also possible to target multiple groups within a section of a playbook, or to specify complex targets, such as nodes that are in one group and not in another group. The syntax for this is available in the external [Ansible documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_patterns.html#common-patterns). Hosts can be in more than one group at a time if there are user-defined groups. In this case, Ansible will run all sections that match the node type against the node.

See the [Ansible Inventory](Ansible_Inventory.md) section for more information about groups that are made automatically available through CFS dynamic inventory.

### Performance and Scaling Tips

CFS will handle scaling up Ansible to run on many hosts, but there are still places where performance can be improved by correctly writing Ansible plays.

- Use image customization when possible to limit how many times a task is run and improve boot times. Configuration that is the same for all nodes of the same type will benefit from image customization. See the next section for how to target specific tasks for running only during image customization.
- Import roles rather than playbooks. Each time a new playbook starts, Ansible automatically gathers facts for all the systems it is running against. This is not necessary more than once and can slow down Ansible execution.
- Turn off facts that are not needed in a playbook by setting `gather_facts: false`. If only a few facts are required, it is also possible to limit fact gathering by setting `gather_subset`. For more information on `gather_subset`, see the external [Ansible module setup](https://docs.ansible.com/ansible/latest/modules/setup_module.html) documentation.
- Use loops rather than individual tasks where modules are called multiple times. Some Ansible modules will optimize the command, such as grouping package installations into a single transaction \(Refer to the external [Ansible playbook loops](https://docs.ansible.com/ansible/latest/user_guide/playbooks_loops.html) documentation\).

