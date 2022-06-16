# Create a CFS Session with Dynamic Inventory

A Configuration Framework Service \(CFS\) session using dynamic inventory is used to configure live nodes. To create a CFS session using the default dynamic inventory, simply provide a session name and the name of the configuration to apply:

```bash
ncn# cray cfs sessions create --name example \
--configuration-name configurations-example
```

Example output:

```json
{
  "ansible": {
    "config": "cfs-default-ansible-cfg",
    "limit": "",
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
    "definition": "dynamic",
    "groups": null
  }
}
```

Add the `--target-definition dynamic` parameter to the create command to explicitly define the inventory type to be `dynamic`. This will enable CFS to provide the Ansible host groups via its dynamic inventory. The individual Ansible playbooks specified in the configuration layers will decide which hosts and/or groups will have configuration applied to them.

