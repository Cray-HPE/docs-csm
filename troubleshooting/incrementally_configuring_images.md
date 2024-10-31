# Incrementally Configuring Images

When the [Install and Upgrade Framework (IUF)](../glossary.md#install-and-upgrade-framework-iuf) or
[System Admin Toolkit (SAT)](../glossary.md#system-admin-toolkit-sat) `bootprep` are failing to configure an image,
this procedure can be used to incrementally configure an image.
This avoids re-running the build and configuration steps that have succeeded, which would occur if IUF or SAT `bootprep` were re-run.

The following example assumes the user is creating a [compute node](../glossary.md#compute-node-cn) image, but
can be adapted for other image types.

- [Setting up](#setting-up)
- [Generating a partially configured image](#generating-a-partially-configured-image)
- [Restarting SAT and IUF](#restarting-sat-and-iuf)

## Setting up

1. (`ncn-mw#`) Find the path to the IUF logs printed by the `iuf` command. It will look like this:

   ```text
   2023-11-01T14:06:36.128255Z INFO All logs will be stored in /etc/cray/upgrade/csm/iuf/cos-products-20231031/log/20231101140636
   ```

   See `install.log` in this directory when subsequent steps reference the IUF logs.

1. (`ncn-mw#`) Find the `prepare-managed-images` SAT logs by looking for a line like the following in the IUF logs:

   ```text
   2023-11-01T14:58:22.874482Z INFO [prepare-managed-images] END sat-bootprep-run [Failed]
   2023-11-01T14:58:22.874567Z DBG  [prepare-managed-images] LOG FILE FOR sat-bootprep-run: argo/cos-products-20231031-gdm63-prepare-images-2rkds/cos-products-20231031-gdm63-prepare-images-2rkds-sat-wrapper-2664865581/main.log
   ```

   The string starting with `argo/` is the key within the `config-data` bucket of the [S3](../glossary.md#simple-storage-service-s3) object
   which contains the log output from `sat bootprep`. Save this S3 key to an environment variable:

   ```bash
   LOGS_S3_KEY="argo/cos-products-20231031-gdm63-prepare-images-2rkds/cos-products-20231031-gdm63-prepare-images-2rkds-sat-wrapper-2664865581/main.log"
   ```

1. (`ncn-mw#`) Download the workflow SAT logs.

   ```bash
   cray artifacts get config-data "$LOGS_S3_KEY" main.log
   ```

1. (`ncn-mw#`) Set `BASE_IMAGE_ID`.

   1. View the log and look for a line that includes `Creation of image`.

      ```text
      INFO: Creation of image ssi-uss-1.0.0-32-csm-1.5.x86_64-csm-1.5.0.beta37-10 succeeded: ID f5374c4c-8c5a-4b79-a5e5-aef778ed36cd
      ```

   1. Set `BASE_IMAGE_ID` to the value of the image ID.

      It is important that this value is set to the image ID and not the image name.

      ```bash
      BASE_IMAGE_ID="f5374c4c-8c5a-4b79-a5e5-aef778ed36cd"
      ```

   SAT may have generated multiple images, in which case it is up to the user to determine which is the desired base image.

1. (`ncn-mw#`) Find the `update-managed-cfs-config` SAT logs by looking for a line like the following in the IUF logs:

   ```text
   2023-11-03T17:31:50.121175Z DBG  [update-managed-cfs-config] LOG FILE FOR sat-bootprep-run: argo/cos-products-20231031-sm5qz-update-cfs-config-hh522/cos-products-20231031-sm5qz-update-cfs-config-hh522-sat-wrapper-1367779725/main.log
   ```

   Note that this may have been logged in a different session within the IUF activity, so a
   different IUF log directory may need to be examined.

   The string starting with `argo/` is the key within the `config-data` bucket of the S3 object
   which contains the log output from `sat bootprep`. Save this S3 key to an environment variable:

   ```bash
   LOGS_S3_KEY="argo/cos-products-20231031-gdm63-prepare-images-2rkds/cos-products-20231031-gdm63-prepare-images-2rkds-sat-wrapper-2664865581/main.log"
   ```

1. (`ncn-mw#`) Download the workflow SAT logs.

   ```bash
   cray artifacts get config-data "$LOGS_S3_KEY" main.log
   ```

1. (`ncn-mw#`) Set `CFS_CONFIGURATION_NAME`.

   1. View the log and look at the end for the list of configurations that have been created.

      ```json
      {
          "configurations": [
              {
                  "name": "ssi-compute-23.11.0-SSI-csm-1.5.0.beta37-10"
              }
          ]
      }
      ```

   1. Set `CFS_CONFIGURATION_NAME` to the name of the [Configuration Framework Service (CFS)](../glossary.md#configuration-framework-service-cfs) configuration.

      ```bash
      CFS_CONFIGURATION_NAME="ssi-compute-23.11.0-SSI-csm-1.5.0.beta37-10"
      ```

   SAT may have generated multiple configurations, in which case it is up to the user to determine which is the desired configuration.
   However, if the default SAT `bootprep` file is being used, then the configuration name should include `compute`.

1. (`ncn-mw#`) Set `SESSION_NAME`.

   This can be set to any value, but the following example steps assume this variable is set.

   ```bash
   SESSION_NAME="example-partial-image-configuration"
   ```

1. (Optional) Find the failed configuration layer.

   If configuration of the image failed somewhere beyond the first configuration layer, and there is some confidence that the successful layers will continue to be successful,
   then it is possible to save time by generating the first partial image with all of the successful layers.
   Find the index of the of the failed configuration either by counting the number of successful configuration layers in the logs, or by comparing the name of the failed layer to the output of `cray cfs v3 configurations describe $CFS_CONFIGURATION_NAME`.
   Indices for the configuration layers start at 0.

## Generating a partially configured image

1. (`ncn-mw#`) Set the configuration limit.

   If this is the first CFS run of this procedure, this should be `0` to apply only the first layer.

   ```bash
   CONFIGURATION_LIMIT=0
   ```

   Optionally, this can instead be set to a comma-separated list of numbers starting at `0` when trying to apply all layers up to the failed layer. For example:

      ```bash
   CONFIGURATION_LIMIT=0,1,2
   ```

   If this is not the first CFS run in this procedure, then set this value to the next layer to be applied.

   ```bash
   CONFIGURATION_LIMIT=<previous CONFIGURATION limit +1>
   ```

1. (`ncn-mw#`) Generate a partially configured image.

    The following command will generate an image that only adds the configuration layers specified in the `CONFIGURATION_LIMIT`.

   ```bash
   cray cfs v3 sessions create --name $SESSION_NAME --configuration-name $CFS_CONFIGURATION_NAME --target-definition image --target-group Compute $BASE_IMAGE_ID --configuration-limit $CONFIGURATION_LIMIT
   ```

   If this is the last layer of the configuration, it is optionally possible to specify the name of the resulting image by adding `--target-image-map`.

   ```bash
   cray cfs v3 sessions create --name $SESSION_NAME --configuration-name $CFS_CONFIGURATION_NAME --target-definition image --target-group Compute $BASE_IMAGE_ID --configuration-limit $CONFIGURATION_LIMIT --target-image-map $BASE_IMAGE_ID <desired image name>
   ```

1. (`ncn-mw#`) Monitor CFS and retrieve the image ID of the partially generated image.

    Monitor the CFS session with the following command until the status is complete. If `succeeded` is true, then move on to the next step; otherwise, debug the failure and re-run the session as necessary.

   ```bash
   cray cfs sessions describe $SESSION_NAME --format json | jq .status.session
   ```

   Example output:

   ```json
   {
     "completionTime": "2023-11-01T19:55:10",
     "job": "cfs-712dee37-2b80-498c-867c-42753716cad6",
     "startTime": "2023-11-01T19:53:09",
     "status": "complete",
     "succeeded": "true"
   }
   ```

1. When the session is complete, get the resulting [Image Management Service (IMS)](../glossary.md#image-management-service-ims) image ID.

   ```bash
   cray cfs v3 sessions describe $SESSION_NAME --format json | jq .status.artifacts
   ```

   Example output:

   ```json
   [
     {
       "image_id": "<IMS IMAGE ID>",
       "result_id": "<RESULTANT IMS IMAGE ID>",
       "type": "ims_customized_image"
     }
   ]
   ```

1. (`ncn-mw#`) Update `BASE_IMAGE_ID`.

   Set `BASE_IMAGE_ID` equal to the `result_id` from the last CFS session.

   ```bash
   BASE_IMAGE_ID=<RESULTANT IMS IMAGE ID>
   ```

1. (`ncn-mw#`) Cleanup the CFS session.

   Cleanup the CFS session to prevent naming conflicts with configuration runs for future layers.

   ```bash
   cray cfs v3 sessions delete $SESSION_NAME
   ```

1. Repeat these steps for each layer.

   If this was not the last layer in the configuration, return to [the beginning of this section](#generating-a-partially-configured-image).
   If this was the last layer in the configuration, move on to the next section.

## Restarting SAT and IUF

1. Create a copy of the original SAT `bootprep` file.

   Instructions for this procedure can be found in the [Stage 0](../upgrade/Stage_0_Prerequisites.md#option-2-upgrade-of-csm-on-system-with-additional-products) upgrade documentation.

1. Edit the [Boot Orchestration Service (BOS)](../glossary.md#boot-orchestration-service-bos) session templates in the SAT `bootprep` file.

   For any BOS templates in the `session_templates` section that will now be booting with the image that was just created, replace `image_ref` with `ims` to specify an image from IMS by its ID:

   Before:

   ```yaml
   session_templates:
   - name: example-session-template
     image:
       image_ref: example-image
   ```

   After:

   ```yaml
   session_templates:
   - name: example-session-template
     image:
       ims:
         id: <image id from the final CFS run>
   ```

1. Remove image generation and configuration from the SAT `bootprep` file.

   In the `images` section of the file, remove configuration of the already created image.

   Example image configuration section that can be removed:

   ```yaml
   - name: "compute-{{base.name}}"
     ref_name: compute_image.aarch64
     base:
       image_ref: base_cos_image.aarch64
     configuration: "{{default.note}}compute-{{recipe.version}}{{default.suffix}}"
     configuration_group_names:
     - Compute
   ```

   Optionally remove the creation of the base image.
   This can save a lot of time in the IUF/SAT run, but requires more changes to the `bootprep` file to ensure that no other image is building off the base image.

   Example image creation section that can be removed:

   ```yaml
   - name: "{{default.note}}{{base.name}}{{default.suffix}}"
     ref_name: base_cos_image.aarch64
     base:
       product:
         name: cos
         type: recipe
         version: "{{cos.version}}"
         filter:
           arch: aarch64
   ```

   If the base image creation is removed, ensure that no other `images` or `session_templates` reference the base image.
   If they do share a base image, as is frequently the case with the `UAN` image and `Compute` image, then the images or templates must be updated to reference the image ID of the base image that
   was already created. The base image ID was stored in `BASE_IMAGE_ID` earlier in this procedure.

   Image customization section before:

   ```yaml
   - name: "uan-{{base.name}}"
     ref_name: uan_image.aarch64
     base:
       image_ref: base_cos_image.aarch64
     configuration: "{{default.note}}uan-{{recipe.version}}{{default.suffix}}"
     configuration_group_names:
     - Application
     - Application_UAN
   ```

   Image customization section after:

   ```yaml
   - name: "uan-{{base.name}}"
     ref_name: uan_image.aarch64
     base:
       ims:
         id: <base image id>
         type: image
     configuration: "{{default.note}}uan-{{recipe.version}}{{default.suffix}}"
     configuration_group_names:
     - Application
     - Application_UAN
   ```

   See the previous step for updating any templates.

1. Restart IUF.

   IUF can now be restarted at the `prepare-images` step using the new `bootprep` file.
   For more information, see [Image Preparation](../operations/iuf/workflows/image_preparation.md)
