# List Volumes Registered in UAS

List the details of all volumes registered in UAS with the `cray uas admin config volumes list` command. Use this command to obtain the `volume_id` value of volume, which is required for other UAS administrative commands.

## Prerequisites

* The administrator must be logged into an NCN or a host that has administrative access to the HPE Cray EX System API Gateway
* The administrator must have the HPE Cray EX System CLI (`cray` command) installed on the above host
* The HPE Cray EX System CLI must be configured (initialized - `cray init` command) to reach the HPE Cray EX System API Gateway
* The administrator must be logged in as an administrator to the HPE Cray EX System CLI (`cray auth login` command)

## Procedure

The volume registrations in the UAS configuration can be quite extensive and sometimes difficult to read in the default TOML format used by the `cray` administrative CLI.
The following shows the `--format` option to the `cray` CLI being used to switch to various output formats that may be easier to read or more useful for certain tasks.
Feel free to use that option with any `cray` CLI command to select a more comfortable output style.

List the details of all the volumes registered in UAS.

* Retrieve the list in TOML.

    ```bash
    ncn-m001-pit# cray uas admin config volumes list
    ```

    Example output:

    ```bash
    [[results]]
    mount_path = "/etc/localtime"
    volume_id = "11a4a22a-9644-4529-9434-d296eef2dc48"
    volumename = "timezone"

    [results.volume_description.host_path]
    path = "/etc/localtime"
    type = "FileOrCreate"
    [[results]]
    mount_path = "/etc/sssd"
    volume_id = "1ec36af0-d5b6-4ad9-b3e8-755729765d76"
    volumename = "broker-sssd-config"

    [results.volume_description.secret]
    default_mode = 384
    secret_name = "broker-sssd-conf"
    [[results]]
    mount_path = "/lus"
    volume_id = "a3b149fd-c477-41f0-8f8d-bfcee87fdd0a"
    volumename = "lustre"

    [results.volume_description.host_path]
    path = "/lus"
    type = "DirectoryOrCreate"
    ```

* Retrieve the list in YAML format.

    ```bash
    ncn-m001-pit# cray uas admin config volumes list --format yaml
    ```

    Example output:

    ```yaml
    - mount_path: /etc/localtime
      volume_description:
        host_path:
          path: /etc/localtime
          type: FileOrCreate
      volume_id: 11a4a22a-9644-4529-9434-d296eef2dc48
      volumename: timezone
    - mount_path: /etc/sssd
      volume_description:
        secret:
          default_mode: 384
          secret_name: broker-sssd-conf
      volume_id: 1ec36af0-d5b6-4ad9-b3e8-755729765d76
      volumename: broker-sssd-config
    - mount_path: /lus
      volume_description:
        host_path:
          path: /lus
          type: DirectoryOrCreate
      volume_id: a3b149fd-c477-41f0-8f8d-bfcee87fdd0a
      volumename: lustre
    ```

* Retrieve the list in JSON format.

    ```bash
    ncn-m001-pit# cray uas admin config volumes list --format json
    ```

    Example output:

    ```json
    [
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
      },
      {
        "mount_path": "/etc/sssd",
        "volume_description": {
          "secret": {
            "default_mode": 384,
            "secret_name": "broker-sssd-conf"
          }
        },
        "volume_id": "1ec36af0-d5b6-4ad9-b3e8-755729765d76",
        "volumename": "broker-sssd-config"
      },
      {
        "mount_path": "/lus",
        "volume_description": {
          "host_path": {
            "path": "/lus",
            "type": "DirectoryOrCreate"
          }
        },
        "volume_id": "a3b149fd-c477-41f0-8f8d-bfcee87fdd0a",
        "volumename": "lustre"
      }
    ]
    ```

The JSON formatted output can help guide administrators in constructing new volume descriptions required to add or update a volume description in UAS. JSON is the required input format for volume descriptions in UAS.

Looking at the above output, each volume has a `mount_path`, `volume_description`, `volume_name` and `volume_id` entry.

The `mount_path` specifies where in the UAI the volume will be mounted.

**NOTE:** While it is acceptable to have multiple volumes configured in UAS with the same `mount_path`, any given UAI will fail creation if it has more than one volume specified for a given mount path.
If multiple volumes with the same mount path exist in the UAS configuration, all UAIs must be created using UAI classes that specify a workable subset of volumes.
A UAI created without a UAI Class under such a UAS configuration will try to use all configured volumes and creation will fail.

The `volume_description` is the JSON description of the volume, specified as a dictionary with one entry, whose key identifies the kind of Kubernetes volume is described (i.e. `host_path`, `configmap`, `secret`, etc.)
whose value is another dictionary containing the Kubernetes volume description itself.
See [Kubernetes documentation](https://kubernetes.io/docs/concepts/storage/volumes) for details on what goes in various kinds of volume descriptions.

The `volumename` is a string the creator of the volume may chose to describe or name the volume. It must be comprised of only lower case alphanumeric characters and dashes ('-') and must begin and end with an alphanumeric character.
It is used inside the UAI pod specification to identify the volume that is mounted in a given location in a container. The name is required and administrators are free to use any name that meets the above requirements.
Volume names do need to be unique within any given UAI and are far more useful when searching for a volume if they are unique across the entire UAS configuration.

The `volume_id` is a unique identifier used to identify the UAS volume when examining, updating or deleting a volume and when linking a volume to a UAI class. It is assigned automatically by UAS.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Add a Volume to UAS](Add_a_Volume_to_UAS.md)
