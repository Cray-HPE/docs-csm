# IMS Image Customization Job Status Stuck at "waiting_on_user"

## Issue description

IMS image customization job on remote node can get stuck in the "waiting_on_user" state indefinitely.
This can occur if during `image customization` remote node gets rebooted, crashes or IMS JOB container is killed/stopped.

## Error identification

The issue can be identified by noticing the failure to ssh into `sshd` container of IMS image customization job. here are
the steps to identify the issue:

1. (`ncn-mw#`) Get the details of the image customization job:

   ```bash
   IMS_JOB_ID=<Job ID>
   cray ims jobs describe $IMS_JOB_ID --format json
   ```

  Job details will show the job status as "waiting_on_user". here is sample output:
  
  ```text
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
      "status": "pending"[README.md](../README.md)
    }
  ],
  "status": "waiting_on_user"
  }
  ```

1. (`ncn-mw#`) Attempt to ssh into the `sshd` container of the job and notice the connection failure:

    ```bash
   IMS_SSH_HOST=<ssh_containers[0].connection_info.customer_access.host from above output>
   IMS_SSH_PORT=<ssh_containers[0].connection_info.customer_access.port from above output>
   ssh -p $IMS_SSH_PORT root@$IMS_SSH_HOST
   ```

1. (`ncn-mw#`) connect to the remote node where the job is running:

   ```bash
   ssh <remote_build_node xname>
   ```

if the remote node is not reachable then skip the next step and go to the [resolution](#resolution) section.

1. (`ncn-mw#`) Check if `ims` job container exists on the remote node:

   ```bash
   IMS_JOB_ID=<Job ID>
   podman ps | grep $IMS_JOB_ID
   ```

   You will notice that either `ims` job container does not exist or is in `exited` state.

## Resolution

In this case the `ims` job needs to be removed. Follow these steps:

1. (`ncn-mw#`) Remove the `ims` image customization job using `cray` CLI:

   ```bash
   IMS_JOB_ID=<Job ID>
   cray ims jobs delete $IMS_JOB_ID
   ```

once the job is deleted a new image customization job can be created using following
[IMS Image Customization](../../operations/image_management/Customize_an_Image_Root_Using_IMS.md)
