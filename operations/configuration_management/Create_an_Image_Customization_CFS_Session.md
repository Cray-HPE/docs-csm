# Create an Image Customization CFS Session

A configuration session that is meant to customize image roots tracked by the Image Management Service \(IMS\) can be created using the `--target-definition` image option. This option will instruct
the Configuration Framework Service \(CFS\) to prepare the image IDs specified and assign them to the groups specified in Ansible inventory. IMS will then provide SSH connection information to each
image root that CFS will use to configure Ansible.

Along with the `--target-definition` option, users must also provide the `--target-group` option. This option can be provided multiple times, and allows users to specify the Ansible inventory by
creating multiple groups within the inventory and the image(s) that should be in each group. It is important to note that users provide the entire inventory when using image customization, and groups
that are not specified will not be included, even if they appear in other CFS inventory types, such as dynamic inventory. For more information on what it means to provide the inventory, see
[Specifying Hosts and Groups](Specifying_Hosts_and_Groups.md).

Users can expect that staging the image and generating an inventory will be a longer process than creating a session with other target definitions \(for example, inventories\). Tearing down the
configuration session will also require additional time while IMS packages up the image build artifacts and uploads them to the artifact repository.

- [Prerequisites](#prerequisites)
- [1. Check if image is registered with IMS](#1-check-if-image-is-registered-with-ims)
- [2. Create CFS image customization session](#2-create-cfs-image-customization-session)
- [3. Wait for CFS session to complete successfully](#3-wait-for-cfs-session-to-complete-successfully)
- [4. Retrieve the resultant image ID](#4-retrieve-the-resultant-image-id)

## Prerequisites

- The Cray CLI must be configured on the node where the commands are being run.
  - See [Configure the Cray CLI](../configure_cray_cli.md).
- The image being customized must be registered in IMS.
  - See [Check if image is registered with IMS](#1-check-if-image-is-registered-with-ims).

## 1. Check if image is registered with IMS

In order to use the `image` target definition, an image must be registered with IMS.

(`ncn-mw#`) For example, if the image ID is `5d64c8b2-4f0e-4b2e-b334-51daba16b7fb`, then use `jq` along with the CLI `--format json` output option to determine if the image ID is known to IMS:

```bash
cray ims images list --format json | jq -r 'any(.[]; .id == "5d64c8b2-4f0e-4b2e-b334-51daba16b7fb")'
```

Example output:

```text
true
```

## 2. Create CFS image customization session

(`ncn-mw#`) To create a CFS session for image customization, provide a session name, the name of the configuration to apply, and any Ansible groups along with the images they will be applied to.
It is also possible to provide a mapping of the source image ids to the resulting image names, for users who want to control the naming of the resultant image.

> **WARNING:** If a CFS session is created with an ID that is not known to IMS, then CFS will not fail and will instead wait for the image ID to become available in IMS.

```bash
cray cfs sessions create --name example \
    --configuration-name configurations-example \
    --target-definition image --format json \
    --target-group Application <IMS_IMAGE_ID> \
    --target-group Application_UAN <IMS_IMAGE_ID> \
    --image-map <IMS_IMAGE_ID> <RESULTING_IMAGE_NAME>
```

Example output:

```json
{
  "ansible": {
    "config": "cfs-default-ansible-cfg",
    "limit": null,
    "passthrough": null,
    "verbosity": 0
  },
  "configuration": {
    "limit": "",
    "name": "configurations-example"
  },
  "name": "example",
  "status": {
    "artifacts": [],
    "session": {
      "completionTime": null,
      "job": null,
      "startTime": "2022-09-26T14:31:33",
      "status": "pending",
      "succeeded": "none"
    }
  },
  "tags": {},
  "target": {
    "definition": "image",
    "groups": [
      {
        "members": [
          IMS_IMAGE_ID
        ],
        "name": "Application"
      },
      {
        "members": [
          IMS_IMAGE_ID
        ],
        "name": "Application_UAN"
      }
    ],
    "imageMap": {
      "source_id": IMS_IMAGE_ID,
      "result_name": RESULTING_IMAGE_NAME
    }
  }
}
```

## 3. Wait for CFS session to complete successfully

See [Track the Status of a Session](Track_the_Status_of_a_Session.md).

## 4. Retrieve the resultant image ID

(`ncn-mw#`) When an image customization CFS session is complete, use the CFS `describe` command to show the IMS image ID that results from the applied configuration:

```bash
cray cfs sessions describe example --format json | jq .status.artifacts
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

This resultant image ID can be used to be further customized pre-boot, or if it is ready, in a Boot Orchestration Service \(BOS\) boot session template.
