# CFS Operator

The CFS Operator is responsible for executing CFS sessions.
This includes:

* Managing the setup and teardown of Kubernetes jobs that run the [AEE](Ansible_Execution_Environments.md).
* Changing the session status from `pending` to `running` and from `running` to `complete`.

The CFS Operator communicates with the CFS API server using both traditional REST API
calls and the Kafka bus.

## More information

* [CFS Flow Diagrams](CFS_Flow_Diagrams.md)

## Known issues

* [Troubleshoot CFS Sessions Failing to Start](Troubleshoot_CFS_Sessions_Failing_to_Start.md)
* [Race Conditions in BOS and CFS](../../troubleshooting/known_issues/Race_Conditions_in_BOS_and_CFS.md)
* [CFS Operator Creating Multiple Jobs For Same Session](../../troubleshooting/known_issues/CFS_Operator_Creating_Multiple_Jobs_For_Same_Session.md)
* [CFS Batcher Creating Multiple Sessions For Same Batch](../../troubleshooting/known_issues/CFS_Batcher_Creating_Multiple_Sessions_For_Same_Batch.md)
* [CFS Sessions Stuck Pending](../../troubleshooting/known_issues/CFS_Sessions_Stuck_Pending.md)
