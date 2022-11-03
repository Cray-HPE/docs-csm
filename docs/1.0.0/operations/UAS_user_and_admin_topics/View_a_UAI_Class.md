# View a UAI Class

Display all the information for a specific UAI class by referencing its class ID.

### Prerequisites

-   Install and initialize the `cray` administrative CLI.
-   Obtain the ID of a UAI class.

### Procedure

1.  View all the information about a specific UAI class.

    To examine an existing UAI class, use a command of the following form:

    ```
    ncn-m001-pit# cray uas admin config classes describe <class-id>
    ```

    The following example uses the `--format yaml` option to display the UAI class configuration in YAML format. Replace yaml with json to return JSON-formatted output. Omitting the `--format` option displays the UAI class in the default TOML format.

    Replace bb28a35a-6cbc-4c30-84b0-6050314af76b in the example command with the ID of the UAI class to be examined.

    ```bash
    ncn-m001-pit# cray uas admin config classes describe \
    --format yaml bb28a35a-6cbc-4c30-84b0-6050314af76b
    class_id: bb28a35a-6cbc-4c30-84b0-6050314af76b
    comment: Non-Brokered UAI User Class
    default: false
    namespace: user
    opt_ports: []
    priority_class_name: uai-priority
    public_ip: true
    resource_config:
    uai_compute_network: true
    uai_creation_class:
    uai_image:
      default: true
      image_id: ff86596e-9699-46e8-9d49-9cb20203df8c
      imagename: dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest
    volume_mounts:
    - mount_path: /etc/localtime
      volume_description:
        host_path:
          path: /etc/localtime
          type: FileOrCreate
      volume_id: 55a02475-5770-4a77-b621-f92c5082475c
      volumename: timezone
    - mount_path: /root/slurm_config/munge
      volume_description:
        secret:
          secret_name: munge-secret
      volume_id: 7aeaf158-ad8d-4f0d-bae6-47f8fffbd1ad
      volumename: munge-key
    - mount_path: /lus
      volume_description:
        host_path:
          path: /lus
          type: DirectoryOrCreate
      volume_id: 9fff2d24-77d9-467f-869a-235ddcd37ad7
      volumename: lustre
    - mount_path: /etc/slurm
      volume_description:
        config_map:
          name: slurm-map
      volume_id: ea97325c-2b1d-418a-b3b5-3f6488f4a9e2
      volumename: slurm-config
    ```

    Refer to [UAI Classes](UAI_Classes.md) and [Elements of a UAI](Elements_of_a_UAI.md) for an explanation of the output of this command.

