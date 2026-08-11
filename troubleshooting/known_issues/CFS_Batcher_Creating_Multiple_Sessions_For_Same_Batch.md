# CFS Batcher Creating Multiple Sessions For Same Batch

The [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)
has an issue in which the CFS Batcher
creates multiple
[CFS sessions](../../operations/configuration_management/Configuration_Sessions.md) for the same batch of
[components](../../operations/configuration_management/Configuration_Management_of_System_Components.md).

This issue arises when CFS Batcher makes a request to the CFS API to create a new session,
this request times out, but it ultimately succeeds (unbeknownst to CFS batcher). In this case,
CFS Batcher will attempt to create a new CFS session (with a different name) for that same batch.

CFS session creation timeouts like this have only been observed on systems which are experiencing
Kafka problems, causing communication retries between the CFS API server and the
CFS Operator.

## Fix

None -- this issue exists in all versions of CSM.

## Workaround

The only way to work around the issue is to investigate and address the problems that are
causing the session creation timeouts.

## Related

Kafka problems can also trigger another known issue with CFS:
[CFS Operator Creating Multiple Jobs For Same Session](CFS_Operator_Creating_Multiple_Jobs_For_Same_Session.md).
