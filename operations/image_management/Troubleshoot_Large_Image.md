# Troubleshoot Issues with Large Images

The default configuration values that IMS has are based on the assumption of a resulting
image of 15 Gb or smaller. If the images being worked with are larger, then there are a couple
of different failures that can happen, but these failures can be resolved by changes to the
IMS configuration settings.

These settings require a balancing act based on the size of the images being produced and
the size of the system and what resources are available. If these settings are too large,
the IMS jobs will consume more resources than required and it will be more difficult to
schedule jobs on the Kubernetes workers because of resource limitations. If they are too small,
then the IMS jobs will fail because the job lacks the resources required for a larger image.

## Prerequisites

This page requires interactive access to the image being worked with.

## Modifying the IMS configuration based on image size

(`ncn-mw#`) There are two settings in the IMS configuration map that need to be modified for larger
images. Both are contained in the same Kubernetes config map. To open this for editing:

```bash
kubectl -n services edit cm ims-config
```

After the commented header, expect the configuration file to look something like the following:

```yaml
apiVersion: v1
data:
  API_GATEWAY_HOSTNAME: istio-ingressgateway.istio-system.svc.cluster.local
  CA_CERT: /mnt/ca-vol/certificate_authority.crt
  DEFAULT_IMS_IMAGE_SIZE: "15"
  DEFAULT_IMS_JOB_MEM_SIZE: "8"
  DEFAULT_IMS_JOB_NAMESPACE: ims
  GUNICORN_WORKER_TIMEOUT: "3600"
  JOB_AARCH64_RUNTIME: kata-qemu
  JOB_CUSTOMER_ACCESS_NETWORK_ACCESS_POOL: customer-management
  JOB_CUSTOMER_ACCESS_NETWORK_DOMAIN: my_system.hpc.amslabs.hpecorp.net
  JOB_CUSTOMER_ACCESS_SUBNET_NAME: cmn
  JOB_ENABLE_DKMS: "false"
  JOB_KATA_RUNTIME: kata-qemu
  S3_BOOT_IMAGES_BUCKET: boot-images
  S3_CONNECT_TIMEOUT: "60"
  S3_IMS_BUCKET: ims
  S3_READ_TIMEOUT: "60"
```

The two settings to work with here are:

### `DEFAULT_IMS_IMAGE_SIZE`

This setting is the expected image size in Gb and will increase or decrease the size of the
storage allocated for the image to be created or customized. It consumes space in ceph that
is not released until the job is deleted.

### `DEFAULT_IMS_JOB_MEM_SIZE`

This setting is size in Gb of the active memory the running IMS job will require. The larger
this number, the more memory is reserved on a Kubernetes worker node for the job to consume.
If this is too large, Kubernetes will have difficulty finding a worker available with enough
free memory to schedule the job. If it is too small, the pod will `OOMKill` when it uses all the
memory it is allowed to consume.

NOTE: Modifying either of these values will require a restart of the `cray-ims` service to pick up
the changes.

### Restarting the IMS service

1. (`ncn-mw#`) When editing the configuration map is complete, find the name of the current `cray-ims` service pod.

    ```bash
    kubectl -n services get pods | grep cray-ims
    ```

    Expected output:

    ```text
    cray-ims-64bf4d5f49-xd4rh      2/2     Running   0  20h
    ```

1. (`ncn-mw#`) Delete the pod.

    ```bash
    kubectl -n services delete pod cray-ims-64bf4d5f49-xd4rh
    ```

When the new pod is up and running, it will use the new settings.

## Error: "FATAL ERROR: Failed to write to output filesystem"

If the produced image is significantly larger than expected, there will not be enough
storage space allocated for the job, and the creation of the `squashfs` file will fail.

The CFS log will contain a failure notice something like:

```text
2023-12-01 17:47:19,322 - INFO    - cray.cfs.teardown - Waiting for resultant image of
job=ac6f6ba0-f399-480b-b49f-396a192c9390; IMS status=error; elapsed time=734s
2023-12-01 17:47:19,325 - ERROR   - cray.cfs.teardown - Failed to teardown image customization of
image=00ce7971-8b42-4012-8895-42ae6fc44c0cin job=ac6f6ba0-f399-480b-b49f-396a192c9390. Error was
RuntimeError('IMS reported an error when packaging artifacts for job=%s.Consult the IMS logs to
determine the cause of failure.IMS response: %s', 'ac6f6ba0-f399-480b-b49f-396a192c9390',
{'arch': 'x86_64', 'artifact_id': '00ce7971-8b42-4012-8895-42ae6fc44c0c', 'build_env_size': 15,
'created': '2023-12-01T16:01:24.298632+00:00', 'enable_debug': False, 'id': 'ac6f6ba0-f399-480b-b49f-396a192c9390',
'image_root_archive_name': 'uan-shs-uss-1.0.0-45-csm-1.5.x86_64-231106_cfs_gpu-2296-uan', 'initrd_file_name': 'initrd',
'job_mem_size': 8, 'job_type': 'customize', 'kernel_file_name': 'vmlinuz', 'kernel_parameters_file_name':
'kernel-parameters', 'kubernetes_configmap': 'cray-ims-ac6f6ba0-f399-480b-b49f-396a192c9390-configmap',
'kubernetes_job': 'cray-ims-ac6f6ba0-f399-480b-b49f-396a192c9390-customize', 'kubernetes_namespace': 'ims',
'kubernetes_pvc': 'cray-ims-ac6f6ba0-f399-480b-b49f-396a192c9390-job-claim', 'kubernetes_service':
'cray-ims-ac6f6ba0-f399-480b-b49f-396a192c9390-service', 'public_key_id': '2ab02101-3b65-413a-b84a-ebf4735776d8',
'require_dkms': True, 'resultant_image_id': None, 'ssh_containers': [{'connection_info': {'cluster.local':
{'host':'cray-ims-ac6f6ba0-f399-480b-b49f-396a192c9390-service.ims.svc.cluster.local', 'port': 22},
'customer_access': {'host': 'ac6f6ba0-f399-480b-b49f-396a192c9390.ims.cmn.lemondrop.hpc.amslabs.hpecorp.net',
'port': 22}}, 'jail': True, 'name': 'gpu-2296-uan', 'status': 'pending'}], 'status': 'error'})
```

The IMS job log for the `buildenv-sidecar` container will have the following:

```text
+ time mksquashfs /mnt/image/image-root /mnt/image/uan-shs-uss-1.0.0-45-csm-1.5.x86_64-231106_cfs_gpu-2296-uan.sqsh
Parallel mksquashfs: Using 57 processors
Creating 4.0 filesystem on /mnt/image/uan-shs-uss-1.0.0-45-csm-1.5.x86_64-231106_cfs_gpu-2296-uan.sqsh, block size 131072.
Write failed because No space left on device
FATAL ERROR: Failed to write to output filesystem
[======================================================-   ] 588500/619268  95%
Command exited with non-zero status 1
real    12m 6.51s
user    4h 4m 33s
sys     9m 50.62s
Error: Creating squashfs of image root return_code = 1
```

The solution is to increase the size of `DEFAULT_IMS_IMAGE_SIZE`.

## Error: `OOMKilled`

1. (`ncn-mw#`) Check the IMS job logs for a 'Killed' message during the run, similar to the following:

    ```bash
    kubectl logs -n ims -l job-name=cray-ims-9b2fd379-31c7-4916-a397-4fe956f744b4-create -c build-image
    ```

    Example output:

    ```text
    [ INFO    ]: 23:46:05 | Creating XZ compressed tar archive
    [ ERROR   ]: 23:46:52 | KiwiCommandError: bash: stderr: bash: line 1: 49862 Broken pipe             tar -C /mnt/image/build/image-root --xattrs --xattrs-include=* -c --to-stdout bin boot dev etc home lib lib64 mnt opt proc root run sbin selinux srv sys tmp usr var
        49863 Killed                  | xz -f --threads=0 > /mnt/image/Cray-shasta-compute-sles15sp5.x86_64-unknown-20231024155019-gunknown.tar.xz
    , stdout: (no output on stdout)
    ERROR: Kiwi reported a build error.
    + rc=1
    + '[' 1 -ne 0 ']'
    + echo 'ERROR: Kiwi reported a build error.'
    + touch /mnt/image/build_failed
    + exit 0
    ```

1. (`ncn-mw#`) Check the status of the `build-image` or `sshd` container of the pod:

    ```bash
    kubectl describe pod -n ims cray-ims-9b2fd379-31c7-4916-a397-4fe956f744b4-create-8h47r
    ```

    Example output:

    ```text
    Name:         cray-ims-9b2fd379-31c7-4916-a397-4fe956f744b4-create-8h47r
    Namespace:    ims
    Priority:     0
    Node:         ncn-w004/10.252.1.13
    Start Time:   Tue, 14 Nov 2023 23:31:08 +0000
    ...
    Init Containers:
    build-image:
        Container ID:   containerd://f57bd79b7a4b26fa22edf57001bed6e4d148df51590680b19172085e3064909d
        Image:          artifactory.algol60.net/csm-docker/stable/cray-ims-kiwi-ng-opensuse-x86_64-builder:1.6.0
        Image ID:       artifactory.algol60.net/csm-docker/stable/cray-ims-kiwi-ng-opensuse-x86_64-builder@sha256:98b9417313a29f5c842769c1f679894bcf9d5d6927eef2a93f74636d4cb1f906
        Port:           <none>
        Host Port:      <none>
        State:          Terminated
        Reason:       OOMKilled
        Exit Code:    0
        Started:      Tue, 14 Nov 2023 23:31:39 +0000
        Finished:     Tue, 14 Nov 2023 23:46:52 +0000
    ```

This shows the pod was terminated for using too much memory on the Kubernetes worker.

The solution is to increase the size of `DEFAULT_IMS_JOB_MEM_SIZE`.

## Error: IMS job pod stuck in `Pending`

If there are not enough free resources on the Kubernetes system, then the IMS job pods can get stuck in
a `Pending` state while waiting for a worker node to have sufficient free resources to start the job.

1. (`ncn-mw#`) Check for jobs stuck in a `Pending` state:

    ```bash
    kubectl get pod -A | grep ims | grep Pending
    ```

    Example output:

    ```text
    ims                 cray-ims-3c478753-02a2-47e0-86cc-c3801a312c1d-customize-kd2rq     0/2     Pending      0          16h
    ims                 cray-ims-49422153-738e-45e8-8c73-4a0132b6da21-customize-hd77r     0/2     Pending      0          47m
    ims                 cray-ims-53ab24c2-c318-487a-9f13-9e90431430c4-customize-llkzw     0/2     Pending      0          16h
    ims                 cray-ims-92c76eeb-915e-41ac-b106-d029d60a55bf-customize-wb2rz     0/2     Pending      0          21m
    ims                 cray-ims-9a2603fd-cf7e-4cf6-bea9-5eb6f6d8e8b3-customize-rf8st     0/2     Pending      0          29m
    ims                 cray-ims-e4ea92bc-5d1c-4b94-83e8-31520e37cf5b-customize-mwxwp     0/2     Pending      0          16h
    ```

1. (`ncn-mw#`) Examining one of the `Pending` jobs should describe what the scarce resource is:

    ```bash
    kubectl -n ims describe pod cray-ims-49422153-738e-45e8-8c73-4a0132b6da21-customize-hd77r
    ```

    Example output:

    ```text
    Name:           cray-ims-49422153-738e-45e8-8c73-4a0132b6da21-customize-hd77r
    Namespace:      ims
    Priority:       0
    ...
    Events:
      Type     Reason            Age   From                  Message
      ----     ------            ----  ----                  -------
      Warning  FailedScheduling  18m   default-scheduler     0/7 nodes are available: 3 node(s) had taint {node-role.kubernetes.io/master: }, that the pod didn't tolerate, 4 Insufficient memory.
      Warning  FailedScheduling  18m   default-scheduler     0/7 nodes are available: 3 node(s) had taint {node-role.kubernetes.io/master: }, that the pod didn't tolerate, 4 Insufficient memory.
      Warning  PolicyViolation   18m   admission-controller  Rule(s) 'privileged-containers' of policy 'disallow-privileged-containers' failed to apply on the resource
      Warning  PolicyViolation   18m   admission-controller  Rule(s) 'adding-capabilities' of policy 'disallow-capabilities' failed to apply on the resource
    ```

This is indicating all four of the worker nodes do not have sufficient free memory to start these jobs.

There are a couple of ways to resolve this and free up resources for new jobs.

1. (`ncn-mw#`) Clear out old running jobs.

    Every IMS job that is still in a `Running` state is consuming resources on the system. Sometimes
    old jobs are not being used any more, but may be left in a `Running` state.

    Check for `Running` IMS jobs:

    ```bash
    kubectl get pod -A | grep ims | grep Running
    ```

    Example output:

    ```text
    ims                 cray-ims-067c3358-afaa-470f-8812-f050208a93fb-customize-47m9w     2/2     Running      0          4d17h
    ims                 cray-ims-4fc9d843-ad20-46c5-aabb-df2454a2d2d6-customize-g52fq     2/2     Running      0          17h
    ims                 cray-ims-806a85b1-425d-46dd-badd-7d035b4fb432-customize-hl4f6     2/2     Running      0          17h
    ims                 cray-ims-82c2bac9-6a57-404e-b50d-2a1f3d51afb5-customize-bcc8h     2/2     Running      0          42h
    ims                 cray-ims-90d1136f-3531-4294-86c9-a1507649747b-customize-wjxpg     2/2     Running      0          9d
    ims                 cray-ims-aee7443f-83e6-4e66-bb37-a78cf0cf59b5-customize-4lqt4     2/2     Running      0          42h
    ims                 cray-ims-ba44f475-f739-49a5-b996-9077e764f717-customize-6b9lh     2/2     Running      0          5d11h
    ims                 cray-ims-bbb31a07-8642-4b82-bb01-2ab6f3e4e08e-customize-5g6gc     2/2     Running      0          8d
    ims                 cray-ims-ca5ef71e-1df7-4f26-adc7-d0a306cf8700-customize-bxlv9     2/2     Running      0          8d
    ims                 cray-ims-d1af1713-238b-4d94-9f9c-fdb95bce96ec-customize-pb6xm     2/2     Running      0          17h
    ims                 cray-ims-ebf91c30-0a16-4099-bf0e-2d711ee8ceb7-customize-czrjv     2/2     Running      0          25h
    ims                 cray-ims-fdd02cc6-dc44-4748-a12c-5cfab9699c25-customize-9zlmr     2/2     Running      0          17h
    ```

    Each of these running IMS jobs is consuming resources and will not release the resources until they are complete
    or deleted. An attempt should be made to determine how these jobs were created and why they were not cleaned
    up. When enough of the existing jobs are finished, the `Pending` jobs should automatically transition to `Running`
    but be aware that if they are running through CFS or SAT there may be automatic timeouts that will no longer have
    sufficient time to complete the intended tasks if they were stuck in `Pending` for too long.

1. Reduce the resource requirements for the jobs.

    If the images being produced are not too large, the configuration maps may be altered to reduce the resource
    requirements. Be aware that if the resources are reduced too far, the jobs will fail with the errors described above.

    In this case reduce the value of `DEFAULT_IMS_JOB_MEM_SIZE`
