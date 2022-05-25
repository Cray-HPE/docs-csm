# Create an Image Customization CFS Session

A configuration session that is meant to customize image roots tracked by the Image Management Service \(IMS\) can be created using the `--target-definition` image option. This option will instruct the Configuration Framework Service \(CFS\) to prepare the image IDs specified and assign them to the groups specified in Ansible inventory. IMS will then provide SSH connection information to each image root that CFS will use to configure Ansible.

Along with the `--target-definition` option, users must also provide the `--target-group` option. This option can be provided multiple times, and allows users to specify the Ansible inventory by creating multiple groups within the inventory and the image(s) that should be in each group. It is important to note that users provide the entire inventory when using image customization, and groups that are not specified will not be included, even if they appear in other CFS inventory types, such as dynamic inventory. For more information on what it means to provide the inventory, see [Specifying Hosts and Groups](./Specifying_Hosts_and_Groups.md).

Users can expect that staging the image and generating an inventory will be a longer process than creating a session with other target definitions \(for example, inventories\). Tearing down the configuration session will also require additional time while IMS packages up the image build artifacts and uploads them to the artifact repository.

In order to use the `image` target definition, an image must be registered with the IMS. For example, if the image ID is 5d64c8b2-4f0e-4b2e-b334-51daba16b7fb, use `jq` along with the CLI `--format json` output option to determine if the image ID is known to IMS:

```bash
ncn# cray ims images list --format json |
jq -r 'any(.[]; .id == "5d64c8b2-4f0e-4b2e-b334-51daba16b7fb")'
true
```

To create a CFS session for image customization, provide a session name, the name of the configuration to apply, and the group/image ID mapping:

> **WARNING:** If a CFS session is created with an ID that is not known to IMS, CFS will not fail and will instead wait for the image ID to become available in IMS.

```bash
ncn# cray cfs sessions create --name example \
--configuration-name configurations-example \
--target-definition image \
--target-group Compute IMS_IMAGE_ID
```

Example output:

```json
{
  "ansible": {
    "config": "cfs-default-ansible-cfg",
    "limit": null,
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
          "<IMS IMAGE ID>"
        ],
        "name": "Compute"
      }
    ]
  }
}
```

## Retrieve the Resultant Image ID

When an image customization CFS session is complete, use the CFS `describe` command to show the IMS image ID that results from the applied configuration:

```bash
ncn# cray cfs sessions describe example --format json | jq .status.artifacts
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

