# IMS Image Customization Job Status Stuck at `waiting_on_user`

## Issue description

An IMS image customization job on a remote node can get stuck in the `waiting_on_user` state indefinitely.
This can occur during `image customization` if any of the following things happen:

- The remote node reboots or crashes.
- The IMS job container on the remote build node is killed or stopped.

## Error identification

A symptom of this problem is a failure when attempting to SSH into the `sshd` container of the IMS image
customization job. Use the following procedure to detect the issue.

1. (`ncn-mw#`) Get the details of the image customization job.

   > In the following command, substitute the actual IMS job ID being checked.

   ```bash
   cray ims jobs describe <IMS_JOB_ID> --format json
   ```

  Example output:
  
  ```json
  {
  "arch": "x86_64",
  "artifact_id": "458478da-79bc-49cd-ba33-8c189f7b45e5",
  "build_env_size": 60,
  "created": "2025-08-06T17:23:35.404817",
  "enable_debug": false,
  "id": "10b93eb5-2926-4521-8cd8-bcb9ab92f989",
  "image_root_archive_name": "uan-uss-1.4.0-113-csm.x86_64-sma-1.11.7",
  "initrd_file_name": "initrd",
  "job_mem_size": 8,
  "job_type": "customize",
  "kernel_file_name": "vmlinuz",
  "kernel_parameters_file_name": "kernel-parameters",
  "kubernetes_configmap": "cray-ims-10b93eb5-2926-4521-8cd8-bcb9ab92f989-configmap",
  "kubernetes_job": "cray-ims-10b93eb5-2926-4521-8cd8-bcb9ab92f989-customize",
  "kubernetes_namespace": "ims",
  "kubernetes_pvc": "cray-ims-10b93eb5-2926-4521-8cd8-bcb9ab92f989-job-claim",
  "kubernetes_secret": "cray-ims-10b93eb5-2926-4521-8cd8-bcb9ab92f989-signing-keys",
  "kubernetes_service": "cray-ims-10b93eb5-2926-4521-8cd8-bcb9ab92f989-service",
  "public_key_id": "7d560617-91e1-4075-b8ab-891a3285b783",
  "remote_build_node": "x3000c0s33b1n0",
  "require_dkms": true,
  "resultant_image_id": null,
  "ssh_containers": [
    {
      "connection_info": {
        "cluster.local": {
          "host": "cray-ims-10b93eb5-2926-4521-8cd8-bcb9ab92f989-service.ims.svc.cluster.local",
          "port": 22
        },
        "customer_access": {
          "host": "10b93eb5-2926-4521-8cd8-bcb9ab92f989.ims.cmn.fanta.hpc.amslabs.hpecorp.net",
          "port": 22
        }
      },
      "jail": false,
      "name": "sat-0fda73ef-4ab0-46d2-9e36-9aad6406bb50",
      "status": "pending"
    }
  ],
  "status": "waiting_on_user"
  }
  ```

1. Confirm that the job details fit the symptoms of this issue.

   - The job `status` field is `waiting_on_user`.
   - The `remote_build_node` field is set, indicating the job is running on a remote build node.

   If either of these is not the case, then the procedure documented here is not applicable.

1. (`ncn-mw#`) Attempt to SSH into the `sshd` container of the job.

   > - Ensure that the user running this command has the SSH private key that
   >   is associated with the IMS SSH public key in the `public_key_id` field of the job details.
   > - Perform the following substitutions in the command:
   >     - Replace `<IMS_SSH_HOST>` with the value of the
   >       `ssh_containers[0].connection_info.customer_access.host` field in the job details.
   >     - Replace `<IMS_SSH_PORT>` with the value of the
   >       `ssh_containers[0].connection_info.customer_access.port` field in the job details.

   ```bash
   ssh -p <IMS_SSH_PORT> root@<IMS_SSH_HOST>
   ```
  
1. Confirm that the SSH attempt resulted in a connection failure.
   If that is not the case, then the procedure documented here is not applicable.

1. (`ncn-mw#`) Connect to the remote node where the job is running.

   > - The name of the remote build node can be found in the `remote_build_node` field of the job details.
   > - If the remote node is not reachable, then skip ahead to the [Resolution](#resolution) section.

   ```bash
   ssh <remote_build_node xname>
   ```

1. (`cn#`) Check if IMS job container exists on the remote node.

   > In the following command, replace `<IMS_JOB_ID>` with the actual IMS job ID.

   ```bash
   podman ps | grep <IMS_JOB_ID>
   ```

1. If the IMS job container either does not exist or is in an `exited` state, then proceed to [Resolution](#resolution),

   If that is not the case, then the procedure documented here is not applicable.

## Resolution

(`ncn-mw#`) In order to resolve the problem, delete the IMS job.

> In the following command, replace `<IMS_JOB_ID>` with the actual IMS job ID.

 ```bash
cray ims jobs delete <IMS_JOB_ID>
```

After the job is deleted, a new image customization job can be created. See
[Customize an Image Root Using IMS](../../operations/image_management/Customize_an_Image_Root_Using_IMS.md).
