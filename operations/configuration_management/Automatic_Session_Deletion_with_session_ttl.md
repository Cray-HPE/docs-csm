# Automatic Session Deletion with `session_ttl`

By default, the Configuration Framework Service \(CFS\) will delete completed CFS sessions whose start date was more than seven days prior.
Kubernetes jobs associated with these sessions will also be deleted as part of this process.
This is done to ensure that CFS sessions do not accumulate and eventually adversely affect the performance of the Kubernetes cluster.

For larger systems or systems that do frequent reboots of nodes that are configured with CFS sessions, this setting may need to be reduced.

> **IMPORTANT:** The `session_ttl` option deletes all completed sessions that meet the TTL criteria, regardless of if they were successful.

## Update `session_ttl`

(`ncn-mw#`) Update the `session_ttl` using the following command:

```bash
cray cfs options update --session-ttl 24h --format toml
```

Example output will contain a line resembling the following:

```toml
session_ttl = "24h"
```

The `session_ttl` can be specified in hours (e.g. `24h`) or days (e.g. `7d`)

## Disable automatic session deletion

(`ncn-mw#`) To disable the `session_ttl` feature, use an empty string as the argument of the `--session-ttl` flag:

```bash
cray cfs options update --session-ttl ""
```
