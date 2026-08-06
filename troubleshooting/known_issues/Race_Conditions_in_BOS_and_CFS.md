# Race Conditions in BOS and CFS

## Summary

Both the [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos) and
[Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs)
have issues where race conditions can lead to unexpected or invalid behavior. These issues
come in two varieties:

* [API server race conditions](#api-server-race-conditions)
* [Operator race conditions](#operator-race-conditions)

## API server race conditions

The API servers for both BOS and CFS are multi-process and multi-threaded, allowing
multiple requests to be handled simultaneously. In the case where these requests impact
overlapping resources, problems can arise. This happens because the API servers are implemented
without taking this parallelism into account. An endpoint which modifies a resource will
read that resource from the database, modify the resource, and then write the modified
resource back to the database. If a delete request for that same resource is handled in the
middle of that process, the delete request will succeed, but the resource will still exist
in the database.

### Workaround for API server race conditions

In general, administrators should avoid making parallel requests that
change or delete the same resources.

### Fix for API server race conditions

This issue exists in all versions of BOS.
This issue exists in all versions of CFS prior to CSM 1.7.1.

## Operator race conditions

Both BOS v2 and CFS include operators that run separately from the API server.
In the case of CFS, these are the
[CFS batcher](../../operations/configuration_management/CFS_Batcher.md), the
[CFS hardware synchronization agent](../../operations/configuration_management/CFS_Hardware_Synchronization_Agent.md),
and the [CFS operator](../../operations/configuration_management/CFS_Operator.md).
In the case of BOS, there are many different
[BOS operators](../../operations/boot_orchestration/Operators.md).
In all cases, these operators generally work in a loop where they make a query to the
main service API, do some work based on the contents of the response, and possibly send a
request back to the main service to change or delete some resources. This offers a window
where a resource may change on the API server in the meantime, without the operator being
aware of it. This can lead to the operator overwriting changes or taking incorrect actions.

Because BOS has far more operators than CFS, it is more likely to encounter this race
condition than CFS is, but both services are susceptible to it.

### Workaround for operator race conditions

None.

### Fix for operator race conditions

This issue exists in all versions of BOS v2.
This issue exists in all versions of CFS.
