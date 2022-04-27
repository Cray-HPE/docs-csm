# Automatic Session Deletion with `sessionTTL`

By default, when a session completes, the Configuration Framework Service \(CFS\) will delete sessions and Kubernetes jobs associated with the session when the start date was more than seven days prior. This is done to ensure CFS sessions do not accumulate and eventually adversely affect the performance of the Kubernetes cluster.

For larger systems or systems that do frequent reboots of nodes that are configured with CFS sessions, this setting may need to be reduced.

Update the `sessionTTL` using the following command:

```bash
ncn# cray cfs options update --session-ttl 24h
```

Example output:

```text
[...]

sessionTTL = "24h"
```

To disable the `sessionTTL` feature, use `--session-ttl ""` in the command above.

> **IMPORTANT:** The `sessionTTL` option deletes all completed sessions that meet the TTL criteria, regardless of if they were successful.

