# Change the Ansible Verbosity Logs

* [Overview](#overview)
* [How Ansible verbosity level is determined](#how-ansible-verbosity-level-is-determined)
* [Considerations for high verbosity levels](#considerations-for-high-verbosity-levels)
* [Creating sessions with increased verbosity][create]
* [Increasing verbosity for sessions that are not created directly][indirect]

## Overview

When debugging, it can be useful to view the Ansible logs with greater verbosity than
the default. The verbosity level is an integer. Valid verbosity levels are integers
`0` (the default) through `4`, with higher numbers indicating increased verbosity.
These translate into the number of `-v` arguments passed into the `ansible-playbook`
command when the playbooks are executed.

| *Verbosity* | *Argument* |
|:-----------:| ---------- |
| `0`         |            |
| `1`         | `-v`       |
| `2`         | `-vv`      |
| `3`         | `-vvv`     |
| `4`         | `-vvvv`    |

## How Ansible verbosity level is determined

The Ansible verbosity is determined at the time that the CFS session starts.
The verbosity is applied to all configuration layers in the session.
The verbosity is set to the first one of the following things that successfully
specifies a verbosity level.

1. If a verbosity level was specified directly when the session was created (using the
   CFS API or CLI), then this level is used.
1. If an Ansible configuration was specified directly when the session was created
   (using the CFS API or CLI), and if that configuration specifies a verbosity level,
   then this level is used.
1. If no Ansible configuration was specified directly when the session was created
   (using the CFS API or CLI), and if a verbosity level is specified in the
   [default Ansible configuration][ancfg], then this level is used.
1. Default to running at a verbosity level of `0`.

For more information on Ansible configurations, see
[Set the `ansible.cfg` for a Session](Set_the_ansible-cfg_for_a_Session.md).

## Considerations for high verbosity levels

When increasing Ansible verbosity, be aware that it can produce a lot of output, and
in some cases can even cause problems.

* It is not recommended to use level `3` or `4` with sessions that target a large numbers
  of hosts. Avoid this by setting an Ansible limit, reducing the number of targets.
  * See [Creating sessions with increased verbosity][create] for details on
    how to specify an Ansible limit.
* Consider reviewing the Ansible tasks being run and altering them, in order to reduce their
  log output.
* **WARNING:** Setting the Ansible verbosity to `4` can cause CFS sessions to hang. There
  are multiple ways to avoid this issue:
  * Reduce the verbosity to `3` or lower.
  * Adjust the `display_ok_hosts` and `display_skipped_hosts` settings in the
    Ansible configuration that the session is using. For more details, see
    [Set the `ansible.cfg` for a Session](Set_the_ansible-cfg_for_a_Session.md).

## Creating sessions with increased verbosity

When creating a CFS session using the API or CLI, there are several different parameters that
may be specified. The following table shows the appropriate argument or field to use in
order to specify the Ansible configuration, limit, or verbosity.

> If no Ansible configuration is directly specified, the session will use the
> [default Ansible configuration][ancfg].

| *Parameter*             | *CLI*                 | *API*              |
| ----------------------- | --------------------- | ------------------ |
| *Ansible configuration* | `--ansible-config`    | `ansibleConfig`    |
| *Ansible limit*         | `--ansible-limit`     | `ansibleLimit`     |
| *Ansible verbosity*     | `--ansible-verbosity` | `ansibleVerbosity` |

## Increasing verbosity for sessions that are not created directly

Not all CFS sessions are created directly by an administrator. For example:

* A session may be created indirectly (as part of a [SAT][sat] operation or a script being run,
  for example).
* A session may be created by the CFS batcher. For more information,
  see [Configuration Management with the CFS Batcher](Configuration_Management_with_the_CFS_Batcher.md).

In these cases, an administrator is not able to directly specify these parameters using the
method described in the previous section. However, these sessions will run using the
[default Ansible configuration][ancfg]. Any parameters specified in this Ansible
configuration will be used in these automatic or indirectly-created CFS sessions.
In particular, this is where an administrator is able to specify an Ansible verbosity
level for these sessions. For more details, see [Set the `ansible.cfg` for a Session](Set_the_ansible-cfg_for_a_Session.md).

<!--- Define the reference-style Markdown links used to improve readability -->

[ancfg]: CFS_Global_Options.md#default-ansible-configuration
[create]: #creating-sessions-with-increased-verbosity
[indirect]: #increasing-verbosity-for-sessions-that-are-not-created-directly
[sat]: ../../glossary.md#system-admin-toolkit-sat
