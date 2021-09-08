
## List Available UAI Classes

View all the details of every available UAI class. Use this information to select a class to apply to one or more UAIs.

### Prerequisites

Install and initialize the `cray` administrative CLI.

### Procedure

1.  List all available UAI classes.

    To list available UAI classes, use the following command:

    ```
    ncn-m001-pit# cray uas admin config classes list
    ```

    The `cray uas admin config classes list` command supports the same `--format` options as the `cray uas admin config volumes list` command. See [List Volumes Registered in UAS](List_Volumes_Registered_in_UAS.md) for details.

    For example:

    ```bash
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

1. Examine the output.

  In the returned output, there are three UAI classes:

  * A UAI broker class
  * A brokered end-user UAI class
  * A non-brokered end-user UAI class

  Taking apart the non-brokered end-user UAI class, the first part is:

   ```
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
   ```

  The `class_id` field is the identifier used to refer to this class when examining, updating, and deleting this class as well as when using the class with the command:

  ```
  ncn-m001-pit# cray uas admin uais create
  ```

  The `comment` field is a free form string describing the UAI class. The `default` field is a flag indicating whether this class is the default class. The default class will be applied, overriding both the default UAI image and any specified image name, when the following command is used to create an end-user UAI for a user:

  ```
  ncn-m001-pit# cray uas create
  ```

  Setting a class to default gives the administrator fine grained control over the behavior of end-user UAIs that are created by authorized users in legacy mode (see [Legacy Mode User-Driven UAI Management](Legacy_Mode_User-Driven_UAI_Management.md)).

  The remaining fields are as follows:
  * The `namespace` field specifies the Kubernetes namespace in which this UAI will run. It has the default setting of `user` here.
  * The `opt_ports` field is an empty list of TCP port numbers that will be opened on the external IP address of the UAI when it runs. This controls whether services other than SSH can be run and reached publicly on the UAI. The `priority_class_name` `"uai_priority"` is the default <a href="https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/#priorityclass">Kubernetes priority class</a> of UAIs. If it were a different class, it would affect both Kubernetes default resource limit / request assignments and Kubernetes scheduling priority for the UAI.
  * The `public_ip` field is a flag that indicates whether the UAI should be given an external IP address LoadBalancer service so that clients outside the Kubernetes cluster can reach it, or only be given a Kubernetes Cluster-IP address. For the most part, this controls whether the UAI is reachable by SSH from external clients, but it also controls whether the ports in `opt_ports` are reachable as well.
  * The `resource_config` field is not set, but could be set to a resource specification to override namespace defaults on Kubernetes resource requests / limits.
  * The `uai_compute_network` flag indicates whether this UAI uses the macvlan mechanism to gain access to the Shasta compute node network. This needs to be `true` to support workload management.
  * The `uai_creation_class` field is used by [broker UAIs](#main-uaimanagement-brokermode-brokerclasses) to tell the broker what kind of UAI to create when automatically generating a UAI.

  After all these individual items, we see the UAI Image to be used to create UAIs of this class:

  ```
     "uai_image": {
        "default": true,
        "image_id": "ff86596e-9699-46e8-9d49-9cb20203df8c",
        "imagename": "registry.local/cray/cray-uai-sles15sp1:latest"
      },
  ```

  Finally, there is a list of volumes that will show up in UAIs created using this class:

   ```
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
   ```

   The timezone is taken from the host node by importing `/etc/localtime` to the UAI. Access is given to the Lustre file system mounted on the host node as `/lus` and mounting that within the UAI at the same path.Then, two pieces of Slurm configuration, the munge key and the slurm configuration file, are taken from Kubernetes and mounted as files at `/root/slurm_config/munge` and `/etc/slurm` respectively.

See [UAI Classes](UAI_Classes.md) and [Elements of a UAI](Elements_of_a_UAI.md) for more details on the output.
