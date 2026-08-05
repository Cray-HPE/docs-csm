# BOS Log Level Change Not Dynamic

After changing the [logging level](../../operations/boot_orchestration/Options.md#logging_level)
in the [Boot Orchestration Service (BOS)](../../glossary.md#boot-orchestration-service-bos),
the [BOS API](../../operations/boot_orchestration/API.md) server pod logs show a message
reflecting this change. However, the server does not fully
pick up the change until the Kubernetes deployment of the API server is restarted.

*NOTE*: The [BOS Operators](../../operations/boot_orchestration/Operators.md) do not
have this issue -- they pick up the log level change without having to be restarted.

This issue exists in BOS in CSM 1.3 through CSM 1.6. It is fixed in CSM 1.7.
