# Boot UANs

Boot UANs with an image so that they are ready for user logins.

## Prerequisites

UAN boot images and a BOS session template have been created. See [Image Preparation](../../operations/iuf/workflows/image_preparation.md).

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
      "template_name": "cle-1.1.0",
      "tenant": null
    }
    ```

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

1. (`ncn-mw#`) SSH into a newly booted UAN.

    ```bash
    ssh uan01-nmn
    ```

1. (`uan01#`) Log out of the UAN.

    ```bash
    exit
    ```
