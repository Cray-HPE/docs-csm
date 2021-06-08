---
category: numbered
---

# List Available UAI Classes

Display all the information about every UAI class available in UAS.

Install and initialize the cray administrative CLI.

-   **ROLE**

    System Administrator

-   **OBJECTIVE**

    View all the details of every available UAI class. Use this information to select a class to apply to one or more UAIs.

-   **LIMITATIONS**

    None.


1.  List all available UAI classes.

    The cray uas admin config classes list command supports the same --format options as the cray uas admin config volumes list command. See [List Volumes Registered in UAS](List_Volumes_Registered_in_UAS.md) for details.

    ```screen
    ncn-m001-pit# cray uas admin config classes list --format json
    [
      {
        "class_id": "05496a5f-7e35-435d-a802-882c6425e5b2",
        "comment": "UAI Broker Class",
        "default": false,
        "namespace": "uas",
        "opt_ports": [],
        "priority_class_name": "uai-priority",
        "public_ip": true,
        "resource_config": null,
        "uai_compute_network": false,
        "uai_creation_class": "a623a04a-8ff0-425e-94cc-4409bdd49d9c",
        "uai_image": {
          "default": false,
          "image_id": "c5dcb261-5271-49b3-9347-afe7f3e31941",
          "imagename": "registry.local/cray/cray-uai-broker:latest"
        },
        "volume_mounts": [
          {
            "mount_path": "/etc/localtime",
            "volume_description": {
              "host_path": {
                "path": "/etc/localtime",
                "type": "FileOrCreate"
              }
            },
            "volume_id": "55a02475-5770-4a77-b621-f92c5082475c",
            "volumename": "timezone"
          },
          {
            "mount_path": "/lus",
            "volume_description": {
              "host_path": {
                "path": "/lus",
                "type": "DirectoryOrCreate"
              }
            },
            "volume_id": "9fff2d24-77d9-467f-869a-235ddcd37ad7",
            "volumename": "lustre"
          }
        ]
      },
      {
        "class_id": "a623a04a-8ff0-425e-94cc-4409bdd49d9c",
        "comment": "UAI User Class",
        "default": false,
        "namespace": "user",
        "opt_ports": [],
        "priority_class_name": "uai-priority",
        "public_ip": false,
        "resource_config": null,
        "uai_compute_network": true,
        "uai_creation_class": null,
        "uai_image": {
          "default": true,
          "image_id": "ff86596e-9699-46e8-9d49-9cb20203df8c",
          "imagename": "registry.local/cray/cray-uai-sles15sp1:latest"
        },
        "volume_mounts": [
          {
            "mount_path": "/etc/localtime",
            "volume_description": {
              "host_path": {
                "path": "/etc/localtime",
                "type": "FileOrCreate"
              }
            },
            "volume_id": "55a02475-5770-4a77-b621-f92c5082475c",
            "volumename": "timezone"
          },
          {
            "mount_path": "/lus",
            "volume_description": {
              "host_path": {
                "path": "/lus",
                "type": "DirectoryOrCreate"
              }
            },
            "volume_id": "9fff2d24-77d9-467f-869a-235ddcd37ad7",
            "volumename": "lustre"
          },
          {
            "mount_path": "/root/slurm_config/munge",
            "volume_description": {
              "secret": {
                "secret_name": "munge-secret"
              }
            },
            "volume_id": "7aeaf158-ad8d-4f0d-bae6-47f8fffbd1ad",
            "volumename": "munge-key"
          },
          {
            "mount_path": "/etc/slurm",
            "volume_description": {
              "config_map": {
                "name": "slurm-map"
              }
            },
            "volume_id": "ea97325c-2b1d-418a-b3b5-3f6488f4a9e2",
            "volumename": "slurm-config"
          }
        ]
      },
      {
        "class_id": "bb28a35a-6cbc-4c30-84b0-6050314af76b",
        "comment": "Non-Brokered UAI User Class",
        "default": false,
        "namespace": "user",
        "opt_ports": [],
        "priority_class_name": "uai-priority",
        "public_ip": true,
        "resource_config": null,
        "uai_compute_network": true,
        "uai_creation_class": null,
        "uai_image": {
          "default": true,
          "image_id": "ff86596e-9699-46e8-9d49-9cb20203df8c",
          "imagename": "registry.local/cray/cray-uai-sles15sp1:latest"
        },
        "volume_mounts": [
          {
            "mount_path": "/etc/localtime",
            "volume_description": {
              "host_path": {
                "path": "/etc/localtime",
                "type": "FileOrCreate"
              }
            },
            "volume_id": "55a02475-5770-4a77-b621-f92c5082475c",
            "volumename": "timezone"
          },
          {
            "mount_path": "/lus",
            "volume_description": {
              "host_path": {
                "path": "/lus",
                "type": "DirectoryOrCreate"
              }
            },
            "volume_id": "9fff2d24-77d9-467f-869a-235ddcd37ad7",
            "volumename": "lustre"
          },
          {
            "mount_path": "/root/slurm_config/munge",
            "volume_description": {
              "secret": {
                "secret_name": "munge-secret"
              }
            },
            "volume_id": "7aeaf158-ad8d-4f0d-bae6-47f8fffbd1ad",
            "volumename": "munge-key"
          },
          {
            "mount_path": "/etc/slurm",
            "volume_description": {
              "config_map": {
                "name": "slurm-map"
              }
            },
            "volume_id": "ea97325c-2b1d-418a-b3b5-3f6488f4a9e2",
            "volumename": "slurm-config"
          }
        ]
      }
    ]
    ```

    See [About UAI Classes](About_UAI_Classes.md) and [Elements of a UAI](Elements_of_a_UAI.md) for an explanation of the output of this command.


