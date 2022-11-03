# Target Ansible Tasks for Image Customization

The Configuration Framework Service \(CFS\) enables Ansible playbooks to run against both running nodes \(node personalization\) and images prior to boot\(image customization\).
See [Configuration Management Use Cases](Configuration_Management.md#use-cases) for more information about image customization and when it should be used.

## Using the `cfs_image` host group

During image customization, CFS will automatically add all image customization hosts into a special `cfs_image` host group in Ansible inventory.
Plays intended for image customization can then target this group in addition to any other provided host groups.

To target only image customization, plays should use the following syntax.  In this example the play is targeting only _images_ for `Compute` nodes. `&` takes the intersection of the `Compute` and `cfs_image` groups.

```yaml
hosts: Compute:&cfs_image
```

To target only node personalization, plays should use the following syntax.  In this example the play is targeting only _running_ `Compute` nodes. `!` negates the `cfs_image` group, so that only Compute nodes that are not an image are targeted.

```yaml
hosts: Compute:!cfs_image
```

For more information on complex host targets, see the [Ansible Hosts Documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_patterns.html).

### Example: Using the `cfs_image` host group for image customization

```yaml
- name: Image customization play
  hosts: Management_Worker:&cfs_image
  tasks:
    - include_role:
        role: cos-services-install

- name: Node personalization play  
  hosts: Management_Worker:!cfs_image
  tasks:
    - include_role: 
        role: cos-services-restart
```

## Using the `cray_cfs_image` variable

`** NOTE **` This option is no longer recommended and should only be used in small playbooks and one-off cases
 as it is more efficient for Ansible to determine this at the host level rather than checking the `cray_cfs_image` variable for multiple tasks.
 The preferred method is to use the aforementioned `cfs_image` host group.

CFS also provides the `cray_cfs_image` variable to distinguish between node personalization and image customization.
`cray_cfs_image` can be used with [Ansible playbook conditionals](https://docs.ansible.com/ansible/latest/user_guide/playbooks_conditionals.html)
to selectively run individual tasks with `when: cray_cfs_image`, or to ignore individual tasks with `when: not cray_cfs_image`.

Conditionals can also be applied to entire roles if desired \(see the external [apply Ansible conditionals to roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_conditionals.html#conditionals-with-includes).
In instances where the same playbook may be run in both modes, it is best practice to include a conditional on all parts of the playbook. This is best done by placing the conditional on an `include_*` statement.
See [Write Ansible Code for CFS: Reduce wasted time](Write_Ansible_Code_for_CFS.md#reduce-wasted-time) for more information on optimizing conditionals.

It is best practice to include a default in Ansible roles for playbook and role portability because CFS injects this variable at runtime. This can be done in the defaults section of the role, or where the variable is called. For example:

```text
{{ cray_cfs_image | default(false) }}
```

If a default is not provided, any playbooks or roles will not be runnable outside of the CFS Ansible Execution Environment \(AEE\) without the user specifying `cray_cfs_image` in the `vars` files or with the Ansible `extra-vars` options.

CFS automatically sets this variable in the `hosts/01-cfs-generated.yaml` file for all sessions. When the session target is image customization, it sets `cray_cfs_image` to `true`; otherwise, it is `false`.

## Image customization limitations

When running Ansible against an IMS-hosted image root during an image customization CFS session, there are no special requirements for the paths when copying or syncing files.
The image root directories will appears as if Ansible is connecting to a regular, live node.
However, the image is not a running node, so actions that require a running system, such as starting/reloading a service, will not work properly and will cause the Ansible play to fail.
Actions like these should be done only during live-node configuration modes such as node personalization.
