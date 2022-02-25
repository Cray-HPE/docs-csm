# Cray System Management (CSM) - Release Notes
## What’s New
## Bug Fixes
## Known Issues
* Incorrect_output_for_bos_command_rerun: When a Boot Orchestration Service (BOS) session fails, it may output a message in the Boot Orchestration Agent (BOA) log associated with that session. This output contains a command that instructs the user how to re-run the failed session. It will only contain the nodes that failed during that session. The command is faulty, and this issue addresses correcting it.
* Cfs_session_stuck_in_pending: Under some circumstances, Configuration Framework Service (CFS) sessions can get stuck in a `pending` state, never completing and potentially blocking other sessions. This addresses cleaning up those sessions.
* The `branch` parameter in CFS configurations may not work, and setting it will instead return an error. Continue setting the git commit hash instead.
* After a boot or reboot a few CFS Pods may continue running even after they have finished and never go away. For more information see [Orphaned CFS Pods After Booting or Rebooting](troubleshooting/known_issues/orphaned_cfs_pods.md).
