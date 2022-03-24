# Target Ansible Tasks for Image Customization

The Configuration Framework Service \(CFS\) enables Ansible playbooks to run against both running nodes and images. See the "Use Cases" header in the [Configuration Management](Configuration_Management.md) section for more information about image customization and when it should be used.

CFS uses the `cray_cfs_image` variable to distinguish between node personalization \(running on live nodes\) and image customization \(configuring an image prior to boot\). When this variable is set to true, it indicates that the CFS session is an image customization type and the playbook is targeting an image.

CFS automatically sets this variable in the hosts/01-cfs-generated.yaml file for all sessions. When the session target is image customization, it sets `cray_cfs_image` to `true`; otherwise, it is `false`.

`cray_cfs_image` can be set with [Ansible playbook conditionals](https://docs.ansible.com/ansible/latest/user_guide/playbooks_conditionals.html) to selectively run individual tasks with `when: cray_cfs_image`, or to ignore individual tasks with `when: not cray_cfs_image`.

Conditionals can also be applied to entire roles if desired \(see the external [apply Ansible conditionals to roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_conditionals.html#applying-when-to-roles-imports-and-includes)\). In instances where the same playbook may be run in both modes, it is best practice to include a conditional on all parts of the playbook, or at least those that take significant time so that work is not duplicated.

It is also best practice to include a default in Ansible roles for playbook and role portability because CFS injects this variable at runtime. This can be done in the defaults section of the role, or where the variable is called. For example:

```bash
when: "{{ cray_cfs_image | default(false) }}"
```

If a default is not provided, any playbooks or roles will not be runnable outside of the CFS Ansible Execution Environment \(AEE\) without the user specifying `cray_cfs_image` in the vars files or with the Ansible extra-vars options.

When running Ansible against an IMS-hosted image root during an image customization CFS session, there are no special requirements for the paths when copying or syncing files. The image root directories will appears as if Ansible is connecting to a regular, live node. However, the image is not a running node, so actions that require a running system, such as starting/reloading a service, will not work properly and will cause the Ansible play to fail. Actions like these should be done only during live-node configuration modes such as node personalization.

