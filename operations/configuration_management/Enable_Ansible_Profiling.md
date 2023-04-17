# Enable Ansible Profiling

Ansible tasks and playbooks can be profiled in order to single out poor performance in runtime.
Profiling execution times is the most common use-case because this can directly affect boot times.
The default Configuration Framework Service \(CFS\) `ansible.cfg` in the `cfs-default-ansible-cfg` ConfigMap does not enable this profiling by default, but does include information on the necessary Ansible callbacks.

 Alternatively, if editing the default `ansible.cfg` file is not desired, then a new Ansible configuration with profiling enabled can be created and used by CFS.
 See [Use a Custom `ansible.cfg` File](Use_a_Custom_ansible-cfg_File.md) for more information.

## Enabling execution time profiling

1. (`ncn-mw#`) Edit the `cfs-default-ansible-cfg` ConfigMap.

   ```bash
   kubectl edit cm cfs-default-ansible-cfg -n services
   ```

1. Uncomment the indicated line by removing the `#` character from the beginning of the line.

   ```yaml
   #callback_whitelist    = cfs_aggregator, timer, profile_tasks, profile_roles
   ```

1. Comment out the indicated line by adding a `#` character to the beginning of the line.

   ```yaml
   callback_whitelist    = cfs_aggregator
   ```

1. Save the modified ConfigMap.

After the modified ConfigMap has been saved, all new CFS sessions that are created will have profiling enabled; profiling information will be available in the Ansible logs of their session pods.

## Enabling memory profiling

Ansible memory profiling is somewhat limited by the constraints of running Ansible inside Kubernetes containers.
The profiling is useful for determining the relative memory consumption of different tasks,
but the exact values will include some slight overhead from the container because of the fact that a separate `cgroup` can not be easily created in the container's read-only file system.
Similarly, the play's `Execution Maximum` will incorrectly show a value of `0`, because the workaround for Ansible's attempts to write to a read-only file is to direct it to a temporary file.

1. (`ncn-mw#`) Edit the `cfs-default-ansible-cfg` ConfigMap.

   ```bash
   kubectl edit cm cfs-default-ansible-cfg -n services
   ```

1. Add `cgroup_memory_recap` to the `callback_whitelist` line that is currently uncommented.
This can be added to the execution time profiling tasks if desired, or it can be added on its own.  

   ```yaml
   callback_whitelist    = cfs_aggregator, cgroup_memory_recap
   ```

   or

   ```yaml
   callback_whitelist    = cfs_aggregator, timer, profile_tasks, profile_roles, cgroup_memory_recap
   ```

1. Add the following section to the configuration.

   > Note that the value for `max_mem_file` can not point to `/sys/fs/cgroup/memory`, because that is read-only in the container and Ansible will try to write to the `memory.max_usage_in_bytes` file.

   ```yaml
   [callback_cgroupmemrecap]
   cur_mem_file = /sys/fs/cgroup/memory/memory.usage_in_bytes
   max_mem_file = /tmp/memory.max_usage_in_bytes
   ```

1. Save the modified ConfigMap.

After the modified ConfigMap has been saved, all new CFS sessions that are created will have profiling enabled; profiling information will be available in the Ansible logs of their session pods.
