# Cray System Management (CSM) - Release Notes
## What’s new
## Bug Fixes
## Known Issues
- Cfs_session_stuck_in_pending: Under some circumstances Configuration Framework Service (CFS) sessions can get stuck in a `pending` state, never completing and potentially blocking other sessions. This addresses cleaning up those sessions.
- Conman_pod_kubernetes_copy_fails: The kubernetes copy file command fails when attempting to copy log files from the cray-conman pod.
* After a boot or reboot a few CFS Pods may continue running even after they've finished and never go away. For more information see [Orphaned CFS Pods After Booting or Rebooting](troubleshooting/known_issues/orphaned_cfs_pods.md).
