# Use a Custom ansible-cfg File

The Configuration Framework Service \(CFS\) allows for flexibility with the Ansible Execution Environment \(AEE\) by allowing for changes to included ansible.cfg file. When installed, CFS imports a custom ansible.cfg file into the cfs-default-ansible-cfg Kubernetes ConfigMap in the services namespace.

Administrators who want to make changes to the ansible.cfg file on a per-session or system-wide basis can upload a new file to a new ConfigMap and direct CFS to use their file. See [Set the ansible.cfg for a Session](Set_the_ansible-cfg_for_a_Session.md) for more information.

To create a custom ansible.cfg that CFS can use, create a new ansible.cfg file and a ConfigMap:

```bash
ncn# vi ansible.cfg     # create an Ansible config file
ncn# kubectl create configmap custom-ansible-cfg -n services --from-file=ansible.cfg
```

To use this Ansible configuration file for a specific session, set `--ansible-config custom-ansible-cfg` when creating a session, or set `--default-ansible-config custom-ansible-cfg` when setting global CFS options with the `cray cfs options update` command.

