# Boot UANs

Boot UANs with an image so that they are ready for user logins.

## Prerequisites

UAN boot images and a BOS session template have been created. See [Create UAN Boot Images](../image_management/Create_UAN_Boot_Images.md).

## Procedure

1. (`ncn-mw#`) Create a BOS session to boot the UAN nodes.

    ```bash
    cray bos v2 sessions create --template-name uan-sessiontemplate-PRODUCT_VERSION \
            --operation reboot --format json | tee session.json
    ```

    Example output:

    ```json
    {
      "components": "",
      "limit": "",
      "name": "9fea7f3f-0a77-40b9-892d-37712de51d65",
      "operation": "boot",
      "stage": false,
      "status": {
        "end_time": null,
        "error": null,
        "start_time": "2022-08-22T14:44:27",
        "status": "pending"
      },
      "template_name": "cle-1.1.0"
    }
    ```

    The first attempt to reboot the UANs will most likely fail. The UAN boot may hang and the UAN console will look similar to the following:

    ```text
    2021-03-19 01:32:41 dracut-initqueue[420]: DVS: node map generated.
    2021-03-19 01:32:41 katlas: init_module: katlas loaded, currently disabled
    2021-03-19 01:32:41
    2021-03-19 01:32:41 DVS: Revision: kbuild Built: Mar 17 2021 @ 15:14:05 against LNet 2.12.4
    2021-03-19 01:32:41 DVS debugfs: Revision: kbuild Built: Mar 17 2021 @ 15:14:05 against LNet 2.12.4
    2021-03-19 01:32:41 dracut-initqueue[420]: DVS: loadDVS: successfully added 10 new nodes into map.
    2021-03-19 01:32:41 ed dvsproc module.
    2021-03-19 01:32:41 DVS: message size checks complete.
    2021-03-19 01:32:41 dracut-initqueuedvs_thread_generator: Watching pool DVS-IPC_msg (id 0)
    2021-03-19 01:32:41 [420]: DVS: loaded dvs module.
    2021-03-19 01:32:41 dracut-initqueue[420]: mount is: /opt/cray/cps-utils/bin/cpsmount.sh -a api-gw-service-nmn.local -t dvs -T 300 -i nmn0 -e 3116cf653e84d265cf8da94956f34d9e-181 s3://boot-images/763213c7-3d5f-4f2f-9d8a-ac6086583f43/rootfs /tmp/cps
    2021-03-19 01:32:41 dracut-initqueue[420]: 2021/03/19 01:31:01 cpsmount_helper Version: 1.0.0
    2021-03-19 01:32:47 dracut-initqueue[420]: 2021/03/19 01:31:07 Adding content: s3://boot-images/763213c7-3d5f-4f2f-9d8a-ac6086583f43/rootfs 3116cf653e84d265cf8da94956f34d9e-181 dvs
    2021-03-19 01:33:02 dracut-initqueue[420]: 2021/03/19 01:31:22 WARN: readyForMount=false type=dvs ready=0 total=2
    2021-03-19 01:33:18 dracut-initqueue[420]: 2021/03/19 01:31:38 WARN: readyForMount=false type=dvs ready=0 total=2
    2021-03-19 01:33:28 dracut-initqueue[420]: 2021/03/19 01:31:48 2 dvs servers [10.252.1.7 10.252.1.8]
    ```

    If this occurs, repeat the BOS command.

1. (`ncn-mw#`) Retrieve the BOS session name from the output of the `cray bos v2 session create` command in the previous step.

    ```bash
    BOS_SESSION=9fea7f3f-0a77-40b9-892d-37712de51d65
    ```

1. (`ncn-mw#`) List the CFS sessions.

    > **`NOTE`** Skip this step if CFS was not enabled in the boot session template used to boot the UANs.

    If CFS was enabled in the boot session template, then BOS will set configuration in CFS that will trigger a CFS session.

    In the following command, `pending` and `complete` are also valid statuses to filter on.

    ```bash
    cray cfs v3 sessions list --tags bos_session=$BOS_SESSION --status running --format json
    ```

1. Verify that the Day Zero patch was applied correctly during [Create UAN Boot Images](../image_management/Create_UAN_Boot_Images.md).

    > Skip this step if the patch has already been verified.

    1. (`ncn-mw#`) SSH into a newly booted UAN.

        ```bash
        ssh uan01-nmn
        ```

    1. (`uan01#`) Verify that the DVS RPM versions match what exists in the `1.4.0-p2/rpms` directory.

        ```bash
        rpm -qa | grep 'cray-dvs.*2.12' | sort
        ```

        Example output:

        ```text
        cray-dvs-compute-2.12_4.0.102-7.0.1.0_8.1__g30d29e7a.x86_64
        cray-dvs-devel-2.12_4.0.102-7.0.1.0_8.1__g30d29e7a.x86_64
        cray-dvs-kmp-cray_shasta_c-2.12_4.0.102_k4.12.14_197.78_9.1.58-7.0.1.0_8.1__g30d29e7a.x86_64
        ```

    1. (`uan01#`) Log out of the UAN.

        ```bash
        exit
        ```
