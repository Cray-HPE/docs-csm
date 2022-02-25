# CFS Sessions are Stuck in Pending State
In rare cases it is possible that a CFS session can be stuck in a `pending` state. Sessions should only enter the `pending` state briefly, for no more than a few seconds while the corresponding Kubernetes job is being scheduled. If any sessions are in this state for more than a minute, they can safely be deleted. If the sessions were created automatically and retires are enabled, the sessions should be recreated automatically.

Pending sessions can be found with the following command:
```
cray cfs sessions list --status pending
```

Stuck sessions that were created by the cfs-batcher can block further sessions from being scheduled against the same components. In the event that sessions are not being scheduled against some components, check the list of pending sessions to see if any are stuck and targeting the same component.
