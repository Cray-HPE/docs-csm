# View a UAI Class

Display all the information for a specific UAI class by referencing its class ID.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)
* The administrator must know the Class ID of a UAI class: [List Available UAI Classes](List_Available_UAI_Classes.md)

## Procedure

View all the information about a specific UAI class.

To examine an existing UAI class, use a command of the following form:

```bash
ncn-m001-pit# cray uas admin config classes describe <class-id>
```

The following example uses the `--format yaml` option to display the UAI class configuration in YAML format.
Replace `yaml` with `json` to return JSON-formatted output. Omitting the `--format` option displays the UAI class in the default TOML format.

Replace `bb28a35a-6cbc-4c30-84b0-6050314af76b` in the example command with the ID of the UAI class to be examined.

```bash
ncn-m001-pit# cray uas admin config classes describe bdb4988b-c061-48fa-a005-34f8571b88b4 --format yaml
```

Example output:

```yaml
class_id: bdb4988b-c061-48fa-a005-34f8571b88b4
comment: UAI Class to Create Brokered End-User UAIs
default: false
image_id: 1996c7f7-ca45-4588-bc41-0422fe2a1c3d
namespace: user
opt_ports: []
priority_class_name: uai-priority
public_ip: false
replicas: 3
resource_config:
  comment: Resource Specification to use with Brokered End-User UAIs
  limit: '{"cpu": "1", "memory": "1Gi"}'
  request: '{"cpu": "1", "memory": "1Gi"}'
  resource_id: f26ee12c-6215-4ad1-a15e-efe4232f45e6
resource_id: f26ee12c-6215-4ad1-a15e-efe4232f45e6
service_account:
timeout:
  hard: '86400'
  soft: '1800'
  warning: '60'
tolerations:
uai_compute_network: true
uai_creation_class:
uai_image:
  default: true
  image_id: 1996c7f7-ca45-4588-bc41-0422fe2a1c3d
  imagename: registry.local/cray/cray-uai-sles15sp2:1.2.4
volume_list:
- 11a4a22a-9644-4529-9434-d296eef2dc48
- a3b149fd-c477-41f0-8f8d-bfcee87fdd0a
volume_mounts:
- mount_path: /etc/localtime
  volume_description:
    host_path:
      path: /etc/localtime
      type: FileOrCreate
  volume_id: 11a4a22a-9644-4529-9434-d296eef2dc48
  volumename: timezone
- mount_path: /lus
  volume_description:
    host_path:
      path: /lus
      type: DirectoryOrCreate
  volume_id: a3b149fd-c477-41f0-8f8d-bfcee87fdd0a
  volumename: lustre
```

Refer to [UAI Classes](UAI_Classes.md) and [Elements of a UAI](Elements_of_a_UAI.md) for an explanation of the output of this command.

[Top: User Access Service (UAS)](index.md)

[Next Topic Modify a UAI Class](Modify_a_UAI_Class.md)
