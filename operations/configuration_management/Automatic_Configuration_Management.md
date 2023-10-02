# Automatic Configuration Management

In addition to creating individual configuration sessions, the Configuration Framework Service \(CFS\) can also automatically configure any registered system components.
The `CFS-Batcher` periodically examines the configuration state of registered components and schedules CFS sessions against those that have not been configured to their desired state.
The frequency of scheduling, the maximum number of components to schedule in the same CFS session, and the expiration time for scheduling less than full sessions are configurable.

* [Automatic configuration triggers](#automatic-configuration-triggers)
* [`CFS-Batcher` scheduling](#cfs-batcher-scheduling)
* [`CFS-Batcher` safety mechanisms](#cfs-batcher-safety-mechanisms)
* [Configure `CFS-Batcher`](#configure-cfs-batcher)
* [List `CFS-Batcher` sessions](#list-cfs-batcher-sessions)
* [Map `CFS-Batcher` sessions to BOS sessions](#map-cfs-batcher-sessions-to-bos-sessions)

## Automatic configuration triggers

There are several situations that will cause automatic configuration:

* When rebooted, components that have the `cfs-state-reporter` package installed will clear the component's recorded state, resulting in a full configuration.
* When a configuration is updated, all components with that desired configuration will automatically get updates for the layers of the configuration that have changed.
* If a configuration is only partially applied because of a previous failed configuration session and the component has not exceeded its maximum retries, it will be configured with any layers of the configurations that have not yet been successfully applied.
* When a user manually resets the configuration state of a component, it will force reconfiguration without rebooting a node.
* If a manual CFS session applies a version of a playbook that conflicts with the version in the desired configuration, CFS will re-apply the desired version after the manual session is completed.
* Any other situation that causes the desired state to not match with the current state of a component will trigger automatic configuration.
CFS only tracks the current state of components as they are configured by CFS sessions.
It does not track configuration state created or modified by other tooling on the system.

## `CFS-Batcher` scheduling

The `CFS-Batcher` schedules CFS sessions according to the following rules:

* Components are assigned to a batch if they need configuration, are not disabled, and are currently not assigned to a batch.
  * Components are grouped according to their desired state information.
  * A new batch is created if no partial batches match the desired state, and all similar batches are full.
* Batches are scheduled as CFS sessions when the batch is full or the batch window time has been exceeded.
  * The timer for the batch window is started when the first component is added, and is never reset.
  Nodes should never wait more than the window period between being ready for configuration and being scheduled in a CFS session.
* CFS cannot guarantee that jobs for similar batches will start at the same time, even if all CFS sessions are created at the same time.
  This variability is due to the nature of Kubernetes scheduling.
  * Checking the start time for the CFS session is more accurate than checking the pod start time when determining when a batch was scheduled.

## `CFS-Batcher` safety mechanisms

There are two safety mechanisms built into the `CFS-Batcher` scheduling that can delay batches more than the usual amount of time.
Both mechanisms are indicated in the logs:

* `CFS-Batcher` will not schedule multiple sessions to configure the same component.
  `CFS-Batcher` monitors on-going sessions that it started so that if one session is started and the desired configuration changes,
  `CFS-Batcher` can wait until the initial session is completed before scheduling the component with the new configuration to a new session.
  * If `CFS-Batcher` is restarted, it will attempt to rebuild its state based on sessions with the "batcher-" naming scheme that are still in progress.
  This ensures that scheduling conflicts will not occur even if `CFS-Batcher` is restarted.
  * On restart, some information on the in-flight sessions is lost, so this wait ensures that `CFS-Batcher` does not schedule multiple configuration sessions for the same component at the same time.
* If several CFS sessions that are created by the `CFS-Batcher` fail in a row \(the most recent 20 sessions\), `CFS-Batcher` will start
  throttling the creation of new sessions.
  * The throttling is automatically reset if a single session succeeds. Users can also manually reset this by restarting `CFS-Batcher`.
  * The back-off is increased if new sessions continue to fail.
  * This helps protect against cases where high numbers of retries are allowed so that `CFS-Batcher` cannot flood Kubernetes with new jobs in a short period of time.

## Configure `CFS-Batcher`

(`ncn-mw#`) Several `CFS-Batcher` behaviors are configurable.
All of the `CFS-Batcher` configuration is available through the CFS options:

```bash
cray cfs v3 options list --format json | grep -i batch
```

Example output:

```json
  "batch_size": 25,
  "batch_window": 60,
  "batcher_check_interval": 10,
  "batcher_disable": false,
  "batcher_max_backoff": 3600,
  "batcher_pending_timeout": 300,
  "default_batcher_retry_policy": 3,
```

See [CFS Global Options](CFS_Global_Options.md) for more information.

Setting these to non-optimal values may affect system performance.
The optimal values will depend on system size and the specifics of the configuration layers that will be applied in the sessions created by `CFS-Batcher`.

## List `CFS-Batcher` sessions

(`ncn-mw#`) The `CFS-Batcher` prepends all CFS session names it creates with `batcher-`. Sessions that have be created by `CFS-Batcher`
are found by using the following command with the `--name-contains` option:

```bash
cray cfs v3 sessions list --name-contains batcher-
```

(`ncn-mw#`) To list the batcher sessions that are currently running, filter with the `cray cfs v3 sessions list` command options:

```bash
cray cfs v3 sessions list --name-contains batcher- --status running
```

Use the `cray cfs v3 sessions list --help` command output for all filtering options, including session age, tags, status, and success.

## Map `CFS-Batcher` sessions to BOS sessions

(`ncn-mw#`) To find all of the sessions created by the `CFS-Batcher` because of configuration requests made by a specific
Boot Orchestration Service \(BOS\) session, filter the sessions by the name of the BOS session, which is added as a tag on the CFS sessions.
The BOS session ID is required to run the following command.

```bash
cray cfs v3 sessions list --tags bos_session=BOS_SESSION_ID
```
