# Obtain the Configuration of a UAS Volume

View the configuration information of a specific UAS volume. This procedure requires the `volume_ID` of that volume.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)
* The administrator must know the Volume ID of the volume to be retrieved: [List Volumes Registered in UAS](List_Volumes_Registered_in_UAS.md)

## Procedure

View the configuration of a specific UAS volume.

This command returns output in TOML format by default. JSON or YAML formatted output can be obtained by using the `--format json` or `--format yaml` options respectively.

```bash
ncn-m001-pit# cray uas admin config volumes describe 11a4a22a-9644-4529-9434-d296eef2dc48 --format json
```

Example output:

```json
{
  "mount_path": "/etc/localtime",
  "volume_description": {
    "host_path": {
      "path": "/etc/localtime",
      "type": "FileOrCreate"
    }
  },
  "volume_id": "11a4a22a-9644-4529-9434-d296eef2dc48",
  "volumename": "timezone"
}
```

[Top: User Access Service (UAS)](index.md)

[Next Topic: Update a UAS Volume](Update_a_UAS_Volume.md)
