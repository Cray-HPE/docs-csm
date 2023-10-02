# Create a Node Personalization CFS Session

Node Personalization is an configuration done by the Configuration Framework Service \(CFS\) that targets live nodes.
By default, CFS will automatically generate the Ansible inventory using CFS' dynamic inventory.
The inventory will include all nodes on the system, placed into groups according to their Role, Subrole and any Groups in HSM.
Other inventory options are also available that will give the user more direct control over the Ansible inventory.
See [CFS Session Inventory](CFS_Session_Inventory.md) for more information.

## Prerequisites

- The Cray CLI must be configured on the node where the commands are being run.
  - See [Configure the Cray CLI](../configure_cray_cli.md).

## 1. Create CFS node personalization session

 To create a CFS session using the default dynamic inventory, simply provide a session name and the name of the configuration to apply:

```bash
cray cfs v3 sessions create --name example \
    --configuration-name example-config --format json
```

Example output:

```json
{
  "ansible": {
    "config": "cfs-default-ansible-cfg",
    "limit": "",
    "passthrough": "",
    "verbosity": 0
  },
  "configuration": {
    "limit": "",
    "name": "example-config"
  },
  "debug_on_failure": false,
  "logs": "ara.cmn.site/hosts?label=example",
  "name": "example",
  "status": {
    "artifacts": [],
    "session": {
      "completion_time": null,
      "job": null,
      "start_time": "2023-08-31T16:38:21",
      "status": "pending",
      "succeeded": "none"
    }
  },
  "tags": {},
  "target": {
    "definition": "dynamic",
    "groups": [],
    "image_map": []
  }
}
```

## 2. Wait for CFS session to complete successfully

See [Track the Status of a Session](Track_the_Status_of_a_Session.md).
