

## Customize an Image Root Using IMS

The Image Management Service \(IMS\) customization workflow sets up a temporary image customization environment within a Kubernetes pod and mounts the image to be customized in that environment. A system administrator then makes the desired changes to the image root within the customization environment. 

Afterwards, the IMS customization workflow automatically copies the NCN CA public key to */etc/cray/ca/certificate\_authority.crt* within the image root being customized to enable secure communications between NCNs and client nodes. IMS then compresses the customized image root and uploads it and its associated initrd image and kernel image \(needed to boot a node\) to the artifact repository.


### Prerequisites

- System management services \(SMS\) are running in a Kubernetes cluster on non-compute nodes \(NCN\) and include the following deployments:
    - `cray-ims`, the Image Management Service \(IMS\)
    - `cray-nexus`, the Nexus repository manager service
- `kubectl` is installed locally and configured to point at the SMS Kubernetes cluster.
- An IMS created image root archive or a pre-built image root SquashFS archive is available to customize.
- The NCN Certificate Authority \(CA\) public key has been properly installed into the CA cache for this system.
- A token providing Simple Storage Service \(S3\) credentials has been generated.
- When customizing an image using IMS Image Customization, once chrooted into the image root \(if using a \`jailed\` environment\), the image will only have access to whatever configuration the image already contains. In order to talk to services, including Nexus RPM repositories, the image root must first be configured with DNS and other settings. A base level of customization is provided by the default Ansible plays used by the Configuration Framework Service \(CFS\) to enable DNS resolution.


### Limitations

- The commands in this procedure must be run as the `root` user.
- Currently, the initrd image and kernel image are not regenerated automatically when the image root is changed. The admin must manually regenerate them while in the customization environment, if needed.
- Images in the .txz compressed format need to be converted to SquashFS in order to use IMS image customization.


### Procedure

**Enable Passwordless SSH**

1.  Check for an existing IMS public key `id`.

    Skip this step if it is known that a public key associated with the user account being used was not previously uploaded to the IMS service.

    The following query may return multiple public key records. The correct one will have a name value including the current username in use.

    ```bash
    ncn# cray ims public-keys list
    ```

    Example output:

    ```
    [...]

    [[results]]
    public_key = "ssh-rsa AAAAB3NzaC1yc2EA ... AsVruw1Zeiec2IWt"
    id = "a252ff6f-c087-4093-a305-122b41824a3e"
    name = "username public key"
    created = "2018-11-21T17:19:07.830000+00:00"
    
    [...]
    ```

    If a public key associated with the username in use is not returned, proceed to the next step. If a public key associated with the username does exist, create a variable for the IMS public key `id` value in the returned data and then proceed to step 3.

    ```bash
    ncn# export IMS_PUBLIC_KEY_ID=a252ff6f-c087-4093-a305-122b41824a3e
    ```

2.  Upload the SSH public key to the IMS service.

    Skip this step if an IMS public key record has already been created for the account being used.

    The IMS debug/configuration shell relies on passwordless SSH. This SSH public key needs to be uploaded to IMS to enable interaction with the image customization environment later in this procedure.

    Replace the username value with the actual username being used on the system when setting the public key name.

    ```bash
    ncn# cray ims public-keys create --name "username public key" --public-key ~/.ssh/id_rsa.pub
    ```

    Example output:

    ```
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl50gK4l9uupxC2KHxMpTNxPTJbnwEdWy1jst5W5LqJx9fdTrc9uNJ33HAq+WIOhPVGbLm2N4GX1WTUQ4+wVOSmmBBJnlu/l5rmO9lEGT6U8lKG8dA9c7qhguGHy7M7WBgdW/gWA16gwE/u8Qc2fycFERRKmFucL/Er9wA0/Qvz7/U59yO+HOtk5hvEz/AUkvaaoY0IVBfdNBCl59CIdZHxDzgXlXzd9PAlrXZNO8jDD3jyFAOvMMRG7py78zj2NUngvsWYoBcV3FcREZJU529uJ0Au8Vn9DRADyB4QQS2o+fa6hG9i2SzfY8L6vAVvSE7A2ILAsVruw1Zeiec2IWt"
    id = "a252ff6f-c087-4093-a305-122b41824a3e"
    name = "username public key"
    created = "2018-11-21T17:19:07.830000+00:00"
    ```

    If successful, create a variable for the IMS public key `id` value in the returned data.

    ```bash
    ncn# export IMS_PUBLIC_KEY_ID=a252ff6f-c087-4093-a305-122b41824a3e
    ```

**Locate or Register an Image Root Archive to Customize**

3.  Determine if the image root being used is in IMS and ready to be customized.

    IMS requires that the image root being used meets the following criteria:

    -   It is in SquashFS format.
    -   It has been uploaded to S3 via the Cray CLI.
    -   It is registered with the IMS service.
    Select one of the following options based on the current state of the image root being used:

    -   If the image root being customized meets the above requirements, proceed to [Locate an IMS Image to Customize](#locate).
    -   If the image root being customized is not in SquashFS format, refer to [Convert TGZ Archives to SquashFS Images](Convert_TGZ_Archives_to_SquashFS_Images.md).
    -   If the image root being customized is in SquashFS format and in S3, but not registered with the IMS service, proceed to [Register the Image Root with the IMS Service](#register).

**Create an IMS Image Record**

4.  Create a new IMS image record for the image.

    ```bash
    ncn# cray ims images create --name $IMS_ROOTFS_FILENAME
    ```

    Example output:

    ```
    created = "2018-12-04T17:25:52.482514+00:00"
    id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
    name = "sles_15_image.squashfs"
    ```

    If successful, create a variable for the id value in the returned data.

    ```bash
    ncn# export IMS_IMAGE_ID=4e78488d-4d92-4675-9d83-97adfc17cb19
    ```

**Upload Image Artifacts to S3**

The steps in this section apply only if the SquashFS image root is not yet in S3.

5.  Upload the image root to S3.

    ```bash
    ncn# cray artifacts create boot-images $IMS_IMAGE_ID $IMS_ROOTFS_FILENAME $IMS_ROOTFS_FILENAME
    ncn# export IMS_ROOTFS_MD5SUM=`md5sum $IMS_ROOTFS_FILENAME | awk '{ print $1 }'`
    ```

6.  Upload the kernel for the image to S3.

    ```bash
    ncn# export IMS_KERNEL_FILENAME=vmlinuz
    ncn# cray artifacts create boot-images $IMS_IMAGE_ID $IMS_KERNEL_FILENAME \
    image-root/boot/$IMS_KERNEL_FILENAME
    ncn# export IMS_KERNEL_MD5SUM=`md5sum image-root/boot/$IMS_KERNEL_FILENAME | awk '{ print $1 }'`
    ```

7.  Upload the initrd for the image to S3.

    ```bash
    ncn# export IMS_INITRD_FILENAME=initrd
    ncn# cray artifacts create boot-images $IMS_IMAGE_ID $IMS_INITRD_FILENAME \
    image-root/boot/$IMS_INITRD_FILENAME
    ncn# export IMS_INITRD_MD5SUM=`md5sum image-root/boot/$IMS_INITRD_FILENAME | awk '{ print $1 }'`
    ```

**Create an Image Manifest and Upload it to S3**

Cray uses a manifest file that associates multiple related boot artifacts \(kernel, initrd, rootfs\) into an image description that is used by IMS and other services to boot nodes. Artifacts listed within the manifest are identified by a `type` value:

- application/vnd.cray.image.rootfs.squashfs
- application/vnd.cray.image.initrd
- application/vnd.cray.image.kernel
- application/vnd.cray.image.parameters.boot

8.  Generate an image manifest file.

    ```bash
    ncn# cat <<EOF> manifest.json
    {
      "created": "`date '+%Y-%m-%d %H:%M:%S'`",
      "version": "1.0",
      "artifacts": [
        {
          "link": {
              "path": "s3://boot-images/$IMS_IMAGE_ID/$IMS_ROOTFS_FILENAME",
              "type": "s3"
          },
          "md5": "$IMS_ROOTFS_MD5SUM",
          "type": "application/vnd.cray.image.rootfs.squashfs"
        },
        {
          "link": {
              "path": "s3://boot-images/$IMS_IMAGE_ID/$IMS_KERNEL_FILENAME",
              "type": "s3"
          },
          "md5": "$IMS_KERNEL_MD5SUM",
          "type": "application/vnd.cray.image.kernel"
        },
        {
          "link": {
              "path": "s3://boot-images/$IMS_IMAGE_ID/$IMS_INITRD_FILENAME",
              "type": "s3"
          },
          "md5": "$IMS_INITRD_MD5SUM",
          "type": "application/vnd.cray.image.initrd"
        }
      ]
    }
    EOF
    ```

9.  Upload the manifest to S3.

    ```bash
    ncn# cray artifacts create boot-images $IMS_IMAGE_ID/manifest.json manifest.json
    ```

<a name="register"></a>
**Register the Image Root with the IMS Service**

10. Update the IMS image record.

    ```bash
    ncn# cray ims images update $IMS_IMAGE_ID \
    --link-type s3 \
    --link-path s3://boot-images/$IMS_IMAGE_ID/manifest.json
    ```

    Example output:

    ```
    created = "2018-12-04T17:25:52.482514+00:00"
    id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
    name = "sles_15_image.squashfs"

    [link]
    type = "s3"
    path = "s3://boot-images/4e78488d-4d92-4675-9d83-97adfc17cb19/manifest.json"
    etag = ""
    ```

<a name="locate"></a>

**Locate an IMS Image to Customize**

11. Locate the IMS image record for the image that is being customized.

    ```bash
    ncn# cray ims images list
    ```

    Example output:

    ```
    [...]

    [[results]]
    created = "2018-12-04T17:25:52.482514+00:00"
    id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
    name = "sles_15_image.squashfs"

    [results.link]
    type = "s3"
    path = "/4e78488d-4d92-4675-9d83-97adfc17cb19/sles_15_image.squashfs"
    etag = ""
    
    [...]
    ```

    If successful, create a variable for the `id` for the image that is being customized.

    ```bash
    ncn# export IMS_IMAGE_ID=4e78488d-4d92-4675-9d83-97adfc17cb19
    ```

**Submit the Kubernetes Image Customization Job**

12. Create an IMS job record and start the image customization job.

    After customizing the image, IMS will automatically upload any build artifacts \(root file system, kernel, and initrd\) to S3, and associate the S3 artifacts with IMS. Unfortunately, IMS is not able to dynamically determine the names of the Linux kernel and initrd to look for, because the file name for these vary depending upon Linux distribution, Linux version, dracut configuration, and more. Thus, the user must pass the name of the kernel and initrd that IMS is to look for in the resultant image root's /boot directory.

    Use the following table to help determine the default kernel and initrd file names to specify when submitting the job to customize an image. These are just default names. Please consult with the site administrator to determine if these names have been changed for a given image or recipe.

    |Recipe|Recipe Name|Kernel File Name|Initrd File Name|
    |------|-----------|----------------|----------------|
    |SLES 15 SP3 Barebones|cray-sles15sp3-barebones|vmlinuz|initrd|
    |COS|cray-shasta-compute-sles15sp3.x86_64-1.4.66|vmlinuz|initrd|

    1. Start the image customization job.

       Before running the following command, replace the MY\_CUSTOMIZED\_IMAGE value with the name of the image root being used.

       ```bash
       ncn# cray ims jobs create \
       --job-type customize \
       --kernel-file-name vmlinuz \
       --initrd-file-name initrd \
       --artifact-id $IMS_IMAGE_ID \
       --public-key-id $IMS_PUBLIC_KEY_ID \
       --enable-debug False \
       --image-root-archive-name MY_CUSTOMIZED_IMAGE
       ```

       Example output:

       ```
       status = "creating"
       enable_debug = false
       kernel_file_name = "vmlinuz"
       artifact_id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
       build_env_size = 10
       job_type = "customize"
       kubernetes_service = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-service"
       kubernetes_job = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-customize"
       id = "ad5163d2-398d-4e93-94f0-2f439f114fe7"
       image_root_archive_name = "MY_CUSTOMIZED_IMAGE"
       initrd_file_name = "initrd"
       created = "2018-11-21T18:22:53.409405+00:00"
       kubernetes_namespace = "ims"
       public_key_id = "a252ff6f-c087-4093-a305-122b41824a3e"
       kubernetes_configmap = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-configmap"
       [[ssh_containers]]
       status = "pending"
       jail = false
       name = "customize"

       [ssh_containers.connection_info."cluster.local"]
       host = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-service.ims.svc.cluster.local"
       port = 22
       [ssh_containers.connection_info.customer_access]
       host = "ad5163d2-398d-4e93-94f0-2f439f114fe7.ims.cmn.shasta.cray.com"
       port = 22
       ```

    2. Create variables for the IMS job ID, Kubernetes job ID, and the SSH connection values in the returned data.

       Before setting the SSH values, determine the appropriate method to SSH into the customization pod:

       - `[ssh_containers.connection_info.customer_access]` values \(**preferred**\): The `customer_access` address is a dynamic hostname that is made available for use by the customer to access the IMS Job from outside the Kubernetes cluster.
       - `[ssh_containers.connection_info."cluster.local"]` values: The `cluster.local` address is used when trying to access an IMS Job from a pod that is running within the HPE Cray EX Kubernetes cluster. For example, this is the address that CFS uses to talk to the IMS Job during a pre-boot customization session.

       The external IP address should only be used if the dynamic `customer_access` hostname does not resolve properly. In the following example, the admin could then SSH to the 10.103.2.160 IP address.

       ```bash
       ncn# kubectl get services -n ims | grep IMS_JOB_ID
       ```

       Example output:

       ```
       NAME                                                    TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)        AGE
       cray-ims-06c3dd57-f347-4229-85b3-1d024a947b3f-service   LoadBalancer   10.29.129.204   10.103.2.160   22:31627/TCP   21h
       ```

       To create the variables:

       ```bash
       ncn# export IMS_JOB_ID=ad5163d2-398d-4e93-94f0-2f439f114fe7
       ncn# export IMS_KUBERNETES_JOB=cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-customize
       ncn# export IMS_SSH_HOST=ad5163d2-398d-4e93-94f0-2f439f114fe7.ims.cmn.shasta.cray.com
       ncn# export IMS_SSH_PORT=22
       ```

       The IMS customization job enables customization of the image root via an SSH shell accessible by one or more dynamic host names. The user needs to know if they will SSH from inside or outside the Kubernetes cluster to determine which host name to use. Typically, customers access the system from outside the Kubernetes cluster using the Customer Access Network \(CAN\).

       Under normal circumstances, IMS customization jobs will download and mount the rootfs for the specified IMS image under the `/mnt/image/image-root` directory within the SSH shell. After SSHing into the job container, `cd` or `chroot` into the `/mnt/image/image-root` directory in order to interact with the image root being customized.

       Optionally, IMS can be told to create a jailed SSH environment by specifying the `--ssh-containers-jail True` parameter.

       A jailed environment lets users SSH into the SSH container and be immediately within the image root for the image being customized. Users do not need to `cd` or `chroot` into the image root. Using a jailed environment has some advantages, such as making the IMS SSH job shell look more like a compute node. This allows applications like the CFS to perform actions on both IMS job pods \(pre-boot\) and compute nodes \(post-boot\).

13. Use `kubectl` and the returned `IMS_KUBERNETES_JOB` value to describe the image create job.

    ```bash
    ncn# kubectl -n ims describe job $IMS_KUBERNETES_JOB
    ```

    Example output:

    ```
    Name: cray-ims-cfa864b3-4e08-49b1-9c57-04573228fd3f-customize
    Namespace: default
    
    [...]

    Events:
    Type Reason Age From Message
    ---- ------ ---- ---- -------
    Normal SuccessfulCreate 4m job-controller Created pod: cray-ims-cfa864b3-4e08-49b1-9c57-04573228fd3f-customize-xh2jf
    ```

    If successful, create a variable for the pod name using the value indicated in the output above, which will be used in future steps.

    ```bash
    ncn# export POD=cray-ims-cfa864b3-4e08-49b1-9c57-04573228fd3f-customize-xh2jf
    ```

14. Verify that the status of the IMS job is waiting_on_user.

    ```bash
    ncn# cray ims jobs describe $IMS_JOB_ID
    ```

    Example output:

    ```
    status = "waiting_on_user"
    enable_debug = false
    kernel_file_name = "vmlinuz"
    artifact_id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
    build_env_size = 10
    job_type = "customize"
    kubernetes_service = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-service"
    kubernetes_job = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-customize"
    id = "ad5163d2-398d-4e93-94f0-2f439f114fe7"
    image_root_archive_name = "my_customized_image"
    initrd_file_name = "initrd"
    created = "2018-11-21T18:22:53.409405+00:00"
    kubernetes_namespace = "ims"
    public_key_id = "a252ff6f-c087-4093-a305-122b41824a3e"
    kubernetes_configmap = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-configmap"
    [[ssh_containers]]
    status = "pending"
    jail = false
    name = "customize"

    [ssh_containers.connection_info."cluster.local"]
    host = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-service.ims.svc.cluster.local"
    port = 22
    [ssh_containers.connection_info.customer_access]
    host = "ad5163d2-398d-4e93-94f0-2f439f114fe7.ims.cmn.shasta.cray.com"
    port = 22
    ```

15. Customize the image in the image customization environment.

    Once chrooted into the image root \(or if using a \`jailed\` environment\) during image customization, the image will only have access to whatever configuration the image already contains. In order to talk to services, including Nexus RPM repositories, the image root must first be configured with DNS and other settings. A base level of customization is provided by the default Ansible plays used by the CFS to enable DNS resolution.

    -   **Option 1:** SSH to the image customization environment.

        The image root is available under /mnt/image/image-root. For passwordless SSH to work, ensure that the correct public/private key pair is used. The private key will need to match the public key that was uploaded to the IMS service and specified in the IMS Job.

        **IMPORTANT:** The following command will work when run on any of the master nodes and worker nodes, except for ncn-w001.

        ```bash
        ncn# ssh -p $IMS_SSH_PORT root@$IMS_SSH_HOST
        Last login: Tue Sep  4 18:06:27 2018 from gateway
        [root@POD ~]#
        ```

        Once connected to the IMS image customization shell, perform any customizations required. If the SSH shell was created without using the `--ssh-containers-jail True` parameter, cd or chroot into the image root. 

        After changes have been made, run the touch command on the `complete` file. The location of the complete file depends on whether or not the SSH job shell was created using the `--ssh-containers-jail True` parameter. See the table below for more information.

        |--ssh-containers-jail|Command used to create the complete file|
        |---------------------|----------------------------------------|
        |False \(default\)|touch /mnt/image/complete|
        |True|touch /tmp/complete|

        ```bash
        [root@POD image]# cd /mnt/image/
        [root@POD image]# chroot image-root/
        :/ # (do touch complete flag)
        :/ # exit
        [root@POD image]#
        ```

        When the complete file has been created, the following actions will occur:

        -   The job SSH container will close any active SSH connections
        -   The `buildenv-sidecar` container will compresses the image root
        -   The customized artifacts will be uploaded to S3 and associated with a new IMS image record

    -   **Option 2:** Use Ansible to run playbooks against the image root.

        ```bash
        ncn# ansible all -i $IMS_SSH_HOST, -m ping --ssh-extra-args " -p $IMS_SSH_PORT -i ./pod_rsa_key \
        -o StrictHostKeyChecking=no" -u root
        ad5163d2-398d-4e93-94f0-2f439f114fe7.ims.cmn.shasta.cray.com | SUCCESS => {
            "changed": false,
            "ping": "pong"
        }
        ```

        This Ansible inventory file below can also be used. The private key \(`./pod_rsa_key`\) corresponds to the public key file the container has in its authorized\_keys file.

        ```bash
        myimage-customize ansible_user=root ansible_host=ad5163d2-398d-4e93-94f0-2f439f114fe7.ims.cmn.shasta.cray.com ansible_port=22 \
                          ansible_ssh_private_key_file=./pod_rsa_key ansible_ssh_common_args='-o \
                          StrictHostKeyChecking=no'
        ```

        A sample playbook can be run on the image root:

        ```bash
        ---
        # The playbook creates a new database test and populates data in the database to test the sharding.

        - hosts: all
        remote_user: root
        tasks:

        - name: Look at the image root
        command: "ls -l /mnt/image/image-root"

        - name: chroot and run dracut
        command: "chroot /mnt/image/image-root dracut --force --kver 4.4.143-94.47-default"

        - name: example copying file with owner and permissions
        copy:
        src: sample_playbook.yml
        dest: /mnt/image/image-root/tmp

        - name: Exit the build container
        copy:
        src: nothing_file
        dest: /mnt/image/complete
        ```

        The sample playbook can be run with the following command:

        ```bash
        ncn# ansible-playbook -i ./inventory.ini sample_playbook.yml
        ```

16. Tail the `buildenv-sidecar` to ensure that any artifacts are properly uploaded to S3 and associated with IMS.

    ```bash
    ncn# kubectl -n ims logs -f $POD -c buildenv-sidecar
    + python -m ims_python_helper image upload_artifacts sles15_barebones_image 7de80ccc-1e7d-43a9-a6e4-02cad10bb60b
    -v -r /mnt/image/sles15_barebones_image.sqsh -k /mnt/image/image-root/boot/vmlinuz
    -i /mnt/image/image-root/boot/initrd
    ```

    Example output:

    ```
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
            "name": "sles15_barebones_image"
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
            "image_root_archive_name": "sles15_barebones_image",
            "initrd_file_name": "initrd",
            "job_type": "create",
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

    The IMS customization workflow automatically copies the NCN Certificate Authority's public certificate to /etc/cray/ca/certificate_authority.crt within the image root being customized. This can be used to enable secure communications between the NCN and the client node.

17. Look up the ID of the newly created image.

    ```bash
    ncn# cray ims jobs describe $IMS_JOB_ID
    ```

    Example output:

    ```
    status = "success"
    enable_debug = false
    kernel_file_name = "vmlinuz"
    artifact_id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
    build_env_size = 10
    job_type = "customize"
    kubernetes_service = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-service"
    kubernetes_job = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-customize"
    id = "ad5163d2-398d-4e93-94f0-2f439f114fe7"
    image_root_archive_name = "my_customized_image"
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

18. Verify the new IMS image record exists.

    ```bash
    ncn# cray ims images describe $IMS_RESULTANT_IMAGE_ID
    ```

    Example output:

    ```
    created = "2018-12-04T17:25:52.482514+00:00"
    id = "d88521c3-b339-43bc-afda-afdfda126388"
    name = "my_customized_image.squashfs"

    [link]
    type = "s3"
    path = "/d88521c3-b339-43bc-afda-afdfda126388/my_customized_image.squashfs"
    etag = "28f3d78c8cceca2083d7d3090d96bbb7"
    ```

**Clean Up the Image Customization Environment**

19. Delete the IMS job record.

    ```bash
    ncn# cray ims jobs delete $IMS_JOB_ID
    ```

    Deleting the job record also deletes the underlying Kubernetes job, service, and ConfigMap that were created when the job record was submitted.


The image root has been modified, compressed, and uploaded to S3, along with its associated initrd and kernel files. The image customization environment has also been cleaned up.


