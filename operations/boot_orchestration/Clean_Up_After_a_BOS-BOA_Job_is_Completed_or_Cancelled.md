# Clean Up After a BOS/BOA Job is Completed or Cancelled

When a BOS session is created, there are a number of items created on the system. When a session is cancelled or completed, these items need to be cleaned up to ensure there is not lingering content from the session on the system.

When a session is launched, the items below are created:

-   **Boot Orchestration Agent \(BOA\) job:** The Kubernetes job that runs and handles the BOS session.
-   **ConfigMap for BOA:** This ConfigMap contains the configuration information that the BOA job uses. The BOA pod mounts a ConfigMap named `boot-session` at /mnt/boot\_session inside the pod. This ConfigMap has a random UUID name, such as e786def5-37a6-40db-b36b-6b67ebe174ee. This name does not obviously connect it to the BOA job.
-   **etcd entries:** BOS makes an entry for the session in its etcd key/value store. If the BOA job has run for long enough, it will also have written a status entry into etcd for this session.
-   **Configuration Framework Service \(CFS\) session:** If configuration is enabled, and the session is doing a boot, reboot, or configure operation, then BOA will have instructed CFS to configure the nodes once they boot. There is not an easy way to link a BOA session to the CFS sessions that are spawned.


### Prerequisites

-   A Boot Orchestration Service \(BOS\) session has been completed or cancelled.
-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.


### Procedure

1.  Identify the BOA job that needs to be deleted.

    Describe the BOS session to find the name of the BOA job under the attribute `boa_job_name`.

    ```bash
    ncn-m001# cray bos session describe --format json BOS_SESSION_ID
    ```

    Example output:

    ```
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

2.  Find the ConfigMap for the BOA job.

    The ConfigMap is listed as `boot-session` under the Volumes section. Retrieve the `Name` value from the returned output.

    ```bash
    ncn-m001# kubectl -n services describe job BOA_JOB_NAME
    ```

    Example output:

    ```
    [...]
      Volumes:
       boot-session:
        Type:      ConfigMap (a volume populated by a ConfigMap)
        **Name:      e786def5-37a6-40db-b36b-6b67ebe174ee**
        Optional:  false
    ```

3.  Delete the ConfigMap.

    ```bash
    ncn-m001# kubectl -n services delete cm CONFIGMAP_NAME
    ```

4.  Delete the etcd entry for the BOS session.

    ```bash
    ncn-m001# cray bos session delete BOS_SESSION_ID
    ```

5.  Stop CFS from configuring nodes.

    There are several different use cases covered in this step. The process varies depending on whether a job is being cancelled, or if the CFS content is simply being cleaned up.

    In the BOS session template, if configuration is enabled, BOA instructs the nodes to configure on boot when doing a boot or reboot operation. When only doing a configure operation, the configuration happens right away. If configuration is disabled or the operation is shutdown, then BOA will not instruct CFS to configure the nodes, and nothing further needs to be done. The remainder of this step may be skipped.

    If BOA instructs CFS to configure the nodes, then CFS will set the desired configuration for the nodes in its database. Once BOA tells CFS to configure the nodes, which happens early in the BOA job, then CFS will configure the nodes immediately if the operation is configure, or upon the node booting if the operation is boot or reboot.

    Attempting to prevent CFS from configuring the nodes is a multi-step, tedious process. It may be simpler to allow CFS to configure the nodes. If the nodes are going to be immediately rebooted, then the CFS configuration will be rerun once the nodes have booted, thus undoing any previous configuration. Alternately, if the nodes are going to be immediately shutdown, this will remove any need to prevent CFS from configuring the nodes.

    Follow the procedures for one of the following use cases:

    -   Configuration has completed and the sessions need to be cleaned up the to reduce clutter:
        1.  Find the old sessions that needs to be deleted.

            ```bash
            ncn-m001# cray cfs sessions list
            ```

        2.  Delete the sessions.

            ```bash
            ncn-m001# cray cfs sessions delete CFS_SESSION_NAME
            ```

    -   Configuration has completed and the desired state needs to be cleaned up so that configuration does not happen on restart:
        1.  Unset the desired state for all components affected.

            To find the impacted component names (xnames) for the components with the desired configuration matching what was applied:

            ```bash
            ncn-m001# cray cfs components list
            ```

            Prevent the configuration from running:

            ```bash
            ncn-m001# cray cfs components update XNAME --desired-state-commit
            ```

            This needs to be done for each component. It is enough to prevent configuration from running, and it does not revert to the previous desired state. The previous desired state has already been overwritten at this point, so if the user is trying to completely revert, they will either need to know and apply the previous desired state manually, or return BOS with the previous template using the configure operation \(which may also trigger a configure operation\).

    -   Configuration was set/started and needs to be cancelled:
        1.  Unset the desired state for all components affected.

            To find the impacted component names (xnames) for the components with the desired configuration matching what was applied:

            ```bash
            ncn-m001# cray cfs components list
            ```

            Prevent the configuration from running:

            ```bash
            ncn-m001# cray cfs components update XNAME --desired-state-commit
            ```

            This needs to be done for each component. It is enough to prevent configuration from running, and it does not revert to the previous desired state. The previous desired state has already been overwritten at this point, so if the user is trying to completely revert, they will either need to know and apply the previous desired state manually, or return BOS with the previous template using the configure operation \(which may also trigger a configure operation\).

        2.  Restart the batcher.

            This will purge any information that CFS cached in relation to the BOA job that it was intending to act upon.

            To get the cfs-batcher pod ID:

            ```bash
            ncn-m001# kubectl -n services get pods|grep cray-cfs-batcher
            ```

            Example output:

            ```
            cray-cfs-batcher-644599c6cc-rwl8f           2/2     Running             0          6d17h
            ```

            To restart the pod, scale the replicas to 0 to stop it, and back up to 1 to restart it:

            ```bash
            ncn-m001# kubectl -n services scale CFS-BATCHER_POD_ID --replicas=0
            ncn-m001# kubectl -n services scale CFS-BATCHER_POD_ID --replicas=1
            ```

        3.  Find the existing session that needs to be deleted.

            ```bash
            ncn-m001# cray cfs sessions list
            ```

        4.  Delete the sessions.

            This step must be done after restarting cfs-batcher. If the cached information is not purged from Batcher first, then Batcher may start additional CFS sessions in response to them being killed. The Batcher agent would fight against the user if it is not restarted.

            Unfortunately, it is hard to link a specific BOA session to a CFS session. At this time, they are identified by comparing the CFS timestamps with those of the BOA job, and associating them based on proximity. Additionally, examine the components in the CFS job to see that they match the components in the BOA job.

            ```bash
            ncn-m001# cray cfs sessions delete CFS_SESSION_NAME
            ```

6.  Delete the BOA job.

    The BOA job is not deleted right away because it is needed to find the ConfigMap name.

    ```bash
    ncn-m001# kubectl -n services delete job BOA_JOB_NAME
    ```

