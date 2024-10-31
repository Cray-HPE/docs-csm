# `prepare-images`

The `prepare-images` stage configures NCN management node images and builds and configures compute node, application
node, and GPU images. It also creates new BOS session templates corresponding to the new node and image content.
The `prepare-images` stage does not reboot nodes to the new images; however, that is done by
the `management-nodes-rollout` and `managed-nodes-rollout` stages.

The product content used to create the images is defined in `sat bootprep` input files. The `sat bootprep` input files
used can be specified by `-bc`, `-bm`, and/or `-bpcd` as described below. Variables within the `sat bootprep`
files can be substituted with values found in the recipe variables (`-rv`) and/or site variables (`-sv`) files.

`prepare-images` details are explained in the following sections:

- [Impact](#impact)
- [Input](#input)
    - [ARM images](#arm-images)
- [Artifacts created](#input)
    - [Management node artifacts](#management-node-artifacts)
    - [Managed node artifacts](#managed-node-artifacts)
- [Execution details](#execution-details)
- [Example](#example)

## Impact

The `prepare-images` stage does not change the running state of the system as it does not deploy the newly created
images; that is done by the `management-nodes-rollout` and `managed-nodes-rollout` stages.

## Input

The following arguments are most often used with the `prepare-images` stage. See `iuf -h` and `iuf run -h` for
additional arguments.

| Input                                         | `iuf` Argument                   | Description                                                                                           |
|-----------------------------------------------|----------------------------------|-------------------------------------------------------------------------------------------------------|
| Activity                                      | `-a ACTIVITY`                    | Activity created for the install or upgrade operations                                                |
| Managed `sat bootprep` configuration files    | `-bc BOOTPREP_CONFIG_MANAGED`    | The `sat bootprep` configuration file used for managed nodes                                          |
| Management `sat bootprep` configuration files | `-bm BOOTPREP_CONFIG_MANAGEMENT` | The `sat bootprep` configuration file used for management nodes                                       |
| `sat bootprep` configuration directory        | `-bpcd BOOTPREP_CONFIG_DIR`      | Directory containing `sat bootprep` configuration files and recipe variables                          |
| Recipe variables                              | `-rv RECIPE_VARS`                | Path to YAML file containing recipe variables provided by HPE                                         |
| Site variables                                | `-sv SITE_VARS`                  | Path to YAML file containing site defaults and any overrides                                          |
| Recipe variables product mask                 | `-mrp MASK_RECIPE_PRODS`         | Mask the recipe variables file entries for the products specified, use product catalog values instead |

### ARM images

If it is necessary to build `aarch64` images, then see [ARM images](../IUF.md#arm-images).

## Artifacts created

The artifacts created by the `prepare-images` stage can found by examining the output from `iuf run` or by examining a
Kubernetes ConfigMap associated with the IUF activity specified when executing the `prepare-images` stage. The following
examples show how to find the management node and managed node artifacts from the ConfigMap.

### Management node artifacts

(`ncn-mw#`) Examine the activity ConfigMap to identify the management node images and CFS configurations created
by `prepare-images`.

```bash
kubectl get configmaps -n argo "${ACTIVITY_NAME}" -o jsonpath='{.data.iuf_activity}' \
    | jq '.operation_outputs.stage_params["prepare-images"]["prepare-management-images"]["sat-bootprep-run"].script_stdout' \
    | xargs -0 echo -e
```

Example output:

```text
"{
    \"images\": [
        {
            \"name\": \"storage-secure-storage-ceph-5.2.54-x86_64.squashfs\",
            \"preconfigured_image_id\": null,
            \"final_image_id\": \"e732edda-cd6a-427c-881b-8d1708f9a02e\",
            \"configuration\": \"minimal-management-23.11.0\",
            \"configuration_group_names\": [
                \"Management_Storage\"
            ]
        },
        {
            \"name\": \"worker-secure-kubernetes-5.2.54-x86_64.squashfs\",
            \"preconfigured_image_id\": null,
            \"final_image_id\": \"26325680-ff2a-4a32-8a88-9c4e16a9e215\",
            \"configuration\": \"management-23.11.0\",
            \"configuration_group_names\": [
                \"Management_Worker\"
            ]
        },
        {
            \"name\": \"master-secure-kubernetes-5.2.54-x86_64.squashfs\",
            \"preconfigured_image_id\": null,
            \"final_image_id\": \"e5d6254d-57b6-4aa7-a971-7d7e371c94c7\",
            \"configuration\": \"management-23.11.0\",
            \"configuration_group_names\": [
                \"Management_Master\"
            ]
        }
    ]
}"
```

### Managed node artifacts

(`ncn-mw#`) Examine the activity ConfigMap to identify the managed node images, CFS configurations, and BOS session
templates created by `prepare-images`.

```bash
kubectl get configmaps -n argo "${ACTIVITY_NAME}" -o jsonpath='{.data.iuf_activity}' \
    | jq '.operation_outputs.stage_params["prepare-images"]["prepare-managed-images"]["sat-bootprep-run"].script_stdout' \
    | xargs -0 echo -e
```

Example output:

```text
"{
    \"images\": [
        {
            \"name\": \"lnet-cray-shasta-compute-sles15sp4.noarch-2.5.28\",
            \"preconfigured_image_id\": null,
            \"final_image_id\": \"6b406606-7bb2-43ef-8df1-40ae7021ed3c\",
            \"configuration\": \"lnet-23.2.10\",
            \"configuration_group_names\": [
                \"Application\",
                \"Application_LNETRouter\"
            ]
        },
        {
            \"name\": \"cray-shasta-compute-sles15sp4.noarch-2.5.28\",
            \"preconfigured_image_id\": \"aed56a05-032b-4351-be78-a994de2181a3\",
            \"final_image_id\": \"aed56a05-032b-4351-be78-a994de2181a3\",
            \"configuration\": null,
            \"configuration_group_names\": null
        },
        {
            \"name\": \"compute-cray-shasta-compute-sles15sp4.noarch-2.5.28\",
            \"preconfigured_image_id\": null,
            \"final_image_id\": \"270e0f78-4404-43a7-8e06-1b04123c2c3d\",
            \"configuration\": \"compute-23.2.10\",
            \"configuration_group_names\": [
                \"Compute\"
            ]
        },
        {
            \"name\": \"gpu-image\",
            \"preconfigured_image_id\": null,
            \"final_image_id\": \"b1c786f5-5004-4226-afbf-ac1e0417ed33\",
            \"configuration\": \"gpu-23.2.10\",
            \"configuration_group_names\": [
                \"Compute\"
            ]
        },
        {
            \"name\": \"uan-cray-shasta-compute-sles15sp4.noarch-2.5.28\",
            \"preconfigured_image_id\": null,
            \"final_image_id\": \"46e63fad-b8cb-4696-a009-d66006f88b08\",
            \"configuration\": \"uan-23.2.10\",
            \"configuration_group_names\": [
                \"Application\",
                \"Application_UAN\"
            ]
        }
    ],
    \"session_templates\": [
        {
            \"name\": \"compute-23.2.10\",
            \"configuration\": \"compute-23.2.10\"
        },
        {
            \"name\": \"uan-23.2.10\",
            \"configuration\": \"uan-23.2.10\"
        },
        {
            \"name\": \"lnet-23.2.10\",
            \"configuration\": \"lnet-23.2.10\"
        }
    ]
}"
```

## Execution details

The code executed by this stage utilizes `sat bootprep` to build and customize images. See the `prepare-images` entry
in `/usr/share/doc/csm/workflows/iuf/stages.yaml` and the corresponding files
in `/usr/share/doc/csm/workflows/iuf/operations/`
for details on the commands executed.

For more information, see [SAT Bootprep](../../../operations/system_admin_toolkit/usage/SAT_Bootprep.md).

## Example

(`ncn-m001#`) Execute the `prepare-images` stage for activity `admin-230127` using
the `/etc/cray/upgrade/csm/admin/site_vars.yaml` file and the managed and management `sat bootprep` configuration files
and the `product_vars.yaml` configuration file found in the `/etc/cray/upgrade/csm/admin` directory.

```bash
iuf -a admin-230127 run -sv /etc/cray/upgrade/csm/admin/site_vars.yaml -bpcd /etc/cray/upgrade/csm/admin -r prepare-images
```
