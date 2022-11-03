# Automatic Session Deletion with `sessionTTL`

By default, the Configuration Framework Service \(CFS\) will delete completed CFS sessions whose start date was more than seven days prior.
Kubernetes jobs associated with these sessions will also be deleted as part of this process.
This is done to ensure that CFS sessions do not accumulate and eventually adversely affect the performance of the Kubernetes cluster.

For larger systems or systems that do frequent reboots of nodes that are configured with CFS sessions, this setting may need to be reduced.

> **IMPORTANT:** The `sessionTTL` option deletes all completed sessions that meet the TTL criteria, regardless of if they were successful.

## Prerequisites

This requires that the Cray command line interface is configured. See [Configure the Cray Command Line Interface](../configure_cray_cli.md).

## Update `sessionTTL`

Update the `sessionTTL` using the following command:

```bash
ncn# cray cfs options update --session-ttl 24h
```

Example output will contain a line resembling the following:

```toml
sessionTTL = "24h"
```

## Disabling `sessionTTL`

To disable the `sessionTTL` feature, use an empty string as the argument of the `--session-ttl` flag:

```bash
ncn# cray cfs options update --session-ttl ""
```
