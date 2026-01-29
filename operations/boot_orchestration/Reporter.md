# BOS Reporter

* [Overview](#overview)
* [RPM and service](#rpm-and-service)
* [Execution](#execution)
* [Reporting interval](#reporting-interval)
* [Network dependency](#network-dependency)
* [CFS state reporter](#cfs-state-reporter)
* [Source](#source)

## Overview

> The BOS reporter is a BOS v2 feature only.

The BOS reporter is a service that runs on all components managed by BOS v2.
It reports to BOS the current state and boot artifacts for the node on which it is running.
This is necessary for BOS v2 to be able to manage a node. For example, it is required in order for
BOS v2 to know that a node has successfully booted into the correct state.

## RPM and service

The `bos-reporter` RPM must be installed on nodes in order for BOS v2 to operate on them properly;
it typically is installed in node images when they are being customized.

(`linux#`) The reporter itself runs as a SystemD service.

```bash
systemctl status --no-pager --full bos-reporter
```

Example output:

```text
● bos-reporter.service - bos-status-reporter reports boot session information periodically to the BOS API
     Loaded: loaded (/usr/lib/systemd/system/bos-reporter.service; enabled; preset: enabled)
     Active: active (running) since Tue 2026-01-20 21:45:21 CST; 1 day 12h ago
   Main PID: 13765 (python3)
      Tasks: 1
        CPU: 2.545s
     CGroup: /system.slice/bos-reporter.service
             └─13765 /usr/lib/bos-reporter/venv/bin/python3 /opt/cray/csm/scripts/bos/bos_reporter

Jan 20 21:45:21 uan01 systemd[1]: Started bos-status-reporter reports boot session information periodically to the BOS API.
```

## Execution

When the BOS reporter first starts, it updates BOS immediately with the current state information.
It then waits for an interval of time before doing the next update. This continues indefinitely.

## Reporting interval

The wait interval between reporting is controlled by the [`component_actual_state_ttl`](Options.md#component_actual_state_ttl)
option. Specifically, the wait interval is set to be 75% of the option value. For example, if the option is set to 8 hours,
then the wait interval will be 2 hours.

An exception to this is the very first wait interval. This wait interval is a random amount of time between 0 and the
regular wait interval. If a large number of nodes are booted at the same time, this ensures that their BOS reporters will
not always be sending updates at the same time.

> **WARNING**: A zero value for the `component_actual_state_ttl` option will **not** disable the BOS reporter or cause it to
> report only once. For details, see [`component_actual_state_ttl`](Options.md#component_actual_state_ttl).

## Network dependency

The reporting is done using the [BOS API](API.md). Because of this, the BOS reporter will not work
on a node without network access to the [BOS API](API.md).

## CFS state reporter

The BOS reporter is somewhat analogous to the [CFS](../../glossary.md#configuration-framework-service-cfs) state reporter,
but there are import differences:

* Unlike the CFS state reporter, which runs once when a node first boots, the BOS reporter is expected to always be running.
* The CFS state reporter does not collect or report any state information about the node on which it is running; it is
  purely used to indicate that a node has booted successfully.

## Source

The location of the BOS reporter source code depends on its version. Prior to version 3.0.0,
the source for the BOS reporter is located in the
[`Cray-HPE/bos`](https://github.com/Cray-HPE/bos/) open source GitHub repository.
Starting in version 3.0.0, the source for the BOS reporter is located in the
[`Cray-HPE/bos-reporter`](https://github.com/Cray-HPE/bos-reporter/) open source GitHub repository.
