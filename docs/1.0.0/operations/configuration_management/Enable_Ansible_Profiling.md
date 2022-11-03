# Enable Ansible Profiling

Ansible tasks and playbooks can be profiled in order to determine execution times and single out poor performance in runtime. The default Configuration Framework Service \(CFS\) ansible.cfg in the cfs-default-ansible-cfg ConfigMap does not enable these profiling tools. If profiling tools are desired, modify the default Ansible configuration file to enable them.

### Procedure

1.  Edit the cfs-default-ansible-cfg ConfigMap.

    ```bash
    ncn# kubectl edit cm cfs-default-ansible-cfg -n services
    ```

2.  Uncomment the indicated line by removing the \# character from the beginning of the line.

    ```bash
    #callback_whitelist    = cfs_aggregator, timer, profile_tasks, profile_roles
    ```

3.  Comment out the indicated line by adding a \# character to the beginning of the line.

    ```bash
    callback_whitelist    = cfs_aggregator
    ```


New sessions will be created with profiling information available in the Ansible logs of the session pods. Alternatively, if editing the default ansible.cfg file that CFS uses, is not desired, a new Ansible configuration can also be created to enable profiling and direct CFS to use it. See [Use a Custom ansible-cfg File](Use_a_Custom_ansible-cfg_File.md) for more information.

