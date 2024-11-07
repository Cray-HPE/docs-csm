# Troubleshoot CFS Issues

> For known issues and troubleshooting information not covered on this page, see
> [CSM Troubleshooting Information](../../troubleshooting/README.md).

Due to CFS' nature as a framework that runs arbitrary Ansible content, there are any number of issues that can arise when attempting to configure a system.
Many of the issues are transient, especially on larger systems or when a long configuration is applied.
Because of this, CFS automatically retries configuration in many cases and a single failing session is often not an issue.
However, when a component is marked as failed or a number of sessions are failing there are two ways to approach debugging.

## Using the CFS debugger

To help debug and distinguish between issues in the CFS framework and issues in the Ansible content, CFS includes a debugging tool.
To access the tool, run the `cfs-debug` command.
This will pull up a list of the modes the debugger can run in.
For most users the default `auto-debug` mode will be most appropriate and will walk the user through a series of prompts and checks to determine the problem and recover from it if possible.

(`ncn-m#`)

```bash
cfs-debug
```

Example output:

```text
Select debugger mode. Type help for more details.
1) Auto-debug (default)
2) Directed-debug
3) Auto-debug report
4) Collect logs
5) Additional actions
0) Exit
```

## Manually debugging CFS

For issues where the `cfs-debugger` is not available or not able to diagnose an issue, see the following pages on manually debugging CFS.

* For sessions that failed, see [Troubleshoot Session Failed](Troubleshoot_CFS_Session_Failed.md).
* For sessions that are not starting, see [Troubleshoot Session Failing to Start](Troubleshoot_CFS_Sessions_Failing_to_Start.md).
* For sessions that are stuck and will not complete, see [Troubleshoot Session Failing to Complete](Troubleshoot_CFS_Session_Failing_to_Complete.md).

## Debug on failure

> **`NOTE`** This feature is only available in the v3 CFS API.

(`ncn-mw#`) CFS sessions can be created with the `debug_on_failure` flag.
If set to true this will cause sessions that fail during Ansible execution to remain running so that users can exec into the pod.

```bash
kubectl -n services exec -it <pod> -c ansible -- /bin/sh
```

Once debugging is complete users should touch the `/tmp/complete` file to complete and cleanup the session. If this is not done, the session will remain up until the `debug_wait_time` expires.

## Debug playbooks

> **`NOTE`** This feature is only available in the v3 CFS API.

CFS supports special debug playbooks, which are part of the AEE image and always available.
These playbooks can be used without requiring a special configuration to be created.
The following playbooks are available, and can be specified as the configuration name for a session if no other configuration has already been created with these names.

* `debug_fail` - This playbook immediately fails, which can be used with the `debug_on_failure` flag to create a quick debugging Ansible environment.
* `debug_facts` - This playbook gather and prints the facts for all available targets.
* `debug_noop` - This playbook will not gather facts or perform any tasks and is useful for skipping past the Ansible container for debugging.
