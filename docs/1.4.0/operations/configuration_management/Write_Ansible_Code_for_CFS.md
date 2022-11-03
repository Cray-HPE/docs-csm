# Write Ansible Code for CFS

HPE Cray provides Ansible plays and roles for software products deemed necessary for the system to function.
Customers are free to write their own Ansible plays and roles to augment what HPE Cray provides or implement new features.
Basic knowledge of Ansible is needed to write plays and roles.
The information below includes recommendations and best practices for writing and running Ansible code on the system successfully with the Configuration Framework Service \(CFS\).

Help with Ansible can be found in the external Ansible documentation:

* [Ansible playbook best practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
* [Ansible examples](https://github.com/ansible/ansible-examples)

## Ansible Code Structure

The Version Control Service \(VCS\), which is setup during the Cray System Management \(CSM\) product installation, is the appropriate place to store configuration content.
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
Hosts can also be in more than one group at a time. In this case, Ansible will run all sections where the node is in the targeted host group.

See the [Ansible Inventory](Ansible_Inventory.md) section for more information about groups that are made automatically available through CFS dynamic inventory.

## Performance and scaling tips

CFS will handle scaling up Ansible to run on many hosts, but there are still places where performance can be improved by correctly writing Ansible plays.

### Using image customization

See [Create an Image Customization CFS Session](Create_an_Image_Customization_CFS_Session.md) for a definition of image customization.

* Use image customization when possible; doing so will improve boot times by limiting how many times a task is run. Configuration that is the same for all nodes of the same type will benefit from image customization.
* Use the `cfs_image` host group to distinguish between image customization and node personalization.
  This allows image customization to be identified in the `hosts` parameter, removing the need to evaluate conditionals, and ensuring that tasks are not accidentally running in both modes needlessly.
* See [Target Ansible Tasks for Image Customization](Target_Ansible_Tasks_for_Image_Customization.md) for more information on writing for image customization.

### Disable fact gathering

* Turn off facts that are not needed in a playbook by setting `gather_facts: false`. If only a few facts are required, it is also possible to limit fact gathering by setting `gather_subset`.
For more information on `gather_subset`, see the external [Ansible module setup](https://docs.ansible.com/ansible/latest/modules/setup_module.html) documentation.
* Reducing fact gathering time is especially important when importing multiple playbooks from a top level playbook.
  Fact gathering will trigger for each imported playbook, potentially collecting the same information multiple times.
  
### Avoid repeated conditionals with `group_by` and `add_host`

The `group_by` and `add_host` modules can both be used to dynamically generate new hosts groups for the Ansible inventory.
These modules prove useful when hosts can be grouped according to a common property. Then, plays can be designed to only target that particular group.
Examples of this might include grouping by operating system, hardware type, or a hardware property such as the presence of a GPU.
Ansible can then use these to skip roles and tasks more efficiently than if the `when` conditional is applied.

`group_by` should be used when there are multiple named groups by which hosts can be grouped.
For more information on using this module see See Ansible's [playbooks best practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#handling-os-and-distro-differences) guide.

Example of `group_by`:

```yaml
- name: group by OS
  hosts: all
  tasks:
    - name: Classify hosts by OS
      group_by:
        key: os_{{ ansible_facts['distribution'] }}

- name: centOS playbook
  hosts: os_CentOS
  tasks:
    ...

```

`add_host` is useful for cases where the property is true or false.
It allows users to create a new group consisting of only the hosts where the property is true.
See Ansible's documentation on the [add host module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/add_host_module.html) for more information.

Example of `add_host`:

```yaml
- name: group by a sample variable
  hosts: all
  tasks:
    - name: Add all hosts where sample_var is true to the new Sample group
      add_host:
        name: '{{ inventory_hostname }}'
        groups: sample_group
      when: sample_var

- name: Sample playbook
  hosts: sample_group
  tasks:
    ...
```

To target only a subset of a set of nodes, plays should use the following syntax.
In this example the play is targeting only nodes in the sample group that are also in the `Compute` nodes group.
`&` takes the intersection of the `Compute` and `sample_group` groups.

```yaml
hosts: Compute:&sample_group
```

To target a set of nodes except the ones in the new group, plays should use the following syntax.
In this example the play is targeting `Compute` nodes that are not a part of the sample group.
`!` negates the `sample_group` group, so that only Compute nodes that are not an image are targeted.

```yaml
hosts: Compute:!sample_group
```

### Avoid repeated conditionals with `include_*`

Use `include_*` (dynamic re-use) to skip multiple tasks at once when using conditionals. Ansible evaluates conditionals for every node in every task.
This includes when the conditional is applied to a block, or a role imported with `roles:` or the `import_role` task.
This is because these are static imports that are compiled at the beginning of the playbook, and the conditional is inherited by every task in the role or block.
Evaluating these conditionals for each task may only take a second or two, but across the hundreds of tasks that might be part of a playbook, this can add up to significant wasted time.
Instead use dynamic imports with the `include_*` tasks. Because these are evaluated at runtime, a conditional can skip the import of the role or tasks entirely, and is only evaluated once.

For example, in the following case the role is imported statically and the `when` statement will be propagated down and evaluated for each task in the role.  This wastes time by running the same check many times.

```yaml
- name: Sample playbook
  hosts: all
  roles:
    - {role: sample_role, when: cray_cfs_image}
```

Instead the role should be imported dynamically so that the `when` conditional is only evaluated once:

```yaml
- name: Sample playbook
  hosts: all
  tasks:
    - include_role:
        role: sample_role
      when: cray_cfs_image
```

See the Ansible documentation on [Conditionals with re-use](https://docs.ansible.com/ansible/latest/user_guide/playbooks_conditionals.html#conditionals-with-re-use)
and [Re-using files and roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse.html#re-using-files-and-roles) for more information.
(Dynamic re-use is not possible when importing playbooks, so instead consider using `group_by` rather than a conditional static import.)

### Other tips

* Use the included Ansible modules rather than making shell calls or running scripts.  Ansible optimizes these and makes them flexible so the same module can be used for different systems.  This will also improve the log output for debugging.
* Use loops rather than individual tasks where modules are called multiple times.
Some Ansible modules will optimize the command, such as grouping package installations into a single transaction \(Refer to the external [Ansible playbook loops](https://docs.ansible.com/ansible/latest/user_guide/playbooks_loops.html) documentation\).
* Use Ansible retries for small, recoverable failures. CFS supports retries on a large scale, but it takes far more time for CFS to detect a failed component and spin up a new session than it does for Ansible to retry a task.
* Do not use Ansible retries for failures that take a long time to recover from. Retrying for a significant amount of time on one node can hold up all the other successful nodes in a batch. If you cannot recover from a failure quickly,
  then let the node fail and CFS will separate it out from the successful nodes when new sessions are started.
* Avoid `any_errors_fatal`. In addition to not working with all Ansible strategies, this can cause an Ansible run to exit early, and the nodes that did not have the error will have to start from the beginning of the playbook in the next session.
* Design playbooks to be run with the `free` Ansible strategy. This means avoiding situations where all nodes in a batch need to complete a task before moving onto the next, and can save time by allowing nodes to proceed through a playbook at their own pace.
* Avoid using the same CFS configuration/playbook for diverse node types. Ansible will skip sections of the playbook that have a `hosts` target that does
  not match any nodes in the current inventory/limit, but when multiple types of nodes are configured at the same time with the same configuration, they may end up in the same batch and Ansible run. This would mean that Ansible
  has to run through the sections for both types of nodes, taking more time than if the nodes were in separate batches and could skip past the unneeded code.

### Summary of the key tips

For users just starting to write plays, or who just want to focus on the biggest improvements, here is a summary of the key tips:

* Disable fact gathering if the play does not use Ansible facts: `gather_facts: false`
* Use image customization where possible to avoid running tasks every time nodes boot.
* Use the `cfs_image` host group to specify whether a play is intended for image customization or node personalization.
* Use `group_by`, `add_host` and `include_*` rather than `roles:` and `when:` to avoid repeating conditionals.
* Use existing Ansible modules rather than calling shell commands or scripts.

## Ansible limitations with CFS

Because CFS splits components into multiple batches, and components may also configure at
different times when they are rebooted, some keywords meant for coordinating the runs of multiple nodes may not work as expected.

| Keyword | Notes |
| --------- | ------- |
| `any_errors_fatal` | This keyword is intended to stop execution as soon as any node reports a failure. However, this will only stop execution for the current batch. |
| `run_once` | This keyword is intended to limit a task to running on a single node. However this will only cause the task to be run once per batch. |
| `serial` | This keyword is intended to limit runs to a small number of nodes at a time, such as during a rolling upgrade. |
| | However, this will only function within the batch, so more nodes may be running the task than intended when multiple batches are running. |
| `delegate_to` | This keyword is often used with `run_once` to run tasks on a specific node. |
| | While delegating to `localhost` is usually safe, delegating to any specific system node is not recommended as that node may not be available, especially during install, upgrades, and rolling reboots. |

## Selecting an Ansible strategy

CFS supports two Ansible strategies: `cfs_linear` and `cfs_free`. `cfs_linear` runs all task in a playbook serially, with all nodes completing a task before Ansible moves on to the next task.
`cfs_free` decouples the nodes allowing each node to proceed through the playbook at its own pace.
Switching to `cfs_free` from the default strategy of `cfs_linear` may result in better configuration time; however, currently, not all included playbooks support the `cfs_free` strategy,
so this should only be done for playbooks that are confirmed to work correctly with the `cfs_free` strategy.
In addition, the `cfs_free` strategy is limited by the fact that configuration in CFS is applied over multiple layers and multiple playbooks.
This means that even when using the `cfs_free` strategy, all nodes must complete a playbook together before moving onto the next playbook.

The CFS Ansible strategies extend the similarly named Ansible strategy, adding reporting callbacks that are used to track components' state. `cfs_linear` and `cfs_free` should always be used in place of `linear` and `free` to ensure that CFS functions correctly.
