# Boot Orchestration

The Boot Orchestration Service \(BOS\) currently supports two API versions, v1 and v2, that have different APIs and underlying mechanisms for performing operations on nodes.
The following is a summary of the changes, and the upgrade path, for users wishing to compare the two.

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
- BOS v2 leverages the Power Control Service (PCS).

## Upgrading from v1 to v2

To upgrade to BOS v2, users only need to start specifying v2 in the CLI or API. Scripts may also need to be updated to use the plural `sessions` and `sessiontemplates`, and to account for the other differences noted in the previous section.

When BOS is upgraded to a version that supports the v2 endpoints, it will automatically migrate all session templates to a v2 form.
BOS v1 versions of the session templates will also remain with `_v1_deprecated` appended to their names, although the converted v2 session templates can still be used with BOS v1.

## Mechanical differences

When a session is created in BOS v1, BOS starts a Kubernetes job called the Boot Orchestration Agent \(BOA\), which manages all of the nodes.
BOA moves through one phase at a time, ensuring that all nodes have completed the phase before moving on to the next. This means that all nodes proceed in lock step.

BOS v2 does away with BOA, replacing it with long-running operators that are each responsible for moving nodes through a particular phase transition.
These operators monitor nodes individually, not as a group, allowing each node to proceed at its own pace, improving retry handling and speeding up the overall booting process.

## The CLI

If no version is specified, the BOS CLI defaults to the `v2` endpoints. `cray bos <command>` defaults to `cray bos v2 <command>`. This is a change from the previous release.
To avoid compatibility issues when the CLI's default version changes, scripts using the CLI should always explicitly specify a version.
The behavior of defaulting to a version when the version parameter is omitted is a convenience to users and is not intended for scripts.
