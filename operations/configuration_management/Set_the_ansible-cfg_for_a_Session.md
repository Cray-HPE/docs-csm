# Set the `ansible.cfg` for a Session

View and update the Ansible configuration used by the Configuration Framework Service \(CFS\).

Ansible configuration is available through the `ansible.cfg` file.
See the [Configuring Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_configuration.html)
external documentation for more information about what values can be set.

CFS provides a default `ansible.cfg` file in the `cfs-default-ansible-cfg` Kubernetes ConfigMap in the `services` namespace.

(`ncn-mw#`) To view the `ansible.cfg` file:

```bash
kubectl get cm -n services cfs-default-ansible-cfg -o json | jq -r '.data."ansible.cfg"'
```

> **WARNING:** Much of the configuration in this file is required by CFS to function properly. Particularly the `cfs_aggregator`
> callback plug-in, which is used for reporting configuration state to the CFS APIs, and the `cfs_*` strategy plug-ins. Exercise extreme
> caution when making changes to this ConfigMap's contents. See [Ansible Execution Environments](Ansible_Execution_Environments.md) for
> more information.

The default `ansible.cfg` file ConfigMap can be changed to a custom ConfigMap \(within the `services` Kubernetes namespace\) by updating
it in the CFS service options. This will update all CFS sessions to use this file for `ansible.cfg`.

To use a different `ansible.cfg` on a per-session basis, use the `--ansible-config` option when creating a CFS session.
See [Use a Custom `ansible.cfg` File](Use_a_Custom_ansible-cfg_File.md) for more information.
