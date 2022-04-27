# Configuration Management with the CFS Batcher

Creating configuration sessions with the Configuration Framework Service \(CFS\) enables remote execution for configuring live nodes and boot images prior to booting. CFS also provides its Batcher component for configuration management of registered system components. The CFS Batcher periodically examines the aggregated configuration state of registered components and schedules CFS sessions against those that have not been configured to their desired state. The frequency of scheduling, the maximum number of components to schedule in the same CFS session, and the expiration time for scheduling less than full sessions are configurable.

The CFS-Batcher schedules CFS sessions according to the following rules:

* Components are assigned to a batch if they need configuration, are not disabled, and are currently not assigned to a batch.
  * Components are grouped according to their desired state information.
  * A new batch is created if no partial batches match the desired state, and all similar batches are full.
* Batches are scheduled as CFS sessions when the batch is full or the batch window time has been exceeded.
  * The timer for the batch window is started when the first component is added, and is never reset. Nodes should never wait more than the window period between being ready for configuration and being scheduled in a CFS session.
* CFS cannot guarantee that jobs for similar batches will start at the same time, even if all CFS sessions are created at the same time. This variability is due to the nature of Kubernetes scheduling.
  * Checking the start time for the CFS session is more accurate than checking the pod start time when determining when a batch was scheduled.

There are two safety mechanisms built into the Batcher scheduling that can delay batches more than the usual amount of time. Both mechanisms are indicated in the logs:

* CFS Batcher will not schedule multiple sessions to configure the same component. Batcher monitors on-going sessions that it started so that if one session is started and the desired configuration changes, Batcher can wait until the initial session is completed before scheduling the component with the new configuration to a new session.
  * If Batcher is restarted, it will attempt to rebuild its state based on sessions with the "batcher-" naming scheme that are still in progress. This ensures that scheduling conflicts will not occur even if Batcher is restarted.
  * On restart, some information on the in-flight sessions is lost, so this wait ensures that the Batcher does not schedule multiple configuration sessions for the same component at the same time.
* If several CFS sessions that are created by the Batcher Agent fail in a row \(the most recent 20 sessions\), Batcher will start throttling the creation of new sessions.
  * The throttling is automatically reset if a single session succeeds. Users can also manually reset this by restarting Batcher.
  * The back-off is increased if new sessions continue to fail.
  * This helps protect against cases where high numbers of retries are allowed so that Batcher cannot flood Kubernetes with new jobs in a short period of time.

## Configure Batcher

Several Batcher behaviors are configurable. All of the Batcher configuration is available through the CFS options:

```bash
# cray cfs options list | grep -i batch
```

Example output:

```text
batchSize = 25
batchWindow = 60
batcherCheckInterval = 10
defaultBatcherRetryPolicy = 3
```

See [CFS Global Options](CFS_Global_Options.md) for more information. Use the `cray cfs options update` command to change these values as needed.

Review the following information about CFS Batcher options before changing the defaults. Setting these to non-optimal values may affect system performance. The optimal values will depend on system size and the specifics of the configuration layers that will be applied in the sessions created by CFS Batcher.

* **batchSize**

  This option determines the maximum number of components that will be included in each session created by CFS Batcher.

  The default value is 25 components per session.

  > **WARNING:** Increasing this value will result in fewer batcher-created sessions, but will also require more resources for Ansible Execution Environment \(AEE\) containers to do the configuration.

* **batchWindow**

  This option sets the number of seconds that CFS batcher will wait before scheduling a CFS session when the number of components needing configuration has not reached the batchSize limit. CFS Batcher will immediately create a session when the batchSize limit is reached. However, in the case where there are few components or long periods of time between components notifying CFS Batcher of the need for configuration, the batchWindow will time-box the creation of sessions so no component needs to wait for the queue to fill.

  The default value is 60 seconds.

  > **WARNING:** Lower values will cause CFS Batcher to be more responsive to creating sessions, but values too low may result in degraded performance of both the CFS APIs as well as the overall system.

* **batcherCheckInterval**

  This option sets how often CFS batcher checks for components waiting to be configured. This value must be lower than batchWindow value.

  The default value is 10 seconds.

  > **WARNING:** Lower values will cause CFS Batcher to be more responsive to creating sessions, but values too low may result in degraded performance of the CFS APIs on larger systems.

* **defaultBatcherRetryPolicy**

  When a component \(node\) requiring configuration fails to configure from a previous configuration session launched by CFS Batcher, the error is logged. defaultBatcherRetryPolicy is the maximum number of failed configurations allowed per component before CFS Batcher will stop attempts to configure the component.

  This value can be overridden on a per component basis.

## List CFS Batcher Sessions

The CFS Batcher prepends all CFS session names it creates with `batcher-`. Sessions that have be created by CFS Batcher are found by using the following command with the `--name-contains` option:

```bash
# cray cfs sessions list --name-contains batcher-
```

To list the batcher sessions that are currently running, filter with the `cray cfs sessions list` command options:

```bash
# cray cfs sessions list --name-contains batcher- --status running
```

Use the `cray cfs sessions list --help` command output for all filtering options, including session age, tags, status, and success.

## Map CFS Batcher Sessions to BOS Sessions

To find all of the sessions created by the CFS Batcher because of configuration requests made by a specific Boot Orchestration Service \(BOS\) session, filter the sessions by the name of the BOS session, which is added as a tag on the sessions. The BOS session ID is required to run the following command.

```bash
# cray cfs sessions list --tags bos_session=BOS_SESSION_ID
```

