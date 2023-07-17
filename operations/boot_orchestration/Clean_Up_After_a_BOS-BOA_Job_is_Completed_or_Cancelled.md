# Clean Up After a BOS/BOA Job is Completed or Cancelled

> **`NOTE`** This section is for Boot Orchestration Service (BOS) v1 only. BOS v2 does not use Boot Orchestration Agent (BOA) jobs and does not require cleanup.

When a BOS session is created, there are a number of items created on the system. When a session is cancelled or completed, these items need to be cleaned up to ensure there is not lingering content from the session on the system.

When a session is launched, the following items are created:

- **BOA job:** The Kubernetes job that runs and handles the BOS session.
- **ConfigMap for BOA:** This ConfigMap contains the configuration information that the BOA job uses. The BOA pod mounts a ConfigMap named `boot-session` at `/mnt/boot_session` inside
  the pod. The name of the ConfigMap has a one-to-one relationship to the name of the BOS session created; however, the name of the BOS session can be different from the name of the
  session template used to create it. For created sessions that do not specify a name, this is most commonly a UUID value.
- **Etcd entries:** BOS makes an entry for the session in its Etcd key/value store. If the BOA job has run for long enough, it will also have written a status entry into Etcd for this session.
- **Configuration Framework Service \(CFS\) session:** If configuration is enabled, and the session is doing a boot, reboot, or configure operation, then BOA will have instructed CFS
  to configure the nodes once they boot. There is not an easy way to link a BOA session to the CFS sessions that are spawned.

## Prerequisites

- A BOS session has been completed or cancelled.
- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray CLI](../configure_cray_cli.md).

## Procedure

1. (`ncn-mw#`) Identify the BOA job that needs to be deleted.

    Describe the BOS session to find the name of the BOA job under the attribute `boa_job_name`.

    ```bash
    cray bos v1 session describe --format json BOS_SESSION_ID
    ```

    Example output:

    ```json
    {
      "status_link": "/v1/session/d200f7e4-1a9f-4466-9ef4-30add3bd87dd/status",
      "complete": "",
      "start_time": "2020-08-11 21:02:09.137917",
      "templateUuid": "cle-1.3.0-nid1",
      "error_count": "",
      "boa_job_name": "boa-d200f7e4-1a9f-4466-9ef4-30add3bd87dd",
      "in_progress": "",
      "operation": "boot",
      "stop_time": null
    }
    ```

1. (`ncn-mw#`) Find the ConfigMap for the BOA job.

    The ConfigMap is listed as `boot-session` under the Volumes section. Retrieve the `Name` value from the returned output.

    ```bash
    kubectl -n services describe job BOA_JOB_NAME
    ```

    Excerpt of example output:

    ```yaml
      Volumes:
       boot-session:
        Type:      ConfigMap (a volume populated by a ConfigMap)
        **Name:      e786def5-37a6-40db-b36b-6b67ebe174ee**
        Optional:  false
    ```

1. (`ncn-mw#`) Delete the ConfigMap.

    ```bash
    kubectl -n services delete cm CONFIGMAP_NAME
    ```

1. (`ncn-mw#`) Delete the etcd entry for the BOS session.

    ```bash
    cray bos v1 session delete BOS_SESSION_ID
    ```

1. (`ncn-mw#`) Stop CFS from configuring nodes.

    There are several different use cases covered in this step. The process varies depending on whether a job is being cancelled, or if the CFS content is simply being cleaned up.

    In the BOS session template, if configuration is enabled, then BOA instructs the nodes to configure on boot when doing a boot or reboot operation. When only doing a configure operation,
    the configuration happens right away. If configuration is disabled or the operation is shutdown, then BOA will not instruct CFS to configure the nodes, and nothing further needs to be done. The remainder of this step may be skipped.

    If BOA instructs CFS to configure the nodes, then CFS will set the desired configuration for the nodes in its database. Once BOA tells CFS to configure the nodes, which happens early
    in the BOA job, then CFS will configure the nodes immediately if the operation is configure, or upon the node booting if the operation is boot or reboot.

    Attempting to prevent CFS from configuring the nodes is a multi-step, tedious process. It may be simpler to allow CFS to configure the nodes. If the nodes are going to be immediately
    rebooted, then the CFS configuration will be rerun once the nodes have booted, thus undoing any previous configuration. Alternatively, if the nodes are going to be immediately
    shutdown, then this will remove any need to prevent CFS from configuring the nodes.

    Follow the procedures for one of the following use cases:

    - Configuration has completed and the sessions need to be cleaned up the to reduce clutter:

        1. Find the old sessions that needs to be deleted.

            ```bash
            cray cfs sessions list
            ```

        1. Delete the sessions.

            ```bash
            cray cfs sessions delete CFS_SESSION_NAME
            ```

    - Configuration has completed and the desired state needs to be cleaned up so that configuration does not happen on restart:

        1. Unset the desired state for all affected components.

            1. Find the component names (xnames) for the components with the desired configuration matching what was applied.

                ```bash
                cray cfs components list
                ```

            1. Prevent the configuration from running.

                ```bash
                cray cfs components update XNAME --desired-config ""
                ```

            This needs to be done for each component. It is enough to prevent configuration from running, and it does not revert to the previous desired state. The previous desired state has
            already been overwritten at this point, so if the user is trying to completely revert, they will either need to know and apply the previous desired state manually, or create a BOS
            session with the previous template using the `configure` operation.

    - Configuration was set/started and needs to be cancelled:

        1. Unset the desired state for all components affected.

            1. Find the impacted component names (xnames) for the components with the desired configuration matching what was applied.

                ```bash
                cray cfs components list
                ```

            1. Prevent the configuration from running.

                ```bash
                cray cfs components update XNAME --desired-config ""
                ```

            This needs to be done for each component. It is enough to prevent configuration from running, and it does not revert to the previous desired state. The previous desired state has
            already been overwritten at this point, so if the user is trying to completely revert, they will either need to know and apply the previous desired state manually, or create a BOS
            session with the previous template using the `configure` operation.

        1. Restart the batcher.

            This will purge any information that CFS cached in relation to the BOA job that it was intending to act upon.

            1. Get the `cfs-batcher` pod ID.

                ```bash
                kubectl -n services get pods|grep cray-cfs-batcher
                ```

                Example output:

                ```text
                cray-cfs-batcher-644599c6cc-rwl8f           2/2     Running             0          6d17h
                ```

            1. Restart the pod by scaling the replicas to 0 in order to stop it, and then back up to 1 in order to restart it.

                ```bash
                kubectl -n services scale CFS-BATCHER_POD_ID --replicas=0
                kubectl -n services scale CFS-BATCHER_POD_ID --replicas=1
                ```

        1. Find the existing session that needs to be deleted.

            ```bash
            cray cfs sessions list
            ```

        1. Delete the sessions.

            This step must be done after restarting `cfs-batcher`. If the cached information is not purged from the batcher first, then the batcher may start additional CFS sessions
            in response to them being killed. The batcher agent would fight against the user if it is not restarted.

            Unfortunately, it is hard to link a specific BOA session to a CFS session. At this time, they are identified by comparing the CFS timestamps with those of the BOA job, and
            associating them based on proximity. Additionally, one may examine the components in the CFS job to see that they match the components in the BOA job.

            ```bash
            cray cfs sessions delete CFS_SESSION_NAME
            ```

1. (`ncn-mw#`) Delete the BOA job.

    The BOA job is not deleted right away because it is needed to find the ConfigMap name.

    ```bash
    kubectl -n services delete job BOA_JOB_NAME
    ```
