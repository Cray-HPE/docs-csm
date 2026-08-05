# BOS Log Level Change Issues

* [Summary](#summary)
* [Non-dynamic change](#non-dynamic-change)
* [Uninformative log level change message](#uninformative-log-level-change-message)

## Summary

There are a couple of issues related to changing the
[logging level](../../operations/boot_orchestration/Options.md#logging_level) for the
[Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos).

* [Non-dynamic change](#non-dynamic-change)
* [Uninformative log level change message](#uninformative-log-level-change-message)

## Non-dynamic change

After changing the BOS logging level, the [BOS API](../../operations/boot_orchestration/API.md)
server pod logs show a message reflecting this change. However, the server does not fully
pick up the change until the Kubernetes deployment of the API server is restarted.

*NOTE*: The [BOS Operators](../../operations/boot_orchestration/Operators.md) do not
have this issue -- they pick up the log level change without having to be restarted.

This issue exists in BOS in CSM 1.3 through CSM 1.6. It is fixed in CSM 1.7.

## Uninformative log level change message

After changing the BOS logging level, the BOS Kubernetes pods show a message reflecting this change.
There is an issue in which the new log level is displayed as an integer rather than a string.

The following is an example of what the message should look like:

```text
Logging level changed from INFO to DEBUG
```

When this issue is present, the message looks like the following:

```text
Logging level changed from INFO to 10
```

For the BOS API server, this bug exists in CSM 1.6.0 and CSM 1.6.1; it is fixed in CSM 1.6.2.
For the BOS operators, this bug exists in CSM 1.6; it is fixed in CSM 1.7.
