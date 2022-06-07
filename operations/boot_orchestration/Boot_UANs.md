# Boot UANs

Boot UANs with an image so that they are ready for user logins.

## Prerequisites

UAN boot images and a BOS session template have been created. See [Create UAN Boot Images](../image_management/Create_UAN_Boot_Images.md).

## Procedure

1. Create a BOS session to boot the UAN nodes.

    ```bash
    ncn# cray bos session create --template-uuid uan-sessiontemplate-PRODUCT_VERSION \
            --operation reboot --format json | tee session.json
    ```

    Example output:

    ```json
    {
     "links": [
       {
         "href": "/v1/session/89680d0a-3a6b-4569-a1a1-e275b71fce7d",
         "jobId": "boa-89680d0a-3a6b-4569-a1a1-e275b71fce7d",
         "rel": "session",
         "type": "GET"
       },
       {
         "href": "/v1/session/89680d0a-3a6b-4569-a1a1-e275b71fce7d/status",
         "rel": "status",
         "type": "GET"
       }
     ],
     "operation": "reboot",
     "templateUuid": "uan-sessiontemplate-PRODUCT_VERSION"
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

1. Retrieve the BOS session ID from the output of the `cray bos session create` command in the previous step.

    ```bash
    ncn# BOS_SESSION=$(jq -r '.links[] | select(.rel=="session") | .href' session.json | cut -d '/' -f4) ; echo $BOS_SESSION
    ```

    Example output:

    ```text
    89680d0a-3a6b-4569-a1a1-e275b71fce7d
    ```

1. Retrieve the Boot Orchestration Agent \(BOA\) Kubernetes job name for the BOS session.

    ```bash
    ncn# BOA_JOB_NAME=$(cray bos session describe $BOS_SESSION --format json | jq -r .boa_job_name)
    ```

1. Retrieve the Kubernetes pod name for the BOA assigned to run this session.

    ```bash
    ncn# BOA_POD=$(kubectl get pods -n services -l job-name=$BOA_JOB_NAME --no-headers -o custom-columns=":metadata.name")
    ```

1. View the logs for the BOA to track session progress.

    ```bash
    ncn# kubectl logs -f -n services $BOA_POD -c boa
    ```

1. List the CFS sessions started by the BOA.

    > Skip this step if CFS was not enabled in the boot session template used to boot the UANs.

    If CFS was enabled in the boot session template, the BOA will initiate a CFS session.

    In the following command, `pending` and `complete` are also valid statuses to filter on.

    ```bash
    ncn# cray cfs sessions list --tags bos_session=$BOS_SESSION --status running --format json
    ```

1. Verify that the Day Zero patch was applied correctly during [Create UAN Boot Images](../image_management/Create_UAN_Boot_Images.md).

    > Skip this step if the patch has already been verified.

    1. SSH into a newly booted UAN.

        ```bash
        ncn# ssh uan01-nmn
        ```

    1. Verify that the DVS RPM versions match what exists in the `1.4.0-p2/rpms` directory.

        ```bash
        uan01# rpm -qa | grep 'cray-dvs.*2.12' | sort
        ```

        Example output:

        ```text
        cray-dvs-compute-2.12_4.0.102-7.0.1.0_8.1__g30d29e7a.x86_64
        cray-dvs-devel-2.12_4.0.102-7.0.1.0_8.1__g30d29e7a.x86_64
        cray-dvs-kmp-cray_shasta_c-2.12_4.0.102_k4.12.14_197.78_9.1.58-7.0.1.0_8.1__g30d29e7a.x86_64
        ```

    1. Log out of the UAN.

        ```bash
        uan01# exit
        ```
