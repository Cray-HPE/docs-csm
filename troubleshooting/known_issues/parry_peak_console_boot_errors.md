# HPE Cray `EX255a` Boot Issue with Console Parameter

- [Description](#description)
- [Workaround](#workaround)

## Description

  `HPE Cray EX255a` hardware has an issue in BIOS versions 1.1.0 and earlier that causes boots to stall when configured to use the default kernel serial port `ttyS0` which is provided in the compute image created during installation of CSM 1.5.2.

## Workaround

1. (`ncn-mw#`) Follow the steps for [customizing](../../operations/image_management/Customize_an_Image_Root_Using_IMS.md) an image to be used for booting `HPE Cray EX255a` hardware.

    ```bash
    cray ims jobs create --public-key-id $PK_ID --job-type customize --artifact-id $IMAGE_ID --image-root-archive-name $NEW_IMAGE_NAME
    ```

    Example output:

    ```toml
    artifact_id = "fdc16942-ba1d-49b5-a4a2-0c7bbce8bb68"
    job_type = "customize"
    image_root_archive_name = "uss-compute-jsmit-test"
    status = "creating"
    require_dkms = false
    job_mem_size = 8
    public_key_id = "<public_key_id>"
    remote_build_node = ""
    arch = "x86_64"
    enable_debug = false
    initrd_file_name = "initrd"
    build_env_size = 30
    created = "2024-07-30T18:01:24.961857+00:00"
    kubernetes_service = "cray-ims-066423ff-2704-4e3f-9df4-82eb210d776b-service"
    kubernetes_job = "cray-ims-066423ff-2704-4e3f-9df4-82eb210d776b-customize"
    kubernetes_namespace = "ims"
    kernel_parameters_file_name = "kernel-parameters"
    kernel_file_name = "vmlinuz"
    id = "066423ff-2704-4e3f-9df4-82eb210d776b"
    kubernetes_configmap = "cray-ims-066423ff-2704-4e3f-9df4-82eb210d776b-configmap"
    kubernetes_pvc = "cray-ims-066423ff-2704-4e3f-9df4-82eb210d776b-job-claim"
    [[ssh_containers]]
    status = "pending"
    name = "customize"
    jail = false

    [ssh_containers.connection_info.customer_access]
    port = 22
    host = "066423ff-2704-4e3f-9df4-82eb210d776b.ims.cmn.vidar.hpc.amslabs.hpecorp.net"
    [ssh_containers.connection_info."cluster.local"]
    port = 22
    host = "cray-ims-066423ff-2704-4e3f-9df4-82eb210d776b-service.ims.svc.cluster.local"
    ```

1. (`ncn-mw#`) SSH into the customization pod.

   ```bash
   ssh 066423ff-2704-4e3f-9df4-82eb210d776b.ims.cmn.vidar.hpc.amslabs.hpecorp.net
   ```

1. Navigate to the boot directory of the image to be customized.

   ```bash
   cd /mnt/image/image-root/boot
   ```

1. Edit the kernel-parameters file and change `console=ttyS0,115200` to `console=ttyS1,115200`.

1. Finish the customization session.

   ```bash
   touch /mnt/image/complete
   ```

1. Once the image has finished customization and has been bundled and uploaded to `s3`, create or copy a BOS [template](../../operations/boot_orchestration/Session_Templates.md) that references the new image id and `etag`.
   Optionally, you can add a `node_list` within the template to specifically target `HPE Cray EX255a` nodes, or you can use the BOS limit option when creating a session to specify only `HPE Cray EX255a` xnames.
   Another option available would be to create a custom group for `HPE Cray EX255a` hardware using HSM and to reference that group using the `node_groups` feature within your BOS template.
   This will allow for specifying the hardware without referencing individual nodes each time in the session template. Once this is complete, `HPE Cray EX255a` hardware should successfully boot using the BOS template created previously.
