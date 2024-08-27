# Troubleshoot Remote Build Node

Remote builds work by creating and running containerized jobs via Podman on a remote node. There
are times that problems crop up with running these remote jobs.

* [Prerequisites](#prerequisites)
* [Jobs fail to launch on remote nodes](#jobs-fail-to-launch-on-remote-nodes)
* [Clean up orphaned jobs](#clean-up-orphaned-jobs)
* [Jobs fail due to lack of resources on the remote node](#jobs-fail-due-to-lack-of-resources-on-the-remote-node)

## Prerequisites

* Administrative access to a master or worker node on the K8S cluster
* Administrative access to the remote build node

## Jobs fail to launch on remote nodes

1. Verify that the remote node is defined in IMS.

    For more information, see [Adding and removing remote build nodes to IMS](Configure_a_Remote_Build_Node.md#adding-and-removing-remote-build-nodes-to-ims).

1. Verify that SSH keys are installed on the remote node.

    For more information, see [Use an existing compute node](Configure_a_Remote_Build_Node.md#use-an-existing-compute-node#).

1. Verify that Podman is installed on the remote node.

    For more information, see [Use an existing compute node](Configure_a_Remote_Build_Node.md#use-an-existing-compute-node#).

1. Check the architecture of of the job and remote node.

    1. (`ncn-mw#`) Check job architecture.

        ```bash
        cray ims jobs describe JOB_ID --format json
        ```

        The returned output will include a field for `arch`:

        ```text
        {
            "arch": "aarch64",
        ...
        }
        ```

    1. (`ncn-mw#`) Check remote build node architecture.

        ```bash
        ssh REMOTE_NODE_XNAME lscpu | grep Architecture
        ```

        The expected output will list the architecture of the remote node:

        ```text
        Architecture:                       aarch64
        ```

    Verify that the architecture of the remote node matches the job expected to run on it.

1. (`ncn-mw#`) Check the IMS service logs for creation of the job.

    ```bash
    cray -n services logs cray-ims-<id of current pod> | grep -A 15 POST
    ```

    When the job is created there is information in the log about matching remote build nodes - look
    for the information verifying the image and remote node information:

    ```text
    [19/Apr/2024:19:03:42 +0000] "POST /v3/jobs HTTP/1.1" 201 1246 "-" "python-requests/2.31.0"
    [2024-04-19 19:03:45,306] INFO in jobs: 2fbf42ca ++ jobs.v3.POST
    [2024-04-19 19:03:45,306] INFO in jobs: 2fbf42ca json_data = {'job_type': 'customize', 'image_root_archive_name': 'dlaine-arm-cust-test', 'initrd_file_name': 'initrd', 'kernel_parameters_file_name': 'kernel-parameters', 'artifact_id': 'f65534d9-c469-4bab-8bb3-f66c3cf98042', 'public_key_id': '88eec811-b0dc-4741-a6c6-ef9fa77c4ace', 'require_dkms': True, 'ssh_containers': [{'jail': True}]}
    [2024-04-19 19:03:45,307] INFO in jobs: Retrieving image info
    [2024-04-19 19:03:45,308] INFO in helper: ++ _validate_s3_artifact {'path': 's3://boot-images/f65534d9-c469-4bab-8bb3-f66c3cf98042/manifest.json', 'type': 's3', 'etag': 'cc330f5babf9a7ba1638aadafa745f76'}.
    [2024-04-19 19:03:45,320] INFO in helper: ++ _read_s3_manifest_json {'path': 's3://boot-images/f65534d9-c469-4bab-8bb3-f66c3cf98042/manifest.json', 'type': 's3', 'etag': 'cc330f5babf9a7ba1638aadafa745f76'}.
    [2024-04-19 19:03:45,332] INFO in helper: ++ _validate_s3_artifact {'etag': 'e801003a78039843210cc02f8be1248e-192', 'path': 's3://boot-images/f65534d9-c469-4bab-8bb3-f66c3cf98042/rootfs', 'type': 's3'}.
    [2024-04-19 19:03:45,342] INFO in helper: ++ _get_s3_download_url {'etag': 'e801003a78039843210cc02f8be1248e-192', 'path': 's3://boot-images/f65534d9-c469-4bab-8bb3-f66c3cf98042/rootfs', 'type': 's3'}.
    [2024-04-19 19:03:45,343] INFO in jobs: ARTIFACT_RECORD: <V2ImageRecord(id=UUID('f65534d9-c469-4bab-8bb3-f66c3cf98042'))>
    [2024-04-19 19:03:45,343] INFO in jobs: architecture: aarch64
    [2024-04-19 19:03:45,344] INFO in jobs: kernel file name: Image
    [2024-04-19 19:03:45,344] INFO in jobs:  NOTE: aarch64 architecture requires dkms
    [2024-04-19 19:03:45,344] INFO in jobs: INFORMATION:: new_job: <v2JobRecord(id=UUID('b3eb4c73-f8da-47cc-9e1e-9874d6ba07ef'))>
    [2024-04-19 19:03:45,344] INFO in jobs: Checking for remote build node for job
    [2024-04-19 19:03:45,890] INFO in jobs: Matching remote node: x9000c1s3b1n0, current jobs on node: 1
    ```

    Examine the information about the architecture of the artifact being used and the remote build nodes found.

## Clean up orphaned jobs

1. (`ncn-mw`) List the current IMS jobs to get the valid job IDs.

    ```bash
    cray ims jobs list --format json | jq '.[] | .id'
    ```

    Expected output will be list of the IMS job IDs:

    ```text
    "b7ec44f1-f5fe-4830-a69b-35d02ab87741"
    "a5a62860-7d48-488d-b09a-56ba9cddd2f3"
    "262af634-8cb7-4f8d-ab36-210ab6cc4409"
    "92319466-672a-4886-8bf6-3300096c74f8"
    ```

1. (`cn#`) Check for the presence of leftover jobs on the remote build node.

    ```bash
    podman ps -a
    ```

    Expected output is all the Podman containers currently running and stopped:

    ```text
    CONTAINER ID  IMAGE                                                            COMMAND     CREATED            STATUS            PORTS                 NAMES
    24438ea88859  localhost/ims-remote-020cb1fc-fbc4-4256-9a28-43b4527fc573:1.0.0              About an hour ago  Up About an hour           0.0.0.0:2022->22/tcp  ims-020cb1fc-fbc4-4256-9a28-43b4527fc573
    b4549f9b3608  localhost/ims-remote-b3eb4c73-f8da-47cc-9e1e-9874d6ba07ef:1.0.0              About an hour ago  Exited (1) 46 seconds ago  0.0.0.0:2023->22/tcp  ims-b3eb4c73-f8da-47cc-9e1e-9874d6ba07ef
    ca674a5de7cd  localhost/ims-remote-262af634-8cb7-4f8d-ab36-210ab6cc4409:1.0.0              About an hour ago  Up About an hour           0.0.0.0:2024->22/tcp  ims-262af634-8cb7-4f8d-ab36-210ab6cc4409
    40149c58272e  localhost/ims-remote-af620dcd-354f-4742-8d35-cc8fd7dea5a4:1.0.0              About an hour ago  Exited (1) 5 seconds ago   0.0.0.0:2025->22/tcp  ims-af620dcd-354f-4742-8d35-cc8fd7dea5a4
    3d7efd2de031  localhost/ims-remote-92319466-672a-4886-8bf6-3300096c74f8:1.0.0              52 minutes ago     Up 52 minutes              0.0.0.0:2026->22/tcp  ims-92319466-672a-4886-8bf6-3300096c74f8
    ```

    Both the image and the name of the container have the IMS `JOB_ID` incorporated.

    In the normal course of events, the IMS job will stop and remove all Podman jobs on the remote node when the job
    stops. There are times if the IMS job is stopped in an irregular way, the Podman jobs may be stopped already -
    check the `STATUS` field for containers that have already exited.

1. (`cn#`) Stop any orphaned running containers.

    If any containers are still running but are not in the IMS job list, then they will need to be stopped before they
    can be removed.

    ```bash
    podman stop CONTAINER_ID
    ```

    Expected output:

    ```text
    CONTAINER_ID
    ```

1. (`cn#`) Remove any orphaned containers.

    ```bash
    podman rm CONTAINER_ID
    ```

    Expected output:

    ```text
    CONTAINER_ID
    ```

1. (`cn#`) Check for the presence of additional container images on the system.

    ```bash
    podman image ls
    ```

    Expected output:

    ```text
    REPOSITORY                                                 TAG         IMAGE ID      CREATED      SIZE
    localhost/ims-remote-92319466-672a-4886-8bf6-3300096c74f8  1.0.0       78598bede292  2 days ago   2.5 GB
    localhost/ims-remote-262af634-8cb7-4f8d-ab36-210ab6cc4409  1.0.0       031d0edef693  2 days ago   2.5 GB
    localhost/ims-remote-b3eb4c73-f8da-47cc-9e1e-9874d6ba07ef  1.0.0       9deee9848779  2 days ago   2.5 GB
    localhost/ims-remote-af620dcd-354f-4742-8d35-cc8fd7dea5a4  1.0.0       78ca60dcf4ff  2 days ago   2.5 GB
    localhost/ims-remote-020cb1fc-fbc4-4256-9a28-43b4527fc573  1.0.0       fa2fa5bc92a9  2 days ago   2.5 GB
    localhost/ims-remote-66d29313-49c7-468a-8bb3-d5d4f1617f83  1.0.0       5a76f1ed8df6  12 days ago  1.22 GB
    ```

    Note that the IMS job id is part of the image name.

1. (`cn#`) Delete any images not being utilized by a valid running job.

    ```bash
    podman rmi IMAGE_ID
    ```

    Expected output will look something like:

    ```text
    Untagged: localhost/ims-remote-b3eb4c73-f8da-47cc-9e1e-9874d6ba07ef:1.0.0
    Deleted: 9deee9848779897cdda4d568a92edafa40e370ad2a883271ed06e68a61a0b8e7
    ```

1. (`cn#`) Delete any dangling Podman resources.

    To remove any additional resources that were attached to the removed containers and images,
    prune the system:

    ```bash
    podman volume prune -f
    ```

    There is usually no output from this command.

1. (`cn#`) Remove temporary directories.

    Jobs use temporary directories to transfer build artifacts back to Kubernetes. Each job will have
    a directory named `/tmp/ims_IMS_JOB_ID`. Delete any directories belonging to jobs that are no longer present.

    ```bash
    rm -rf /tmp/ims_OLD_IMS_JOB_ID
    ```

## Jobs fail due to lack of resources on the remote node

The most common cause for jobs failing to start on the remote node is a lack of resources on the remote node.
There are a couple of different ways these failures can manifest.

In either of the below cases, the solution is to either reduce the resource demands on the remote node through
running fewer concurrent jobs or jobs with smaller images, or to add storage to the remote node.

For more information, see [Adding storage to a remote build node](Configure_a_Remote_Build_Node.md#adding-storage-to-a-remote-build-node).

### IMS job fails in `init`

This usually happens when there is insufficient space to upload the remote job image to the remote node.

1. (`ncn-mw`) Find the name of the IMS job using the job id.

    ```bash
    kubectl -n ims get pods | grep IMS_JOB_ID
    ```

    Expected output will be something like:

    ```text
    cray-ims-b88d44b6-8e7e-4247-9d58-998485527993-customize-xldkv   0/2     Init:Error   0          48m
    ```

1. (`ncn-mw`) Look at the log of the `prepare` container.

    Using the name of the pod found in a previous step:

    ```bash
    kubectl -n ims logs IMS_JOB_POD_NAME prepare
    ```

    Towards the end of the log look for a problem with insufficient space. The error usually occurs while
    attempting to upload the image to the remote node:

    ```text
    + podman save ims-remote-b88d44b6-8e7e-4247-9d58-998485527993:1.0.0
    + ssh -o StrictHostKeyChecking=no root@x3000c0s19b3n0 podman load
    Getting image source signatures
    Copying blob sha256:b0704db1fd03ffb529ca958a99ef292fed3f658db143c8c58c949943f0869126
    Copying blob sha256:26651719d6f34a6b96dea95e234c34b32c17c542e7179c3f00f919a963b9954e
    Copying blob sha256:c745f2cbe6fae9be464d94b737764ac7b653fed9c0c28ceb8fd21f61ae1dc251
    Copying blob sha256:568b71624086dfb722dda9f4843df978d93543e7ab42276208c2c96c985c3bcc
    Copying blob sha256:b3ab11a3b9960608e028ccaf0fbdd6a191fb39a9624015395435e70432e87179
    Copying blob sha256:f62577694e03b33aa177b0f20a2e572b8eb64409915f4069c17b9c63741ae79c
    Copying blob sha256:0ecfc323c3bd0d5eb79ffe52b3a006881308d9209e710e1b1623c1c159cc1f75
    Copying blob sha256:a4d9aab5a97d75c8a3af8ad96071477ff8aa7fe43896c7e94856f4950ae6c57c
    Copying blob sha256:8fc5f1e13cc239ade126a6077ae9aff7b0b2f964b287270b6b79cd3a668c3ddd
    Copying blob sha256:00cff7cee47c58505025ee7f13ee651bfaca6f5dab5cf4bf67df958a79043658
    Copying blob sha256:c37df6418ae377781ef5e00b7c35eaba63d05aad10bda219d9834b9ee08ab80a
    Copying blob sha256:c23c4211329265b6b9fee5cebfed0f0fb72a69a4c3f83258cbff75f2362ce454
    Copying blob sha256:fa39935319170e70e30fd942f62fffe2b9cdab3b98ee3a6bdbdaaed0a4e2cc0d
    Error: payload does not match any of the supported image formats:
    * oci: initializing source oci:/var/tmp/podman2767250042:: open /var/tmp/podman2767250042/index.json: not a directory
    * oci-archive: loading index: open /var/tmp/oci989385672/index.json: no such file or directory
    * docker-archive: writing blob: storing blob to file "/var/tmp/storage2387688446/4": write /var/tmp/storage2387688446/4: no space left on device
    * dir: open /var/tmp/podman2767250042/manifest.json: not a directory
    + RC=125
    + [[ 125 -ne 0 ]]
    + echo 'Copying image to remote node failed - check available space on the remote node'
    + exit 1
    Copying image to remote node failed - check available space on the remote node
    ```

### Remote container fails

As the image is being built or customized on the remote node, it will consume space. At times it may run
out of space during one of the image operations. The best way to debug this case is to look through the
logs of the recipe build in the case of a create job, or the Ansible logs in a customize job.

It is also possible for it to run out of space in the process of preparing the image results for transfer
back to the IMS job pod. In this case it may be required to look at the container logs on the remote
node. These are removed at the end of the job, so it may be required to follow the log as the pod is
running rather than look at the results after.

1. (`cn`) Find the container for the IMS job.

    ```bash
    podman ps -a | grep IMS_JOB_ID
    ```

    There should be one container with the IMS job id embedded into the name and image. The output
    should look something like:

    ```text
    c5acda1ee60b  localhost/ims-remote-a818004a-4ee4-4670-a938-2a353960b803:1.0.0  About a minute ago  Up About a minute  0.0.0.0:2022->22/tcp  ims-a818004a-4ee4-4670-a938-2a353960b803
    ```

    The first column of output is the container id - note it for the next step.

    NOTE: If the container has already been removed, restart the IMS job and repeat this step until the
    container for the new job starts running, then proceed to the next step.

1. (`cn`) Look at the logs of the container.

    ```bash
    podman logs --follow CONTAINER_ID
    ```

    Expect output to look something like:

    ```text
    + echo on
    on
    + IMAGE_ROOT_PARENT=/mnt/image
    + IMAGE_ROOT_DIR=/mnt/image/image-root/
    + SIGNAL_FILE_REMOTE_EXITING=/mnt/image/remote_exiting
    + SSHD_CONFIG_FILE=/etc/cray/ims/sshd_config
    Checking env vars
    + echo 'Checking env vars'
    + IMPORTED_VALS=('OAUTH_CONFIG_DIR' 'BUILD_ARCH' 'IMS_JOB_ID' 'IMAGE_ROOT_PARENT')
    + for item in "${IMPORTED_VALS[@]}"
    + [[ -z /etc/admin-client-auth ]]
    + for item in "${IMPORTED_VALS[@]}"
    + [[ -z x86_64 ]]
    + for item in "${IMPORTED_VALS[@]}"
    + [[ -z a818004a-4ee4-4670-a938-2a353960b803 ]]
    + for item in "${IMPORTED_VALS[@]}"

    ...

    Mounted /dev
    + '[' True = True ']'
    + echo 'ChrootDirectory /mnt/image/image-root/'
    + mkdir -p /root/.ssh
    + ssh-keygen -A
    ssh-keygen: generating new host keys: RSA DSA ECDSA ED25519 
    + echo 'SetEnv IMS_JOB_ID=a818004a-4ee4-4670-a938-2a353960b803 IMS_ARCH=x86_64 IMS_DKMS_ENABLED=True'
    + /usr/sbin/sshd -E /etc/cray/ims/sshd.log -f /etc/cray/ims/sshd_config
    + set +x
    off
    Waiting for signal file
    ```

### Look at the resources on the remote build node

There are two directories that are used by the remote builds and require the most space:

* `/tmp` - this is used to transfer files back and forth from the remote job to the system
* `/var/lib/containers` - this is used by Podman for images and container volume space

1. (`cn`) Check the current usage by running the following command on the remote build node.

    ```bash
    df -h
    ```

    The expected results should look something like:

    ```text
    Filesystem      Size  Used Avail Use% Mounted on
    devtmpfs        4.0M     0  4.0M   0% /dev
    tmpfs            32G   88K   32G   1% /dev/shm
    tmpfs            13G  6.7G  5.9G  54% /run
    tmpfs           4.0M     0  4.0M   0% /sys/fs/cgroup
    /dev/loop0      1.7G  1.7G     0 100% /run/rootfsbase
    LiveOS_rootfs    13G  6.7G  5.9G  54% /
    tmpfs            16G     0   16G   0% /tmp
    tmpfs           6.3G     0  6.3G   0% /run/user/0
    shm              63M     0   63M   0% /var/lib/containers/storage/overlay-containers/c5acda1ee60b9f41fcf8d86764217d732a4b9752c9bd416c6d1eb96e59a33a43/userdata/shm
    fuse-overlayfs   13G  6.7G  5.9G  54% /var/lib/containers/storage/overlay/47ea77d2bf8f62bea247db6da78c314f3f7121fdbc218b2cf9f252029afc1840/merged
    ```

    NOTE: the `/var/lib/containers` directories may not be present if there are no running container and no images on the node.

1. Add volume space if needed.

    For more information, see [Adding storage to a remote build node](Configure_a_Remote_Build_Node.md#adding-storage-to-a-remote-build-node).
