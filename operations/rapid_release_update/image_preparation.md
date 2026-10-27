# Prepare Images

Prepare the new images only after product delivery and CFS configuration have
succeeded. This stage rebuilds NCN images (master, worker, storage) using `sat bootprep`.
The images are built using the CFS configurations created during
`update-cfs-config`, which include the `csm-security` layer with security
patches.

**Note:** Building new management node images will take about an hour.

1. (`ncn-m001#`) Run the `prepare-images` stage.

   ```bash
   iuf -a ${ACTIVITY_NAME} -m ${MEDIA_DIR} run \
     -bm ${BOOTPREP_FILE} -sv ${SITE_VARS} -rv ${RECIPE_VARS} \
     -r prepare-images
   ```

2. After `prepare-images` completes, identify the image IDs and CFS configurations it created.
   You will need these for the storage and master node rollout steps.

   The artifacts created by the prepare-images stage can found by examining the output from iuf run or by examining a Kubernetes ConfigMap associated with the
   IUF activity specified when executing the prepare-images stage. The following examples show how to find the management node and managed node artifacts from the ConfigMap.

   (`ncn-mw#`) Examine the activity ConfigMap to identify the management node images and CFS configurations created by prepare-images.

   ```bash
   kubectl get configmaps -n argo "${ACTIVITY_NAME}" -o jsonpath='{.data.iuf_activity}' \
        | jq '.operation_outputs.stage_params["prepare-images"]["prepare-management-images"]["sat-bootprep-run"].script_stdout' \
        | xargs -0 echo -e
   ```

   Example output:

   ```bash
   "{
        \"images\": [
            {
                \"name\": \"worker-secure-kubernetes-7.2.18-x86_64.squashfs-rru-26.10.01\",
                \"preconfigured_image_id\": null,
                \"final_image_id\": \"d0de60c0-e939-46fb-b10b-99ddaccec273\",
                \"configuration\": \"management-26.3.0-rru-26.10.01\",
                \"configuration_group_names\": [
                    \"Management_Worker\"
                ]
            },
            {
                \"name\": \"storage-secure-storage-ceph-7.2.18-x86_64.squashfs-rru-26.10.01\",
                \"preconfigured_image_id\": null,
                \"final_image_id\": \"8eb5dc4d-8041-47e0-aa4c-542e10516c1e\",
                \"configuration\": \"storage-26.3.0-rru-26.10.01\",
                \"configuration_group_names\": [
                    \"Management_Storage\"
                ]
            },
            {
                \"name\": \"master-secure-kubernetes-7.2.18-x86_64.squashfs-rru-26.10.01\",
                \"preconfigured_image_id\": null,
                \"final_image_id\": \"a70de793-859a-44e0-8d53-f27893097158\",
                \"configuration\": \"management-26.3.0-rru-26.10.01\",
                \"configuration_group_names\": [
                    \"Management_Master\"
                ]
            }
        ]
   }"
   ```

3. Set variables for the images created

   Using the example output from the previous step, set the values for `MASTER_IMAGE_ID`, `STORAGE_IMAGE_ID`, and `WORKER_IMAGE_ID` with the `IMS` `final_image_id` in the configmap for each image type.

   ```bash
   export MASTER_IMAGE_ID=a70de793-859a-44e0-8d53-f27893097158
   export STORAGE_IMAGE_ID=8eb5dc4d-8041-47e0-aa4c-542e10516c1e
   export WORKER_IMAGE_ID=d0de60c0-e939-46fb-b10b-99ddaccec273
   ```

4. Set variables for the CFS configurations created

   Using the example output from the previous step, set the values for `MASTER_CFG_ID`, `STORAGE_CFG_ID`, and `WORKER_CFG_ID` with the `IMS` `configuration` in the configmap for each image type.

   ```bash
   export MASTER_CFG_ID=management-26.3.0-rru-26.10.01
   export STORAGE_CFG_ID=storage-26.3.0-rru-26.10.01
   export WORKER_CFG_ID=management-26.3.0-rru-26.10.01
   ```

## Next steps

- Return to the
  [Deploying Rapid Release Update with IUF](installation_iuf.md)
  workflow to continue the install.
