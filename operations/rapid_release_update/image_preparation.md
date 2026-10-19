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

2. After `prepare-images` completes, identify the image IDs and CFS configurations
   it created. You will need these for the storage and master node rollout steps.

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
               \"name\": \"master-secure-kubernetes-7.2.21-x86_64.squashfs\",
               \"preconfigured_image_id\": null,
               \"final_image_id\": \"d5c99503-096f-4279-a0a9-be4789a1bea5\",
               \"configuration\": \"management-26.3.1\",
               \"configuration_group_names\": [
                   \"Management_Master\"
               ]
           },
           {
               \"name\": \"storage-secure-storage-ceph-7.2.21-x86_64.squashfs\",
               \"preconfigured_image_id\": null,
               \"final_image_id\": \"7603a2ee-3732-4c60-9fe4-b289e48c717f\",
               \"configuration\": \"storage-26.3.1\",
               \"configuration_group_names\": [
                   \"Management_Storage\"
               ]
           },
           {
               \"name\": \"worker-secure-kubernetes-7.2.21-x86_64.squashfs\",
               \"preconfigured_image_id\": null,
               \"final_image_id\": \"43079045-952b-485a-96bc-a967e1c2dc88\",
               \"configuration\": \"management-26.3.1\",
               \"configuration_group_names\": [
                   \"Management_Worker\"
               ]
           }
       ]
   }"
   ```

3. Set variables for the images created

   Using the example output from the previous step, set the values for `MASTER_IMAGE_ID`, `STORAGE_IMAGE_ID`, and `WORKER_IMAGE_ID` with the `IMS` `final_image_id` in the configmap for each image type.

   ```bash
   export MASTER_IMAGE_ID=d5c99503-096f-4279-a0a9-be4789a1bea5
   export STORAGE_IMAGE_ID=7603a2ee-3732-4c60-9fe4-b289e48c717f
   export WORKER_IMAGE_ID=43079045-952b-485a-96bc-a967e1c2dc88
   ```

## Next steps

- Return to the
  [Install Rapid Release Update with IUF](installation_iuf.md)
  workflow to continue the install.