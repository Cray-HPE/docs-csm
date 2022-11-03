# Customize Configuration Values

In general, most systems will require some customization from the default values provided by Cray products. As stated in the previous section, these changes cannot be made on the pristine product branches that are imported during product installation and upgrades. Changes can only be made in Git branches that are based on the pristine branches.

Changing or overriding default values should be done in accordance with Ansible best practices \(see the external [Ansible best practices guide](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#content-organization)\) and variable precedence \(see the external [Ansible variable guide](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html)\) in mind.

The following practices should also be followed:

-   When it is necessary to add more functionality beyond an Ansible playbook provided by a Cray product, include the product playbook in a new playbook instead of modifying it directly. Any modifications to a product playbook will result in a merge being required during a product upgrade.
-   Do not modify default Ansible role variables, override all values using inventory \(group\_vars and host\_vars directories\). Cray products do not import any content to inventory locations, so merges of new product content will not cause conflicts if variables are located in inventory.
-   Do not put any sensitive or secret information, such as passwords, in the Git repository. These values should be pulled during runtime from an external key management system.

### Handling Sensitive Information

Passwords and other sensitive content should not be stored in a Version Control Service \(VCS\) repository. Instead, consider writing Ansible tasks/roles that pull the value in dynamically while the playbook is running from an external secrets management system.

At this time, the Ansible Vault is not supported by the Configuration Framework Service \(CFS\).

### Example: Override a Role Default Value

To override a value that is defined in an Ansible role in a configuration repository, set the value in the Ansible inventory. If the override pertains to an entire Ansible group of nodes, create a file as follows:

1.  Clone the configuration repository.
2.  Checkout the branch that will include the change, or create a new branch.
3.  Capture the variable name in the `roles/[role name]/defaults/main.yml` file.
4.  Create a new directory and edit a file with the role name.

    ```bash
    ncn# mkdir -p group_vars/all && touch group_vars/all/[role name].yml
    ```

5.  Set the variable to a new value in the file.

    ```bash
    ncn# echo '[variable name]: [new variable value]' >> group_vars/all/[role name].yml
    ```

6.  Stage the file in the Git branch, commit it, and promote the change.

This change will be applied to all nodes by using the group name `all`. To narrow the variable scope to a specific group \(`Compute` for example\), use the group name instead of `all` as follows:

```bash
ncn# mkdir -p group_vars/Compute && touch group_vars/Compute/[role name].yml
ncn# echo '[variable name]: [new variable value]' >> group_vars/Compute/[role name].yml
```

To narrow the variable scope to a single node create the file in the `host_vars/[node xname]/[role name].yaml` and override the value.

The name of the created file is largely inconsequential. The identified best practice is to include the name of the role in the created file for reasons of maintainability and discoverability. However, be aware that the file name matters when multiple files in the same directory contain the same variable with different values. In that case, use a single `all.yml` file rather than a directory, or use files names with import ordering in mind. See the external [Ansible documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#ansible-variable-precedence) for more information on how variables precedence is handled.

To override role variables for roles that exist across multiple repositories, consider using the CFS Additional Inventory feature. See [Manage Multiple Inventories in a Single Location](Manage_Multiple_Inventories_in_a_Single_Location.md).

### Example: Add or Remove Functionality to a Provided Playbook

To add more functionality to a playbook provided by a configuration repository, it is considered best practice to leave the existing playbook unmodified \(if possible\) to not have merge conflicts when new versions of the playbook are installed. For instance, if a site.yml playbook needs to be extended with a custom site-custom.yml playbook, consider creating a new playbook that imports and runs them both. For example, the `site-all.yml` playbook.

```bash
ncn# cat site-all.yml
- import_playbook: site.yml
- import_playbook: site-custom.yml
```

See the external [Ansible documentation on re-using playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse.html#re-using-playbooks).

To remove a role from a provided playbook, the best practice is to determine if the role provides a variable to skip the roles tasks altogether. See the `roles/[role name]/README` file for a listing of the role variables.

If changes to role variables are not able to skip the role, the role may be commented out in the playbook. However, note that an upgrade to the configuration will result in a merge conflict because of the changes made in the playbook if the upgrade pristine branch is merged with the branch containing the commented playbook.

