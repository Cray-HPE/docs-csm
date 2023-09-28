# Configure Ansible

The Configuration Framework Service \(CFS\) allows users to configure Ansible in the Ansible Execution Environment \(AEE\).
The default Ansible configuration file is accessible through the `cfs-default-ansible-cfg` Kubernetes ConfigMap in the `services` namespace.
Administrators can either update the existing ConfigMap, or create separate ConfigMaps to allow easy switching between Ansible configurations.

See the [Ansible Configuration](https://docs.ansible.com/ansible/latest/installation_guide/intro_configuration.html) external documentation for more information about what values can be set.

> **WARNING:** Much of the configuration in this file is required by CFS to function properly.
> Particularly the `cfs_aggregator` callback plug-in, which is used for reporting configuration state to the CFS APIs, and the `cfs_*` strategy plug-ins.
> Exercise extreme caution when making changes to this ConfigMap's contents.
> See [Ansible Execution Environments](Ansible_Execution_Environments.md) for more information.

## Update the default `ansible.cfg` file

(`ncn-mw#`) To view the `ansible.cfg` file:

```bash
kubectl edit cm -n services cfs-default-ansible-cfg
```

## Create a new `ansible.cfg` file

Administrators who want to make changes to the `ansible.cfg` file on a per-session or system-wide basis can upload a new file to a new ConfigMap in the `services` namespace, and then direct CFS to use their file.

1. Create a new `ansible.cfg` file.

1. (`ncn-mw#`) Create a new Kubernetes ConfigMap in the `services` namespace from this `ansible.cfg` file.

    ```bash
    kubectl create configmap custom-ansible-cfg -n services --from-file=ansible.cfg
    ```

## Use a custom `ansible.cfg` file

(`ncn-mw#`) The default Ansible configuration can be changed at a global level by updating the `default_ansible_config` option.
See [CFS Global Options](CFS_Global_Options.md) for more information on this setting global options.

```bash
cray cfs v3 options update --default-ansible-config <custom-ansible-cfg>
```

(`ncn-mw#`) Alternatively, it is possible to specify the Ansible configuration to be used for a single CFS session using the `ansible_config` option.

 ```bash
cray cfs v3 sessions create --name <session-name> --configuration-name <config-name> --ansible-config <custom-ansible-cfg>
```
