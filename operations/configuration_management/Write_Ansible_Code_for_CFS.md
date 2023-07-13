# Write Ansible Code for CFS

HPE Cray provides Ansible plays and roles for software products deemed necessary for the system to function.
Customers are free to write their own Ansible plays and roles to augment what HPE Cray provides or implement new features.
Basic knowledge of Ansible is needed to write plays and roles.
The information below includes recommendations and best practices for writing and running Ansible code on the system successfully with the Configuration Framework Service \(CFS\).

Help with Ansible can be found in the external Ansible documentation:

* [Ansible playbook best practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
* [Ansible examples](https://github.com/ansible/ansible-examples)

## Ansible code structure

The Version Control Service \(VCS\) is setup during the Cray System Management \(CSM\) product installation, which is the appropriate place to store configuration content.
Individual product installations include the Ansible code to properly configure each product.

The structure of the individual repository directories matches the [recommended directory layout](https://docs.ansible.com/ansible/2.9/user_guide/playbooks_best_practices.html#content-organization) from the external Ansible documentation.
Playbooks are found at the top level, and the Ansible roles and variables are in their appropriate directories.
Inventory directories like `group_vars` and `host_vars` may exist, but they are empty and left for variable overrides and customizations by the user.

## Targeting specific node types with playbooks

Within an Ansible playbook, users can designate which node groups the various tasks and roles will run against.
For example, a playbook may contain a list of roles that are run on only the `Compute` nodes, or a list of roles that will run on only `Application` nodes. This is designated using the `hosts` parameter.

For example, `hosts: Compute` would be used to target the compute nodes. Users can create additional sections that target other node types, or adjust the hosts that the included roles will run against as necessary.
It is also possible to target multiple groups within a section of a playbook, or to specify complex targets, such as nodes that are in one group and not in another group.
The syntax for this is available in the external [Ansible documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_patterns.html#common-patterns).
Hosts can also be in more than one group at a time. In this case, Ansible will run all sections that match the node type against the node.

See the [Ansible Inventory](Ansible_Inventory.md) section for more information about groups that are made automatically available through CFS dynamic inventory.

## Performance and scaling tips

CFS will handle scaling up Ansible to run on many hosts, but there are still places where performance can be improved by correctly writing Ansible plays.

### Using image customization

* Use image customization when possible; doing so will improve boot times by limiting how many times a task is run. Configuration that is the same for all nodes of the same type will benefit from image customization.
* Use different playbooks for image customization and node personalization.
Moving image customizations tasks to their own playbook can remove the need to evaluate conditionals in a shared playbook, as well as ensuring that tasks are not accidentally running in both modes needlessly.
* See [Target Ansible Tasks for Image Customization](Target_Ansible_Tasks_for_Image_Customization.md) for more information on writing for image customization.

### Disable fact gathering

* Turn off facts that are not needed in a playbook by setting `gather_facts: false`. If only a few facts are required, it is also possible to limit fact gathering by setting `gather_subset`.
For more information on `gather_subset`, see the external [Ansible module setup](https://docs.ansible.com/ansible/latest/modules/setup_module.html) documentation.
* Avoid importing playbooks in other playbooks.  This will trigger fact gathering for each imported playbook, potentially collecting the same information multiple times.

### Reduce wasted time

* Use `include_*` (dynamic re-use) to skip multiple tasks at once when using conditionals. Ansible evaluates conditionals for every node in every task.
  This includes when the conditional is applied to a block, or a role imported with `roles:` or the `import_role` task.
  This is because these are static imports that are compiled at the beginning of the playbook, and the conditional is inherited by every task in the role or block.
  Evaluating these conditionals for each task may only take a second or two, but across the hundreds of tasks that might be part of a playbook, this can add up to significant wasted time.
  Instead use dynamic imports with the `include_*` tasks. Because these are evaluated at runtime, a conditional can skip the import of the role or tasks entirely, and is only evaluated once.
  See the Ansible documentation on [Conditionals with re-use](https://docs.ansible.com/ansible/latest/user_guide/playbooks_conditionals.html#conditionals-with-re-use)
  and [Re-using files and roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse.html#re-using-files-and-roles) for more information.
* Avoid using the same CFS configuration/playbook for all nodes and relying on the `hosts` keyword to determine what tasks will run against each node. Ansible will skip sections of the playbook that have a `hosts` target that does
  not match any nodes in the current inventory/limit, but when multiple types of nodes are configured at the same time with the same configuration, they may end up in the same batch and Ansible run. This would mean that Ansible
  has to run through the sections for both types of nodes, taking more time than if the nodes were in separate batches and could skip past the unneeded code.

### Other tips

* Use loops rather than individual tasks where modules are called multiple times.
Some Ansible modules will optimize the command, such as grouping package installations into a single transaction \(Refer to the external [Ansible playbook loops](https://docs.ansible.com/ansible/latest/user_guide/playbooks_loops.html) documentation\).
* Use Ansible retries for small, recoverable failures. CFS supports retries on a large scale, but it takes far more time for CFS to detect a failed component and spin up a new session than it does for Ansible to retry a task.
* Do not use Ansible retries for failures than take a long time to recover from. Retrying for a significant amount of time on one node can hold up all the other successful nodes in a batch. If you cannot recover from a failure quickly,
  then let the node fail and CFS will separate it out from the successful nodes when new sessions are started.
* Avoid `any_errors_fatal`. In addition to not working with all Ansible strategies, this can cause an Ansible run to exit early, and the nodes that did not have the error will have to start from the beginning of the playbook in the next session.
* Design playbooks to be run with the `free` Ansible strategy. This means avoiding situations where all nodes in a batch need to complete a task before moving onto the next, and can save time by allowing nodes to proceed through a playbook at their own pace.

## Ansible limitations with CFS

Because CFS splits components into multiple batches, and components may also configure at
different times when they are rebooted, some keywords meant for coordinating the runs of multiple nodes may not work as expected.

| Keyword | Notes |
| --------- | ------- |
| `any_errors_fatal` | This keyword is intended to stop execution as soon as any node reports a failure. However, this will only stop execution for the current batch. |
| `run_once` | This keyword is intended to limit a task to running on a single node. However this will only cause the task to be run once per batch. |
| `serial` | This keyword is intended to limit runs to a small number of nodes at a time, such as during a rolling upgrade. |
| | However, this will only function within the batch, so more nodes may be running the task than intended when multiple batches are running. |

## Selecting an Ansible strategy

CFS supports two Ansible strategies: `cfs_linear` and `cfs_free`. `cfs_linear` runs all task in a playbook serially, with all nodes completing a task before Ansible moves on to the next task.
`cfs_free` decouples the nodes allowing each node to proceed through the playbook at its own pace.
Switching to `cfs_free` from the default strategy of `cfs_linear` may result in better configuration time, however currently not all included playbooks support the `cfs_free` strategy,
so this should only be done when playbooks that are confirmed to work correctly with the `cfs_free` strategy.
In addition, the `cfs_free` strategy is limited by the fact that configuration in CFS is applied over multiple layers and multiple playbooks.
This means that even when using the `cfs_free` strategy, all nodes must complete a playbook together before moving onto the next playbook.

The CFS Ansible strategies extend the similarly named Ansible strategy, adding reporting callbacks that are used to track components' state. `cfs_linear` and `cfs_free` should always be used in place of `linear` and `free` to ensure that CFS functions correctly.
