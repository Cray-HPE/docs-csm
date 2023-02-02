# Troubleshoot CFS Issues

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
Select debugger mode.  Type help for more details.
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
