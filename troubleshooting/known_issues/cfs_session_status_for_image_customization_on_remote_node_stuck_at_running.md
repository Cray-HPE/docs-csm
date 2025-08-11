# CFS Session for Image Customization on Remote Node Status Stuck at `running`

## Issue description

A CFS session for image customization job on a remote node can get stuck in the `running` state indefinitely.
This can occur during image customization if any of the following things happen:

- The remote node reboots or crashes.
- The IMS job container on the remote build node is killed or stopped.

## Error identification

A symptom of this problem is the following error repeated continuously in the `inventory` container log in the CFS session pod.

```text
2025-08-08 15:44:52,299 - INFO    - cray.cfs.inventory.image - Error while waiting for SSH to be available: Error reading SSH protocol banner[Errno 104] Connection reset by peer. Retrying..
```

Follow these steps to view the `inventory` container log.

1. (`ncn-mw#`) Get the details of the CFS session.

    > In the following command, replace `<CFS_SESSION_NAME>` with the actual CFS session name being checked.

    ```bash
    cray cfs sessions describe $CFS_SESSION_NAME --format json | jq '.status.session.job'
    ```

    Example output:

    ```text
    "cfs-4b8a485f-7536-48ca-9fc9-e11a9a555fcd"
    ```

1. (`ncn-mw#`) Get the name of the CFS pod running in the `services` namespace.

    > - Perform the following substitutions in the command:
    >     - Replace `<CFS_SESSIONS_JOB_ID>` with the value of the
    >       previous command.

    ```bash
    kubectl get pods -n services -o name|grep <CFS_SESSIONS_JOB_ID>
    ```

    Example output:

    ```text
    pod/cfs-f7e04dbf-542b-4f22-8c66-537744684db8-4l6wv
    ```

1. (`ncn-mw#`) Get the log of the CFS session pod's `inventory` container.

    > - Perform the following substitutions in the command:
    >     - Replace `<CFS_POD>` with the output of the command in the previous step.

    ```bash
    kubectl logs -f <CFS_POD> -n services -c inventory
    ```

    Example output:

    ```text
    2025-08-08 15:50:06,023 - INFO    - cray.cfs.inventory - Starting CFS Inventory version=1.31.0, namespace=services
    2025-08-08 15:50:06,108 - INFO    - cray.cfs.inventory - Inventory target=image for cfsession=build-ims-remote-image-x86-cmsdev
    2025-08-08 15:50:06,263 - INFO    - cray.cfs.inventory.image - Uploading public key to IMS for SSH container access.
    2025-08-08 15:50:06,417 - INFO    - cray.cfs.inventory.image - Requesting access to IMS image='15bacab2-053b-41d6-a7e6-8561cec1bade'
    2025-08-08 15:50:07,796 - INFO    - cray.cfs.inventory.image - IMS status=creating for IMS image='15bacab2-053b-41d6-a7e6-8561cec1bade' job='15b7479d-e5f2-405f-971c-405c1fac1152'. Elapsed time=0s
    2025-08-08 15:50:12,810 - INFO    - cray.cfs.inventory.image - IMS status=creating for IMS image='15bacab2-053b-41d6-a7e6-8561cec1bade' job='15b7479d-e5f2-405f-971c-405c1fac1152'. Elapsed time=5s
    ...
    2025-08-08 15:54:28,704 - INFO    - cray.cfs.inventory.image - IMS status=fetching_image for IMS image='15bacab2-053b-41d6-a7e6-8561cec1bade' job='15b7479d-e5f2-405f-971c-405c1fac1152'. Elapsed time=260s
    2025-08-08 15:54:33,722 - INFO    - cray.cfs.inventory.image - IMS status=fetching_image for IMS image='15bacab2-053b-41d6-a7e6-8561cec1bade' job='15b7479d-e5f2-405f-971c-405c1fac1152'. Elapsed time=265s
    2025-08-08 15:54:38,739 - INFO    - cray.cfs.inventory.image - Checking ssh availability
    2025-08-08 15:54:38,739 - INFO    - cray.cfs.inventory.image - Waiting for SSH to be available at cray-ims-15b7479d-e5f2-405f-971c-405c1fac1152-service.ims.svc.cluster.local:22. Elapsed time=0s
    2025-08-08 15:54:40,753 - INFO    - cray.cfs.inventory.image - Error while waiting for SSH to be available: Error reading SSH protocol banner[Errno 104] Connection reset by peer. Retrying..
    ```

    In the above output following line contains the details about IMS image ID and IMS job ID needed for error identification in the next step.

    ```text
    2025-08-08 15:54:28,704 - INFO    - cray.cfs.inventory.image - IMS status=fetching_image for IMS image='15bacab2-053b-41d6-a7e6-8561cec1bade' job='15b7479d-e5f2-405f-971c-405c1fac1152'. Elapsed time=260s
    ```

1. Determine whether or not this known issue is the cause of the problem.

    Follow the [Error identification](ims_image_customization_job_status_stuck_at_waiting_on_user.md#error-identification) procedure and
    verify that the symptom matches, but do not follow the resolution steps in the linked page.

1. If the IMS job container on the remote node either does not exist or is in an `exited` state, then proceed to [Resolution](#resolution).

    If that is not the case, then the procedure documented here is not applicable.

## Resolution

(`ncn-mw#`) In order to resolve the problem, delete the CFS session.

> In the following command, replace `<CFS_SESSION_NAME>` with the actual CFS session name.

```bash
cray cfs sessions delete <CFS_SESSION_NAME>
```

After the CFS session is deleted, a new CFS session for image customization can be created. See
[Create CFS Session For Image Customization](../../operations/configuration_management/Create_an_Image_Customization_CFS_Session.md).
