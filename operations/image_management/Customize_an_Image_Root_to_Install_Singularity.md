## Customize an Image Root to Install Singularity

Use the Image Management Service \(IMS\) infrastructure to modify a compute image to install the singularity container runtime. This procedure uses the image customization process.

There are several starting points for modifying compute images. An admin can start with a bare bones image as described in [Customize an Image Root Using IMS](Customize_an_Image_Root_Using_IMS.md), or start with an existing image that is already in use. This procedure starts with an image rootfs that is already being used on the compute nodes.

### Prerequisites

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.
-   System management services \(SMS\) are running in a Kubernetes cluster on non-compute nodes \(NCN\) and include the following deployment:
    -   cray-ims, the Image Management Service \(IMS\)

### Procedure

1.  Query the Boot Script Service \(BSS\) for the compute image.

    ```bash
    ncn# cray bss bootparameters list --nids 1
    [[results]]
    params = "console=ttyS0,115200 bad_page=panic crashkernel=360M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt 
    ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y 
    rd.neednet=1 rd.retry=10 rd.shell k8s_gw=api-gw-service-nmn.local quiet turbo_boost_limit=999 
    root=craycps-s3:s3://boot-images/**6ca24366-9bc7-4a35-8c2a-5d0bc287ae64**/rootfs:b5ad8d47bd5d33b1fcb72a85ea70b74d-165:dvs:api-gw-service-nmn.local:300:eth0"
    initrd = "s3://boot-images/6ca24366-9bc7-4a35-8c2a-5d0bc287ae64/initrd"
    hosts = [ "x3000c0s19b1n0",]
    kernel = "s3://boot-images/6ca24366-9bc7-4a35-8c2a-5d0bc287ae64/kernel"
    ```

    If successful, create a variable for the root argument in the returned output that references the boot image ID. In the example above, this value is 6ca24366-9bc7-4a35-8c2a-5d0bc287ae64.

    ```bash
    ncn# export ROOTFS=6ca24366-9bc7-4a35-8c2a-5d0bc287ae64
    ```

2.  Find the image that refers to the desired artifact.

    ```bash
    ncn# cray ims images list | grep -C 3 $ROOTFS
    [[results]]
    created = "2019-11-22T17:05:19.717337+00:00"
    id = "6ca24366-9bc7-4a35-8c2a-5d0bc287ae64" 
    name = "cle_default_rootfs_cfs_0ade0002-0d49-11ea-a1ed-a4bf0135a8ee"
    
    [results.link]
    type = "s3"
    path = "/6ca24366-9bc7-4a35-8c2a-5d0bc287ae64/cle_default_rootfs_cfs_0ade0002-0d49-11ea-a1ed-a4bf0135a8ee"
    etag = ""
    ```

    If successful, create a variable for the image ID.

    ```bash
    ncn# export IMS_IMAGE_ID=6ca24366-9bc7-4a35-8c2a-5d0bc287ae64
    ```

3.  Describe the image to verify the information is accurate.

    ```bash
    ncn# cray ims images describe $IMS_IMAGE_ID
    [[results]]
    created = "2019-11-22T17:05:19.717337+00:00"
    id = "6ca24366-9bc7-4a35-8c2a-5d0bc287ae64" 
    name = "cle_default_rootfs_cfs_0ade0002-0d49-11ea-a1ed-a4bf0135a8ee"
    
    [results.link]
    type = "s3"
    path = "/6ca24366-9bc7-4a35-8c2a-5d0bc287ae64/cle_default_rootfs_cfs_0ade0002-0d49-11ea-a1ed-a4bf0135a8ee"
    etag = ""
    ```

4.  Check for an existing IMS public key `id`.

    Skip this step if it is known that a public key associated with the user account being used was not previously uploaded to the IMS service.

    The following query may return multiple public key records. The correct one will have a name value including the current username in use.

    ```bash
    ncn# cray ims public-keys list
    ...
    [[results]]
    public_key = "ssh-rsa AAAAB3NzaC1yc2EA ... AsVruw1Zeiec2IWt"
    id = "d599f45a-53c3-4071-a603-96e864fc43cc"
    name = "username public key"
    created = "2018-11-21T17:19:07.830000+00:00"
    ...
    ```

    If a public key associated with the username in use is not returned, proceed to the next step. If a public key associated with the username does exist, create a variable for the IMS public key `id` value in the returned data and then proceed to step 6.

    ```bash
    ncn# export IMS_PUBLIC_KEY_ID=d599f45a-53c3-4071-a603-96e864fc43cc
    ```

5.  Upload the SSH public key to the IMS service.

    Skip this step if an IMS public key record has already been created for the account being used.

    The IMS debug/configuration shell relies on passwordless SSH. This SSH public key needs to be uploaded to IMS to enable interaction with the image customization environment later in this procedure.

    Replace the username value with the actual username being used on the system when setting the public key name.

    ```bash
    ncn# cray ims public-keys create --name "username public key" --public-key ~/.ssh/id_rsa.pub
    public_key = "ssh-rsa
    AAAAB3NzaC1yc2EAAAADAQABAAABAQCl50gK4l9uupxC2KHxMpTNxPTJbnwEdWy1jst5W5LqJx9fdTrc9uNJ33HAq
    +WIOhPVGbLm2N4GX1WTUQ4+wVOSmmBBJnlu/l5rmO9lEGT6U8lKG8dA9c7qhguGHy7M7WBgdW/gWA16gwE/
    u8Qc2fycFERRKmFucL/Er9wA0/Qvz7/U59yO+HOtk5hvEz/
    AUkvaaoY0IVBfdNBCl59CIdZHxDzgXlXzd9PAlrXZNO8jDD3jyFAOvMMRG7py78zj2NUngvsWYoBcV3FcREZJU529uJ0Au8Vn9DRA
    DyB4QQS2o+fa6hG9i2SzfY8L6vAVvSE7A2ILAsVruw1Zeiec2IWt"
    id = "d599f45a-53c3-4071-a603-96e864fc43cc" 
    name = "username public key"
    created = "2018-11-21T17:19:07.830000+00:00"
    ```

    If successful, create a variable for the IMS public key `id` value in the returned data.

    ```bash
    ncn# export IMS_PUBLIC_KEY_ID=d599f45a-53c3-4071-a603-96e864fc43cc
    ```

6.  Create an IMS job record and start the image customization job.

    After customizing the image, IMS will automatically upload any build artifacts \(root file system, kernel and initrd\) to S3, and associate the S3 artifacts with IMS. Unfortunately, IMS is not able to dynamically determine the Linux kernel and initrd to look for since the file name for these vary depending upon Linux distribution, Linux version, dracut configuration, and more. Thus, the user must pass the name of the kernel and initrd that IMS is to look for in the resultant image root’s /boot directory.

    ```bash
    ncn# cray ims jobs create \
    --job-type customize \
    --image-root-archive-name singularity_image \
    --kernel-file-name vmlinuz \
    --build-env-size 20 \
    --initrd-file-name initrd \
    --artifact-id $IMS_IMAGE_ID \
    --public-key-id $IMS_PUBLIC_KEY_ID
    status = "creating"
    enable_debug = false
    kernel_file_name = "vmlinuz"
    artifact_id = "5be661d9-f7ac-4fa9-bff3-28ec148994ad"
    build_env_size = 20
    job_type = "customize"
    kubernetes_service = "cray-ims-0e633134-41dc-48eb-a6a4-a2535cb1a36c-service"
    kubernetes_job = "cray-ims-0e633134-41dc-48eb-a6a4-a2535cb1a36c-customize" 
    id = "0e633134-41dc-48eb-a6a4-a2535cb1a36c" 
    image_root_archive_name = "singularity_image"
    initrd_file_name = "initrd"
    created = "2019-12-14T23:40:55.765702+00:00"
    kubernetes_namespace = "default"
    public_key_id = "28119e22-8722-45d7-8bd2-96c607b5549f"
    kubernetes_configmap = "cray-ims-0e633134-41dc-48eb-a6a4-a2535cb1a36c-configmap"
    [[ssh_containers]]
    status = "pending"
    jail = false
    name = "customize"
    [ssh_containers.connection_info."cluster.local"]
    host = "cray-ims-0e633134-41dc-48eb-a6a4-a2535cb1a36c-service.default.svc.cluster.local"
    port = 22
    [ssh_containers.connection_info.customer_access]
    host = "0e633134-41dc-48eb-a6a4-a2535cb1a36c.ims.system.dev.cray.com"
    port = 22
    ```

    If successful, create variables for the IMS job `id` and the SSH connection values in the returned data.

    ```bash
    ncn# export IMS_JOB_ID=0e633134-41dc-48eb-a6a4-a2535cb1a36c
    ncn# export IMS_SSH_HOST=0e633134-41dc-48eb-a6a4-a2535cb1a36c.ims.system.dev.cray.com
    ncn# export IMS_SSH_PORT=22
    ```

    The IMS customization job enables customization of the image root via an SSH shell accessible by one or more dynamic host names. The user needs to know if they will SSH from inside or outside the Kubernetes cluster to determine which host name to use. Typically, customers access the system from outside the Kubernetes cluster using the Customer Access Network \(CAN\).

    Under normal circumstances, IMS customization jobs will download and mount the rootfs for the specified IMS image under the /mnt/image/image-root directory within the SSH shell. After SSHing into the job container, cd or chroot into the /mnt/image/image-root directory in order to interact with the image root being customized.

    Optionally, IMS can be told to create a jailed SSH environment by specifying the --ssh-containers-jail True parameter.

    A jailed environment lets users SSH into the SSH container to be immediately within the image root for the image being customized. Users do not need to cd or chroot into the image root. Using a jailed environment has some advantages, such as making the IMS SSH job shell look more like a compute node. This allows applications like the Configuration Framework Service \(CFS\) to perform actions on both IMS job pods \(preboot\) and compute nodes \(post-boot\).

7.  Verify that the status of the IMS job is `waiting_on_user`.

    ```bash
    ncn# cray ims jobs describe $IMS_JOB_ID
    status = "waiting_on_user" 
    enable_debug = false
    kernel_file_name = "vmlinuz"
    artifact_id = "84783ec6-03d3-4ac1-8631-b448f9e6275b"
    build_env_size = 20
    job_type = "customize"
    kubernetes_service = "cray-ims-e68cc04a-8717-4d5d-98dd-4e8117bc9b85-service"
    kubernetes_job = "cray-ims-e68cc04a-8717-4d5d-98dd-4e8117bc9b85-customize"
    id = "e68cc04a-8717-4d5d-98dd-4e8117bc9b85"
    image_root_archive_name = "singularity_image"
    initrd_file_name = "initrd"
    created = "2019-12-03T17:46:12.669878+00:00"
    kubernetes_namespace = "default"
    public_key_id = "4d428348-a200-4f6c-bee4-1b0e6a6bd7e5"
    kubernetes_configmap = "cray-ims-e68cc04a-8717-4d5d-98dd-4e8117bc9b85-configmap"
    resultant_image_id = "db326952-759e-4ed6-be39-cf6be4371365" 
    [[ssh_containers]]
    status = "pending"
    host = "mgmt-plane-nmn.local"
    jail = false
    name = "customize"
    port = 31585
    ```

8.  SSH to the image customization environment.

    Use the host and port values returned in the image customization creation job launched by the cray ims jobs create command.

    For passwordless SSH to work, ensure that the correct public/private key pair is used. The private key will need to match the public key that was uploaded to the IMS service and specified in the IMS Job.

    **Important:** The following command will work when run on any of the master nodes and worker nodes, except for ``.

    ```bash
    ncn# ssh -p $IMS_SSH_PORT root@$IMS_SSH_HOST
    Last login: Tue Sep  4 18:06:27 2018 from gateway
    [root@POD ~]#
    ```

9.  Change to the image root directory.

    Once connected to the IMS image customization shell, customizations to install singularity can be made. If the SSH shell was created without using the --ssh-containers-jail True parameter, cd or chroot into the image root.

    ```bash
    [root@POD image]# cd /mnt/image/
    [root@POD image]# chroot image-root/
    ```

10. Turn off signature verification by setting the `gpgcheck` value to `off`.

    ```bash
    :/ # for f in /etc/zypp/repos.d/*; do echo "gpgcheck=off" >> $f; done
    :/ # zypper refresh && zypper lr
    ```

11. Find the available Singularity components.

    ```bash
    :/ # zypper search -s singularity
    Loading repository data...
    Reading installed packages...
     
    S | Name                  | Type    | Version | Arch   | Repository
    --+-----------------------+---------+---------+--------+-------------------
      | singularity           | package | 3.5.3-1 | x86_64 | cray-sles15-sp1-cn
      | singularity-debuginfo | package | 3.5.3-1 | x86_64 | cray-sles15-sp1-cn
    ```

12. Install the new components.

    ```bash
    :/ # zypper --non-interactive install singularity squashfs
    Loading repository data...
    Reading installed packages...
    Resolving package dependencies...
     
    The following 3 NEW packages are going to be installed:
      liblzo2-2 singularity squashfs
     
    The following 3 packages have no support information from their vendor:
      liblzo2-2 singularity squashfs
     
    3 new packages to install.
    Overall download size: 20.9 MiB. Already cached: 0 B. After the operation, additional 97.6 MiB will be used.
    Continue? [y/n/v/...? shows all options] (y): y
    Retrieving package liblzo2-2-2.10-2.22.x86_64                                                                 (1/3),  50.8 KiB (134.2 KiB unpacked)
    Retrieving: liblzo2-2-2.10-2.22.x86_64.rpm ..................................................................................................[done]
    Retrieving package squashfs-4.3-1.29.x86_64                                                                   (2/3), 134.5 KiB (351.1 KiB unpacked)
    Retrieving: squashfs-4.3-1.29.x86_64.rpm ....................................................................................................[done]
    Retrieving package singularity-3.5.3-1.x86_64                                                                 (3/3),  20.7 MiB ( 97.1 MiB unpacked)
    Retrieving: singularity-3.5.3-1.x86_64.rpm ..................................................................................................[done]
     
    Checking for file conflicts: ................................................................................................................[done]
    (1/3) Installing: liblzo2-2-2.10-2.22.x86_64 ................................................................................................[done]
    (2/3) Installing: squashfs-4.3-1.29.x86_64 ..................................................................................................[done]
    (3/3) Installing: singularity-3.5.3-1.x86_64 ................................................................................................[done]
    
    ```

13. Finish the install and exit the image customization environment.

    After changes have been made, run the touch command on the `complete` file. The location of the complete file depends on whether or not the SSH job shell was created using the `--ssh-containers-jail True` parameter. See the table below for more information.

    |--ssh-containers-jail|Command used to create the complete file|
    |---------------------|----------------------------------------|
    |False \(default\)|touch /mnt/image/complete|
    |True|touch /tmp/complete|

    ```bash
    :/ # exit
    exit
    [root@cray-ims-9c4b689e-831d-4e25-b25f-50986145fec5-customize-s6njd image]# touch /mnt/image/complete
    ```

    When the complete file has been created, the following actions will occur:

    -   The job SSH container will close any active SSH connections
    -   The `buildenv-sidecar` container will compresses the image root
    -   The customized artifacts will be uploaded to S3 and associated with a new IMS image record
  
14. Ensure that any artifacts are properly uploaded to S3 and associated with IMS.

    If the $POD variable was not defined when creating the image customization job, use the Kubernetes pod name from the job description.

    ```bash
    ncn# kubectl -n ims logs -f $POD -c buildenv-sidecar
    + python -m ims_python_helper image upload_artifacts singularity_image 7de80ccc-1e7d-43a9-a6e4-02cad10bb60b 
    -v -r /mnt/image/singularity_image.sqsh -k /mnt/image/image-root/boot/vmlinuz 
    -i /mnt/image/image-root/boot/initrd
    {
        "ims_image_artifacts": [
            {
                "link": {
                    "etag": "4add976679c7e955c4b16d7e2cfa114e-32",
                    "path": "s3://boot-images/d88521c3-b339-43bc-afda-afdfda126388/rootfs",
                    "type": "s3"
                },
                "md5": "94165af4373e5ace3e817eb4baba2284",
                "type": "application/vnd.cray.image.rootfs.squashfs"
            },
            {
                "link": {
                    "etag": "f836412241aae79d160556ed6a4eb4d4",
                    "path": "s3://boot-images/d88521c3-b339-43bc-afda-afdfda126388/kernel",
                    "type": "s3"
                },
                "md5": "f836412241aae79d160556ed6a4eb4d4",
                "type": "application/vnd.cray.image.kernel"
            },
            {
                "link": {
                    "etag": "ec8793c07f94e59a2a30abdb1bd3d35a-4",
                    "path": "s3://boot-images/d88521c3-b339-43bc-afda-afdfda126388/initrd",
                    "type": "s3"
                },
                "md5": "86832ee3977ca0515592e5d00271d2fe",
                "type": "application/vnd.cray.image.initrd"
            },
            {
                "link": {
                    "etag": "13af343f3e76b0f8c7fbef7ee3588ac1",
                    "path": "s3://boot-images/d88521c3-b339-43bc-afda-afdfda126388/manifest.json",
                    "type": "s3"
                },
                "md5": "13af343f3e76b0f8c7fbef7ee3588ac1",
                "type": "application/json"
            }
        ],
        "ims_image_record": {
            "created": "2018-12-17T22:59:43.264129+00:00",
            "id": "d88521c3-b339-43bc-afda-afdfda126388",
            "name": "singularity_image"
            "link": {
                "etag": "13af343f3e76b0f8c7fbef7ee3588ac1",
                "path": "s3://boot-images/d88521c3-b339-43bc-afda-afdfda126388/manifest.json",
                "type": "s3"
            },
        },
        "ims_job_record": {
            "artifact_id": "2233c82a-5081-4f67-bec4-4b59a60017a6",
            "build_env_size": 10,
            "created": "2018-11-21T18:22:53.409405+00:00",
            "enable_debug": false,
            "id": "ad5163d2-398d-4e93-94f0-2f439f114fe7", 
            "image_root_archive_name": "singularity_image",
            "initrd_file_name": "initrd",
            "job_type": "customize",
            "kernel_file_name": "vmlinuz",
            "kubernetes_configmap": "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-configmap",
            "kubernetes_job": "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-create",
            "kubernetes_service": "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-service",
            "public_key_id": "a252ff6f-c087-4093-a305-122b41824a3e",
            "resultant_image_id": "d88521c3-b339-43bc-afda-afdfda126388",
            "ssh_port": 0,
            "status": "packaging_artifacts"
        },
        "result": "success"
    }
    ```

    Create a variable for the IMS job id value in the returned data.

    ```bash
    ncn# export IMS_JOB_ID=ad5163d2-398d-4e93-94f0-2f439f114fe7
    ```

    The IMS customization workflow automatically copies the NCN Certificate Authority’s public certificate to /etc/cray/ca/certificate\_authority.crt within the image root being customized. This can be used to enable secure communications between the NCN and the client node.

15. Look up the ID of the newly created image.

    ```bash
    # cray ims jobs describe $IMS_JOB_ID
    status = "success"
    enable_debug = false
    kernel_file_name = "vmlinuz"
    artifact_id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
    build_env_size = 10
    job_type = "customize"
    kubernetes_service = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-service"
    kubernetes_job = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-customize"
    id = "ad5163d2-398d-4e93-94f0-2f439f114fe7"
    image_root_archive_name = "singularity_image"
    initrd_file_name = "initrd"
    resultant_image_id = "d88521c3-b339-43bc-afda-afdfda126388" 
    created = "2018-11-21T18:22:53.409405+00:00"
    kubernetes_namespace = "ims"
    public_key_id = "a252ff6f-c087-4093-a305-122b41824a3e"
    kubernetes_configmap = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-configmap"
    ```

    If successful, create a variable for the IMS `resultant_image_id` value in the returned data.

    ```bash
    ncn# export IMS_RESULTANT_IMAGE_ID=d88521c3-b339-43bc-afda-afdfda126388
    ```

16. Verify the new IMS image record exists.

    ```bash
    ncn# cray ims images describe $IMS_RESULTANT_IMAGE_ID
    created = "2018-12-04T17:25:52.482514+00:00"
    id = "d88521c3-b339-43bc-afda-afdfda126388"
    name = "singularity_image.squashfs"
    
    [link]
    type = "s3"
    path = "/d88521c3-b339-43bc-afda-afdfda126388/singularity_image.squashfs"
    etag = "28f3d78c8cceca2083d7d3090d96bbb7"
    ```

17. Look up the IMS Job ID.

    ```bash
    ncn# cray ims jobs list
    ...
    [[results]]
    status = "success"
    enable_debug = false
    kernel_file_name = "vmlinuz"
    artifact_id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
    build_env_size = 10
    job_type = "customize"
    kubernetes_service = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-service"
    kubernetes_job = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-customize"
    id = "ad5163d2-398d-4e93-94f0-2f439f114fe7" 
    image_root_archive_name = "singularity_image"
    initrd_file_name = "initrd"
    resultant_image_id = "d88521c3-b339-43bc-afda-afdfda126388"
    created = "2018-11-21T18:22:53.409405+00:00"
    kubernetes_namespace = "ims"
    public_key_id = "a252ff6f-c087-4093-a305-122b41824a3e"
    kubernetes_configmap = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-configmap"
    ...
    ```

18. Delete the IMS job record.

    ```bash
    ncn# cray ims jobs delete $IMS_JOB_ID
    ```

    Deleting the job record also deletes the underlying Kubernetes job, service and ConfigMap that were created when the job record was submitted.


