# Boot Orchestration

The Boot Orchestration Service \(BOS\) currently supports API version v2.
The following is a summary of the changes BOS v2 made from v1, and the upgrade path from v1 to v2.

## BOS v1 removal

BOS v1 is removed in CSM 1.6. During the upgrade to CSM 1.6, all BOS v1 session data is deleted. Other BOS data
may be modified or, in rare cases, deleted. See [BOS data notice](../../upgrade/README.md#bos-data-notice) for more details.

## BOS v2 improvements

BOS v2 makes significant improvements to boot times, retries, and error handling, by allowing nodes to proceed through the boot process at their own pace.
Nodes that require extra time or retries to complete will no longer hold up the rest of the nodes, meaning that more nodes will reach a ready state faster.

## API differences

The v2 endpoints have plural nouns, using `sessions` and `sessiontemplates` rather than `session` and `sessiontemplate`. This is more consistent with other CSM APIs.

BOS v2 also introduces two new endpoints:

- A `/components` endpoint for tracking state at the component level. See [Components](Components.md) for details.
- An `/options` endpoint to allow changing global options dynamically. See [Options](Options.md) for details.

There are some different API responses in BOS v2 as well:

- Listing sessions in BOS v2 results in full session records rather than just a list of the current session names.
- The session status endpoint has also changed significantly. See [View the Status of a BOS Session](View_the_Status_of_a_BOS_Session.md) for more information on the session status endpoint.
- BOS v2 leverages the [Power Control Service (PCS)](../../glossary.md#power-control-service-pcs).

For more information on the BOS API, see [BOS API](../../api/bos.md).

## Upgrading from v1 to v2

To upgrade to BOS v2, users only need to start specifying v2 in the CLI or API. Scripts may also need to be updated to use the plural `sessions` and `sessiontemplates`, and to account for the other differences noted in the previous section.

When BOS is upgraded to a version that supports the v2 endpoints, it will automatically migrate all session templates to a v2 form.
BOS v1 versions of the session templates will also remain with `_v1_deprecated` appended to their names, although the converted v2 session templates can still be used with BOS v1.

## Mechanical differences

When a session was created in BOS v1, BOS started a Kubernetes job called the Boot Orchestration Agent \(BOA\), which managed all of the nodes.
BOA moved through one phase at a time, ensuring that all nodes had completed the phase before moving on to the next. This meant that all nodes proceeded in lock step.

BOS v2 does away with BOA, replacing it with long-running operators that are each responsible for moving nodes through a particular phase transition.
These operators monitor nodes individually, not as a group, allowing each node to proceed at its own pace, improving retry handling and speeding up the overall booting process.

## The CLI

If no version is specified, the BOS CLI defaults to the `v2` endpoints. `cray bos <command>` defaults to `cray bos v2 <command>`.
To avoid compatibility issues when the CLI's default version changes, scripts using the CLI should always explicitly specify a version.
The behavior of defaulting to a version when the version parameter is omitted is a convenience intended for interactive use and is not intended for scripts.
