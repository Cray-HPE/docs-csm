# CFS Operator Creating Multiple Jobs For Same Session

The [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)
has an issue in which the [CFS Operator](../../operations/configuration_management/CFS_Operator.md)
creates multiple Kubernetes jobs for the same
[CFS session](../../operations/configuration_management/CFS_Sessions.md).

When a new session is created, the CFS API server communicates this to the CFS operator
over the Kafka bus. This communication is what causes the CFS operator to create a
Kubernetes job for the session. This issue arises in a case where the CFS API server thinks the
Kafka send failed or timed out, when it actually succeeded. The CFS API server then retries the
send, resulting in multiple Kafka messages for the same session. There are no guardrails in place
to handle this, and it results in the CFS operator creating multiple Kubernetes jobs.

This issue has only been observed on systems which are experiencing Kafka problems.

## Fix

This issue is fixed in [CSM 1.7.1-patch.2](../../RELEASE_NOTES_1.7.1-patch.2.md); the issue exists in all earlier versions of CSM.

## Workaround

The only way to work around the issue is to investigate and address the problems that are
causing the Kafka bus problems.

## Related

Kafka problems can also trigger another known issue with CFS:
[CFS Batcher Creating Multiple Sessions For Same Batch](CFS_Batcher_Creating_Multiple_Sessions_For_Same_Batch.md).
