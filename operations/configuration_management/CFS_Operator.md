# CFS Operator

The CFS Operator is responsible for executing CFS sessions.
This includes:

* Managing the setup and teardown of Kubernetes jobs that run the [AEE](Ansible_Execution_Environments.md).
* Changing the session status from `pending` to `running` and from `running` to `complete`.

The CFS Operator communicates with the CFS API server using both traditional REST API
calls and the Kafka bus.

## More information

* [CFS Flow Diagrams](CFS_Flow_Diagrams.md)
* [Troubleshoot CFS Sessions Failing to Start](Troubleshoot_CFS_Sessions_Failing_to_Start.md)

## Known issues

* [Race Conditions in BOS and CFS](../../troubleshooting/known_issues/Race_Conditions_in_BOS_and_CFS.md)
