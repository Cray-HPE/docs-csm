# Build an Image Using IMS REST Service

Create an image root from an IMS recipe.

## Prerequisites

* The Cray command line interface \(CLI\) tool is initialized and configured on the system.
* System management services \(SMS\) are running in a Kubernetes cluster on non-compute nodes \(NCN\) and include the
  following deployments:
  * `cray-ims`, the Image Management Service \(IMS\)
  * `cray-nexus`, the Nexus repository manager service
* The NCN Certificate Authority \(CA\) public key has been properly installed into the CA cache for this system.
* `kubectl` is installed locally and configured to point at the SMS Kubernetes cluster.
* A Kiwi image recipe uploaded as a gzipped tar file and registered with IMS.
  See [Upload and Register an Image Recipe](Upload_and_Register_an_Image_Recipe.md).
* A token providing Simple Storage Service \(S3\) credentials has been generated.

## Limitations

The commands in this procedure must be run as the `root` user.

## Procedure

### Prepare to create the image

1. (`ncn-mw#`) Check for an existing IMS public key ID.

   > Skip this step if it is known that a public key associated with the user account being used was not previously
   uploaded to the IMS service.

   The following query may return multiple public key records. The correct one will have a name value including the
   current username in use.

    ```bash
    cray ims public-keys list
    ```

   Example output excerpt:

    ```toml
    [[results]]
    public_key = "ssh-rsa AAAAB3NzaC1yc2EA ... AsVruw1Zeiec2IWt"
    id = "a252ff6f-c087-4093-a305-122b41824a3e"
    name = "username public key"
    created = "2018-11-21T17:19:07.830000+00:00"
    ```

   If a public key associated with the username in use is not returned, proceed to the next step. If a public key
   associated with the username does exist, create a variable for the IMS public key `id` value in the returned data and
   then proceed to step 3.

    ```bash
    IMS_PUBLIC_KEY_ID=a252ff6f-c087-4093-a305-122b41824a3e
    ```

1. (`ncn-mw#`) Upload the SSH public key to the IMS service.

   > Skip this step if an IMS public key record has already been created for the account being used.

   The IMS debug/configuration shell relies on passwordless SSH. This SSH public key needs to be uploaded to IMS to
   enable interaction with the image customization environment later in this procedure.

   Replace the username value with the actual username being used on the system when setting the public key name.

   ```bash
   cray ims public-keys create --name "username public key" --public-key ~/.ssh/id_rsa.pub
   ```

   Example output:

   ```toml
   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl50gK4l9uupxC2KHxMpTNxPTJbnwEdWy1jst5W5LqJx9fdTrc9uNJ33HAq+WIOhPVGbLm2N4GX1WTUQ4+wVOSmmBBJnlu/l5rmO9lEGT6U8lKG8dA9c7qhguGHy7M7WBgdW/gWA16gwE/u8Qc2fycFERRKmFucL/Er9wA0/Qvz7/U59yO+HOtk5hvEz/AUkvaaoY0IVBfdNBCl59CIdZHxDzgXlXzd9PAlrXZNO8jDD3jyFAOvMMRG7py78zj2NUngvsWYoBcV3FcREZJU529uJ0Au8Vn9DRADyB4QQS2o+fa6hG9i2SzfY8L6vAVvSE7A2ILAsVruw1Zeiec2IWt"
   id = "a252ff6f-c087-4093-a305-122b41824a3e"
   name = "username public key"
   created = "2018-11-21T17:19:07.830000+00:00"
    ```

    If successful, create a variable for the IMS public key `id` value in the returned data.

    ```bash
    IMS_PUBLIC_KEY_ID=a252ff6f-c087-4093-a305-122b41824a3e
    ```

### Get the IMS recipe to build

1. (`ncn-mw#`) Locate the IMS recipe needed to build the image.

   ```bash
   cray ims recipes list
   ```

   Example output excerpt:

   ```toml
   [[results]]
   id = "2233c82a-5081-4f67-bec4-4b59a60017a6"
   name = "my_recipe.tgz"
   created = "2020-02-05T19:24:22.621448+00:00"
   arch = "x86_64"
   require_dkms = false

   [results.link]
   path = "s3://ims/recipes/2233c82a-5081-4f67-bec4-4b59a60017a6/my_recipe.tgz"
   etag = "28f3d78c8cceca2083d7d3090d96bbb7"
   type = "s3"
   ```

  If successful, create a variable for the IMS recipe `id` in the returned data.

   ```bash
   IMS_RECIPE_ID=2233c82a-5081-4f67-bec4-4b59a60017a6
   ```

### Submit the Kubernetes image create job

1. (`ncn-mw#`) Create an IMS job record and start the image creation job.

   After building an image, IMS will automatically upload any build artifacts \(root file system, kernel and `initrd`\)
   to the artifact repository, and associate them with IMS. IMS is not able to dynamically determine the Linux kernel
   and `initrd` to look for because the file name for these vary depending upon Linux distribution, Linux version,
   `dracut` configuration, and more. Thus, the user must pass the name of the kernel and `initrd` that IMS will look for
   in the resultant image root's `/boot` directory.

   Use the following table to help determine the default kernel and `initrd` file names to specify when submitting the
   job to customize an image. These are just default names. Please consult with the site administrator to determine if
   these names have been changed for a given image or recipe.

   | Recipe                          | Recipe Name                                    | Kernel File Name | `initrd` File Name |
   |---------------------------------|------------------------------------------------|------------------|--------------------|
   | SLES 15 SP5 `x86_64` Barebones  | `cray-sles15sp3-barebones`                     | `vmlinuz`        | `initrd`           |
   | SLES 15 SP5 `aarch64` Barebones | `cray-sles15sp3-barebones`                     | `Image`          | `initrd`           |
   | COS                             | `cray-shasta-compute-sles15sp5.x86_64-1.4.66`  | `vmlinuz`        | `initrd`           |
   | COS                             | `cray-shasta-compute-sles15sp5.aarch64-1.4.66` | `Image`          | `initrd`           |

   ```bash
    cray ims jobs create \
     --job-type create \
     --image-root-archive-name cray-sles15-barebones \
     --artifact-id $IMS_RECIPE_ID \
     --public-key-id $IMS_PUBLIC_KEY_ID \
     --enable-debug False
   ```

   Example output:

   ```toml
   status = "creating"
   enable_debug = false
   kernel_file_name = "vmlinuz"
   artifact_id = "2233c82a-5081-4f67-bec4-4b59a60017a6"
   build_env_size = 10
   job_type = "create"
   kubernetes_service = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-service"
   kubernetes_job = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-create"
   id = "ad5163d2-398d-4e93-94f0-2f439f114fe7"
   image_root_archive_name = "cray-sles15-barebones"
   initrd_file_name = "initrd"
   arch = "x86_64"
   require_dkms = false
   created = "2018-11-21T18:22:53.409405+00:00"
   public_key_id = "a252ff6f-c087-4093-a305-122b41824a3e"
   kubernetes_configmap = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-configmap"
   ```

   If successful, create variables for the IMS job `id` and `kubernetes_job` values in the returned data.

   ```bash
   IMS_JOB_ID=ad5163d2-398d-4e93-94f0-2f439f114fe7
   IMS_KUBERNETES_JOB=cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-create
   ```

1. (`ncn-mw#`) Describe the image create job.

    ```bash
    kubectl -n ims describe job $IMS_KUBERNETES_JOB
    ```

   Example output:

    ```text
    Name: ims-myimage-create
    Namespace: default

    [...]

    Events:
    Type Reason Age From Message
    ---- ------ ---- ---- -------
    Normal SuccessfulCreate 4m job-controller Created pod: cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-create-lt69t
    ```

   If successful, create a variable for the pod name that was created above, displayed in the `Events` section.

    ```bash
    POD=cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-create-lt69t
    ```

1. (`ncn-mw#`) Watch the logs from the `fetch-recipe`, `wait-for-repos`, `build-ca-rpm`, `build-image`,
   and `buildenv-sidecar` containers to monitor the image creation process.

   Use `kubectl` and the returned pod name from the previous step to retrieve this information.

   The `fetch-recipe` container is responsible for fetching the recipe archive from S3 and uncompressing the recipe.

    ```bash
    kubectl -n ims logs -f $POD -c fetch-recipe
    ```

   Example output:

    ```text
    INFO:/scripts/fetch.py:IMS_JOB_ID=ad5163d2-398d-4e93-94f0-2f439f114fe7
    INFO:/scripts/fetch.py:Setting job status to 'fetching_recipe'.
    INFO:ims_python_helper:image_set_job_status: {{ims_job_id: ad5163d2-398d-4e93-94f0-2f439f114fe7, job_status: fetching_recipe}}
    INFO:ims_python_helper:PATCH https://api-gw-service-nmn.local/apis/ims/jobs/ad5163d2-398d-4e93-94f0-2f439f114fe7 status=fetching_recipe
    INFO:/scripts/fetch.py:Fetching recipe http://rgw.local:8080/ims/recipes/2233c82a-5081-4f67-bec4-4b59a60017a6/my_recipe.tgz?AWSAccessKeyId=GQZKV1HAM80ZFDZJFFS7&Expires=1586891507&Signature=GzRzuTWo3p5CoKHzT2mIuPQXLGM%3D
    INFO:/scripts/fetch.py:Saving file as '/mnt/recipe/recipe.tgz'
    INFO:/scripts/fetch.py:Verifying md5sum of the downloaded file.
    INFO:/scripts/fetch.py:Successfully verified the md5sum of the downloaded file.
    INFO:/scripts/fetch.py:Uncompressing recipe into /mnt/recipe
    INFO:/scripts/fetch.py:Deleting compressed recipe /mnt/recipe/recipe.tgz
    INFO:/scripts/fetch.py:Done
    ```

   The `wait-for-repos` container will ensure that any HTTP/HTTPS repositories referenced by the Kiwi-NG recipe can be
   accessed and are available. This helps ensure that the image will be built successfully. If 301 responses are
   returned instead of 200 responses, that does not indicate an error.

    ```bash
    kubectl -n ims logs -f $POD -c wait-for-repos
    ```

   Example output:

    ```text
    2019-05-17 09:53:47,381 - INFO    - __main__ - Recipe contains the following repos: ['http://api-gw-service-nmn.local/repositories/sle15-Module-Basesystem/', 'http://api-gw-service-nmn.local/repositories/sle15-Product-SLES/', 'http://api-gw-service-nmn.local/repositories/cray-sle15']
    2019-05-17 09:53:47,381 - INFO    - __main__ - Attempting to get http://api-gw-service-nmn.local/repositories/sle15-Module-Basesystem/repodata/repomd.xml
    2019-05-17 09:53:47,404 - INFO    - __main__ - 200 response getting http://api-gw-service-nmn.local/repositories/sle15-Module-Basesystem/repodata/repomd.xml
    2019-05-17 09:53:47,404 - INFO    - __main__ - Attempting to get http://api-gw-service-nmn.local/repositories/sle15-Product-SLES/repodata/repomd.xml
    2019-05-17 09:53:47,431 - INFO    - __main__ - 200 response getting http://api-gw-service-nmn.local/repositories/sle15-Product-SLES/repodata/repomd.xml
    2019-05-17 09:53:47,431 - INFO    - __main__ - Attempting to get http://api-gw-service-nmn.local/repositories/cray-sle15/repodata/repomd.xml
    2019-05-17 09:53:47,458 - INFO    - __main__ - 200 response getting http://api-gw-service-nmn.local/repositories/cray-sle15/repodata/repomd.xml
    ```

   The `build-ca-rpm` container creates an RPM with the private root CA certificate for the system. This RPM is
   installed automatically by Kiwi-NG to ensure that Kiwi can securely talk to the Nexus repositories when building the
   image root.

    ```bash
    kubectl -n ims logs -f $POD -c build-ca-rpm
    ```

   Example output:

    ```text
    cray_ca_cert-1.0.0/
    cray_ca_cert-1.0.0/etc/
    cray_ca_cert-1.0.0/etc/cray/
    cray_ca_cert-1.0.0/etc/cray/ca/
    cray_ca_cert-1.0.0/etc/cray/ca/certificate_authority.crt
    Executing(%prep): /bin/sh -e /var/tmp/rpm-tmp.pgDBLk
    + umask 022
    + cd /root/rpmbuild/BUILD
    + cd /root/rpmbuild/BUILD
    + rm -rf cray_ca_cert-1.0.0
    + /bin/gzip -dc /root/rpmbuild/SOURCES/cray_ca_cert-1.0.0.tar.gz
    + /bin/tar -xof -
    + STATUS=0
    + '[' 0 -ne 0 ]
    + cd cray_ca_cert-1.0.0
    + /bin/chmod -Rf a+rX,u+w,g-w,o-w .
    + exit 0
    Executing(%build): /bin/sh -e /var/tmp/rpm-tmp.gILKaJ
    + umask 022
    + cd /root/rpmbuild/BUILD
    + cd cray_ca_cert-1.0.0
    + exit 0
    Executing(%install): /bin/sh -e /var/tmp/rpm-tmp.PGhobB
    + umask 022
    + cd /root/rpmbuild/BUILD
    + cd cray_ca_cert-1.0.0
    + install -d /root/rpmbuild/BUILDROOT/cray_ca_cert-1.0.0-1.x86_64/usr/share/pki/trust/anchors
    + install -m 644 /etc/cray/ca/certificate_authority.crt /root/rpmbuild/BUILDROOT/cray_ca_cert-1.0.0-1.x86_64/usr/share/pki/trust/anchors/cray_certificate_authority.crt
    + /usr/lib/rpm/brp-compress
    + /usr/lib/rpm/brp-strip /usr/bin/strip
    + /usr/lib/rpm/brp-strip-static-archive /usr/bin/strip
    find: file: No such file or directory
    + /usr/lib/rpm/brp-strip-comment-note /usr/bin/strip /usr/bin/objdump
    Processing files: cray_ca_cert-1.0.0-1.x86_64
    Provides: cray_ca_cert = 1.0.0-1 cray_ca_cert(x86-64) = 1.0.0-1
    Requires(interp): /bin/sh
    Requires(rpmlib): rpmlib(CompressedFileNames) <= 3.0.4-1 rpmlib(PayloadFilesHavePrefix) <= 4.0-1
    Requires(post): /bin/sh
    Checking for unpackaged file(s): /usr/lib/rpm/check-files /root/rpmbuild/BUILDROOT/cray_ca_cert-1.0.0-1.x86_64
    Wrote: /root/rpmbuild/RPMS/x86_64/cray_ca_cert-1.0.0-1.x86_64.rpm
    Executing(%clean): /bin/sh -e /var/tmp/rpm-tmp.jHaFMC
    + umask 022
    + cd /root/rpmbuild/BUILD
    + cd cray_ca_cert-1.0.0
    + exit 0
    ```

   The `build-image` container builds the recipe using the Kiwi-NG tool.

    ```bash
    kubectl -n ims logs -f $POD -c build-image
    ```

   Example output:

    ```text
    + RECIPE_ROOT_PARENT=/mnt/recipe
    + IMAGE_ROOT_PARENT=/mnt/image
    + PARAMETER_FILE_BUILD_FAILED=/mnt/image/build_failed
    + PARAMETER_FILE_KIWI_LOGFILE=/mnt/image/kiwi.log

    [...]

    + kiwi-ng --logfile=/mnt/image/kiwi.log --type tbz system build --description /mnt/recipe --target /mnt/image
    [ INFO    ]: 16:14:31 | Loading XML description
    [ INFO    ]: 16:14:31 | --> loaded /mnt/recipe/config.xml
    [ INFO    ]: 16:14:31 | --> Selected build type: tbz
    [ INFO    ]: 16:14:31 | Preparing new root system
    [ INFO    ]: 16:14:31 | Setup root directory: /mnt/image/build/image-root
    [ INFO    ]: 16:14:31 | Setting up repository http://api-gw-service-nmn.local/repositories/sle15-Module-Basesystem/
    [ INFO    ]: 16:14:31 | --> Type: rpm-md
    [ INFO    ]: 16:14:31 | --> Translated: http://api-gw-service-nmn.local/repositories/sle15-Module-Basesystem/
    [ INFO    ]: 16:14:31 | --> Alias: SLES15_Module_Basesystem
    [ INFO    ]: 16:14:32 | Setting up repository http://api-gw-service-nmn.local/repositories/sle15-Product-SLES/
    [ INFO    ]: 16:14:32 | --> Type: rpm-md
    [ INFO    ]: 16:14:32 | --> Translated: http://api-gw-service-nmn.local/repositories/sle15-Product-SLES/
    [ INFO    ]: 16:14:32 | --> Alias: SLES15_Product_SLES
    [ INFO    ]: 16:14:32 | Setting up repository http://api-gw-service-nmn.local/repositories/cray-sle15
    [ INFO    ]: 16:14:32 | --> Type: rpm-md
    [ INFO    ]: 16:14:32 | --> Translated: http://api-gw-service-nmn.local/repositories/cray-sle15
    [ INFO    ]: 16:14:32 | --> Alias: DST_built_rpms

    [...]

    [ INFO    ]: 16:19:19 | Calling images.sh script
    [ INFO    ]: 16:19:55 | Creating system image
    [ INFO    ]: 16:19:55 | Creating XZ compressed tar archive
    [ INFO    ]: 16:21:31 | --> Creating archive checksum
    [ INFO    ]: 16:21:51 | Export rpm packages metadata
    [ INFO    ]: 16:21:51 | Export rpm verification metadata
    [ INFO    ]: 16:22:09 | Result files:
    [ INFO    ]: 16:22:09 | --> image_packages: /mnt/image/cray-sles15-barebones.x86_64-1.0.1.packages
    [ INFO    ]: 16:22:09 | --> image_verified: /mnt/image/cray-sles15-barebones.x86_64-1.0.1.verified
    [ INFO    ]: 16:22:09 | --> root_archive: /mnt/image/cray-sles15-barebones.x86_64-1.0.1.tar.xz
    [ INFO    ]: 16:22:09 | --> root_archive_md5: /mnt/image/cray-sles15-barebones.x86_64-1.0.1.md5
    + rc=0
    + '[' 0 -ne 0 ']'
    + exit 0
    ```

   The `buildenv-sidecar` container determines if the Kiwi-NG build was successful or not.

* If the Kiwi-NG build completed successfully, the image root, kernel, and `initrd` artifacts are uploaded to the
  artifact repository.
* If the Kiwi-NG build failed to complete successfully, an optional SSH debug shell is enabled so the image build can be
  debugged.

```bash
kubectl -n ims logs -f $POD -c buildenv-sidecar
```

Example output:

```text
Not running user shell for successful create action
Copying SMS CA Public Certificate to target image root
+ IMAGE_ROOT_PARENT=/mnt/image
+ IMAGE_ROOT_DIR=/mnt/image/build/image-root
+ KERNEL_FILENAME=vmlinuz
+ INITRD_FILENAME=initrd
+ IMAGE_ROOT_ARCHIVE_NAME=sles15_barebones_image
+ echo Copying SMS CA Public Certificate to target image root
+ mkdir -p /mnt/image/build/image-root/etc/cray
+ cp -r /etc/cray/ca /mnt/image/build/image-root/etc/cray/
+ mksquashfs /mnt/image/build/image-root /mnt/image/sles15_barebones_image.sqsh
Parallel mksquashfs: Using 4 processors
Creating 4.0 filesystem on /mnt/image/sles15_barebones_image.sqsh, block size 131072.
[===========================================================\] 26886/26886 100%

Exportable Squashfs 4.0 filesystem, gzip compressed, data block size 131072
    compressed data, compressed metadata, compressed fragments, compressed xattrs

[...]

+ python -m ims_python_helper image upload_artifacts sles15_barebones_image 7de80ccc-1e7d-43a9-a6e4-02cad10bb60b \
        -v -r /mnt/image/sles15_barebones_image.sqsh -k /mnt/image/image-root/boot/vmlinuz
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
        "arch": "x86_64"
        "require_dkms": False
        "kernel_file_name": "vmlinuz",
        "kubernetes_configmap": "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-configmap",
        "kubernetes_job": "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-create",
        "kubernetes_service": "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-service",
        "public_key_id": "a252ff6f-c087-4093-a305-122b41824a3e",
        "resultant_image_id": "d88521c3-b339-43bc-afda-afdfda126388",
        "ssh_port": 0,
        "status": "creating"
    },
    "result": "success"
}

[...]
```

> **IMPORTANT:** The IMS image creation workflow automatically copies the NCN Certificate Authority's public certificate
> to `/etc/cray/ca/certificate_authority.crt` within
> the image root being built. This can be used to enable secure communications between the NCN and the client node.

If the image creation operation fails, the build artifacts will not be uploaded to S3. If `enable_debug` is set
to `true`, then the IMS creation job will enable a debug SSH shell that is accessible by one or more dynamic host names.
The user needs to know if they will SSH from inside or outside the Kubernetes cluster to determine which host name to
use. Typically, customers access the system from outside the Kubernetes cluster using the Customer Access Network
\(CAN\).

1. If no errors are observed, skip to the 1. [Verify that the new image was created correctly](#verify-creation) step.

   Otherwise, proceed to the following step to debug the failure.

1. (`ncn-mw#`) Use the `IMS_JOB_ID` to look up the ID of the newly created image.

   There may be multiple records returned. Ensure that the correct record is selected in the returned data.

    ```bash
    cray ims jobs describe $IMS_JOB_ID
    ```

   Example output:

    ```toml
    status = "waiting_on_user"
    enable_debug = false
    kernel_file_name = "vmlinuz"
    artifact_id = "4e78488d-4d92-4675-9d83-97adfc17cb19"
    build_env_size = 10
    job_type = "create"
    kubernetes_service = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-service"
    kubernetes_job = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-create"
    id = "ad5163d2-398d-4e93-94f0-2f439f114fe7"
    image_root_archive_name = "my_customized_image"
    initrd_file_name = "initrd"
    created = "2018-11-21T18:22:53.409405+00:00"
    kubernetes_namespace = "ims"
    arch = "x86_64"
    require_dkms = false
    public_key_id = "a252ff6f-c087-4093-a305-122b41824a3e"
    kubernetes_configmap = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-configmap"
    [[ssh_containers]]
    status = "pending"
    jail = false
    name = "debug"

    [ssh_containers.connection_info."cluster.local"]
    host = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-service.ims.svc.cluster.local"
    port = 22
    [ssh_containers.connection_info.customer_access]
    host = "ad5163d2-398d-4e93-94f0-2f439f114fe7.ims.cmn.shasta.cray.com" <<-- Note this host
    port = 22 <<-- Note this port
    ```

   If successful, create variables for the SSH connection information.

    ```bash
    IMS_SSH_HOST=ad5163d2-398d-4e93-94f0-2f439f114fe7.ims.cmn.shasta.cray.com
    IMS_SSH_PORT=22
    ```

1. (`ncn-mw#`) Connect to the IMS debug shell.

   To access the debug shell, SSH to the container using the private key that matches the public key used to create the
   IMS job.

   > **IMPORTANT:** The following command will not work when run on a node within the Kubernetes cluster.

    ```bash
    ssh -p IMS_SSH_PORT root@IMS_SSH_HOST
    ```

   Example output:

    ```text
    Last login: Tue Sep  4 18:06:27 2018 from gateway
    [root@POD ~]#
    ```

1. Investigate using the IMS debug shell.

1. Change to the `/mnt/image/` directory.

    ```bash
    [root@POD image]# cd /mnt/image/
    ```

1. Access the image root.

    ```bash
    [root@POD image]# chroot image-root/
    ```

1. Investigate inside the image debug shell.

1. Exit the image root.

    ```bash
    :/ # exit
    [root@POD image]#
    ```

1. Touch the `complete` file once investigations are complete.

    ```bash
    [root@POD image]# touch /mount/image/complete
    ```

#### Verify Creation

1. (`ncn-mw#`) Verify that the new image was created correctly.

    ```bash
    cray ims jobs describe $IMS_JOB_ID
    ```

   Example output:

    ```toml
    status = "success"
    enable_debug = false
    kernel_file_name = "vmlinuz"
    artifact_id = "2233c82a-5081-4f67-bec4-4b59a60017a6"
    build_env_size = 10
    job_type = "create"
    kubernetes_service = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-service"
    kubernetes_job = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-customize"
    id = "ad5163d2-398d-4e93-94f0-2f439f114fe7"
    image_root_archive_name = "sles15_barebones_image"
    resultant_image_id = "d88521c3-b339-43bc-afda-afdfda126388"
    initrd_file_name = "initrd"
    arch = "x86_64"
    require_dkms = false
    created = "2018-11-21T18:22:53.409405+00:00"
    kubernetes_namespace = "ims"
    public_key_id = "a252ff6f-c087-4093-a305-122b41824a3e"
    kubernetes_configmap = "cray-ims-ad5163d2-398d-4e93-94f0-2f439f114fe7-configmap"
    ```

   If successful, create a variable for the IMS `resultant_image_id`.

    ```bash
    IMS_RESULTANT_IMAGE_ID=d88521c3-b339-43bc-afda-afdfda126388
    ```

1. (`ncn-mw#`) Verify that the new IMS image record exists.

    ```bash
    cray ims images describe $IMS_RESULTANT_IMAGE_ID
    ```

   Example output:

    ```toml
    created = "2018-12-17T22:59:43.264129+00:00"
    id = "d88521c3-b339-43bc-afda-afdfda126388"
    name = "sles15_barebones_image"

    [link]
    path = "s3://boot-images/d88521c3-b339-43bc-afda-afdfda126388/manifest.json"
    etag = "180883770442235de747e9d69855f269"
    type = "s3"
    ```

### Clean up the creation environment

1. (`ncn-mw#`) Delete the IMS job record.

    ```bash
    cray ims jobs delete $IMS_JOB_ID
    ```

   Deleting the job record will delete the underlying Kubernetes job, service, and ConfigMap that were created when the
   job record was submitted.

Jobs created with the flag `--enable-debug true` will remain in a 'Running' state and continue to consume Kubernetes
resources until the job is manually completed, or deleted. If there are enough 'Running' IMS jobs on the system it may
not be possible to schedule more pods on worker nodes.

Images built by IMS contain only the packages and settings that are referenced in the Kiwi-NG recipe used to build the
image. The only exception is that IMS will dynamically install the system's root CA certificate to allow Zypper \(via
Kiwi-NG\) to talk securely with the required Nexus RPM repositories. Images that are intended to be used to boot a CN or
other node must be configured with DNS and other settings that enable the image to talk to vital services. A base level
of customization is provided by the default Ansible plays used by the Configuration Framework Service \(CFS\) to enable
DNS resolution; these plays are typically run against an image after it is built by IMS.

When customizing an image via [Customize an Image Root Using IMS](Customize_an_Image_Root_Using_IMS.md), once in the
image root using `chroot` \(or if using a \`jailed\`
environment\), the image will only have access to whatever configuration the image already contains. In order to talk to
services, including Nexus RPM repositories, the image root must first be configured with DNS and other settings. That
base level of customization is provided by the default Ansible plays used by CFS to enable DNS resolution.
