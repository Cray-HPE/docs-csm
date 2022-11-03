# Enable `ncsd` on UANs

Configure User Access Nodes (UANs) to start the `ncsd` service at boot time.

The `nscd` service is not currently enabled by default and `systemd` does not start it at boot time. There are two ways to start `nscd` on UAN nodes:
manually starting the service or enabling the service in the UAN image. While restarting `nscd` manually has to be performed each time the UAN is rebooted,
enabling `nscd` in the image only has to be done once. Then all UANs that use the image will have `nscd` started automatically on boot.

- [Start `ncsd` manually on each UAN](#start-ncsd-manually-on-each-uan)
- [Enable `ncsd` in the UAN image](#enable-ncsd-in-the-uan-image)

## Start `ncsd` manually on each UAN

1. Log into a UAN.

1. (`uan#`) Start `ncsd` using `systemctl`.

    ```bash
    systemctl start nscd
    ```

1. Repeat the previous two steps for every UAN.

## Enable `ncsd` in the UAN image

1. Determine the ID of the image used by the UAN.

    This ID can be found in the BOS session template used to boot the UAN:

    ```json
    {
       "boot_sets": {
         "uan": {
           "boot_ordinal": 2,
           "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=340M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=nmn0:dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y quiet rd.neednet=1 rd.retry=10 rd.shell turbo_boost_limit=999 ifmap=net2:nmn0,lan0:hsn0,lan1:hsn1 spire_join_token=${SPIRE_JOIN_TOKEN}",
         "network": "nmn",
         "node_list": [
            "LIST_OF_APPLICATION_NODES"
         ],
         "path": "s3://boot-images/IMS_IMAGE_ID/manifest.json",
         "rootfs_provider": "cpss3",
         "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:nmn0",
         "type": "s3"
         }
       },
       "cfs": {
         "configuration": "uan-config-PRODUCT_VERSION"
       },
       "enable_cfs": true,
       "name": "uan-sessiontemplate-PRODUCT_VERSION"
    }
    ```

    The image ID is found in the `path` field inside the `boot_sets` object.

    1. Enable the `ncsd` service in the image.

        (`chroot#`) Use the procedure [Customize an Image Root Using IMS](../../image_management/Customize_an_Image_Root_Using_IMS.md) and run the following commands in the image `chroot`:

        ```bash
        systemctl enable nscd.service
        /tmp/images.sh
        ```

    1. Obtain the new resultant image ID from the previous step.

    1. Update the UAN BOS session template with the new image ID.

        See [Create UAN Boot Images](../../image_management/Create_UAN_Boot_Images.md) for instructions on updating the BOS session template.

    1. Reboot the UANs with the updated session template.

        See [Boot UANs](../../boot_orchestration/Boot_UANs.md).
