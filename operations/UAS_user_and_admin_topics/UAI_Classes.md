# UAI Classes

This topic explains all the fields in a User Access Instance (UAI) class and gives guidance on setting them when creating UAI classes.

### Example Listing and Overview

The following is JSON-formatted example output from the cray uas admin config classes list command \(see [List Available UAI Classes](List_Available_UAI_Classes.md)\). This output contains examples of three UAI classes:

-   A UAI broker class
-   A brokered end-user UAI class
-   A non-brokered end-user UAI class

This topic uses the end-user UAI class section to explain each of fields within a UAI class.

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

### UAI Class Parameters

The following selection is the first part of the end-user UAI class section:

```bash
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

The following table explains each of these fields.

|Field|Description|Notes|
|-----|-----------|-----|
|class\_id|The identifier used for this class when examining, updating, and deleting the class.|This identifier is also used to create UAIs using this class with the cray uas admin uais create|
|comment|A free-form string describing the UAI class| |
|default|A boolean value \(flag\) indicating whether this class is the default class.|When this field is set to `true`, this class overrides both the default UAI image and any specified image name when the cray uas create command is used to create an end-user UAI for a user. Setting a class to `"default": true`, gives the administrator fine-grained control over the behavior of end-user UAIs that are created by authorized users in legacy mode.|
|namespace|The Kubernetes namespace in which this UAI will run.|The default setting is user.|
|opt\_ports|An optional list of TCP port numbers that will be opened on the external IP address of the UAI when it runs.|This field controls whether services other than SSH can be run and reached publicly on the UAI. If this list is empty \(like the preceding example\), only SSH will be externally accessible.|
|priority\_class\_name|The Kubernetes priority class of the UAI.|"uai\_priority" is the default. Using other values affects both Kubernetes default resource limit and request assignments and the Kubernetes scheduling priority for the UAI.|
|public\_ip|A boolean value that indicates whether the UAI will be given an external IP address from the LoadBalancer service. Such an address enables clients outside the Kubernetes cluster to reach the UAI.|This field controls whether the UAI is reachable by SSH from external clients, but it also controls whether the ports in opt\_ports are reachable. If this field is set to `false`, the UAI will have only an internal IP address, reachable from within the Kubernetes cluster.|
|resource\_config|Can be set to a resource specification to override namespace defaults on Kubernetes resource requests and limits.|This field is not set in the preceding example.|
|uai\_compute\_network|A flag that indicates whether this UAI uses the macvlan mechanism to gain access to the HPE Cray EX compute node network.|This field must be true to support workload management.|
|uai\_creation\_class|A field used by broker UAIs to tell the broker what kind of UAI to create when automatically generating a UAI.|This field is not set in the preceding example.|

### UAI Images and Volumes in UAI Classes

The following section is used to create UAIs of this class:

```bash
 "uai_image": {
      "default": true,
      "image_id": "ff86596e-9699-46e8-9d49-9cb20203df8c",
      "imagename": "registry.local/cray/cray-uai-sles15sp1:latest"
    },
```

At the end of this end-user UAI class, there is a list of volumes that will be mounted by UAIs created using the class:

```bash
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

Refer to [Elements of a UAI](Elements_of_a_UAI.md) for a full explanation of UAI images and volumes.

In the preceding section of output, the end-user UAI inherits the timezone from the host node by importing /etc/localtime. This UAI also gains access to the Lustre file system mounted on the host node. On the host node, the file system is mounted at /lus and the UAI mounts the file system at the same mount point as the host node. Lastly, the UAI class includes two Slurm configuration items, the munge key and the Slurm configuration file. These are obtained from Kubernetes and the UAI mounts them as files at /root/slurm\_config/munge and /etc/slurm respectively.

