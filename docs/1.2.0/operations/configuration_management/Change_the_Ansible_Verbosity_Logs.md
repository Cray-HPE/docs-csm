# Change the Ansible Verbosity Logs

It is useful to view the Ansible logs in a Configuration Framework Session \(CFS\) session with greater verbosity than the default. CFS sessions are able to set the Ansible verbosity from the command line when the session is created. The verbosity will apply to all configuration layers in the session.

Specify an integer using the --ansible-verbosity option, where 1 = `-v`, 2 = `-vv`, and so on. Valid values range from 0 \(default\) to 4. See the `ansible-playbook` help for more information.

It is not recommended to use level 3 or 4 with sessions that target large numbers of hosts. When using `--ansible-verbosity` to debug Ansible plays or roles, consider also limiting the session targets with `--ansible-limit` to reduce log output.

> **WARNING:** Setting the `--ansible-verbosity` to 4 can cause CFS sessions to hang for unknown reasons. To correct this issue, reduce the verbosity to 3 or lower, or adjust the usage of the `display_ok_hosts` and `display_skipped_hosts` settings in the ansible.cfg file the session is using. Consider also reviewing the Ansible tasks being run and reducing the amount log output from these individual tasks.

